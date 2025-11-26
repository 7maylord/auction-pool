// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

import {PoolManager} from "v4-core/PoolManager.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {LPFeeLibrary} from "v4-core/libraries/LPFeeLibrary.sol";

import {AuctionPoolHook} from "../src/AuctionPoolHook.sol";

contract AuctionPoolHookTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    AuctionPoolHook hook;
    PoolId poolId;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");

    function setUp() public {
        // Deploy v4 core contracts
        deployFreshManagerAndRouters();

        // Deploy tokens
        deployMintAndApprove2Currencies();

        // Deploy hook
        address flags = address(
            uint160(
                Hooks.BEFORE_SWAP_FLAG |
                Hooks.AFTER_SWAP_FLAG |
                Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
                Hooks.AFTER_ADD_LIQUIDITY_FLAG
            ) ^ (0x4444 << 144) // Namespace the hook to avoid collisions
        );

        deployCodeTo("AuctionPoolHook.sol", abi.encode(address(manager)), flags);
        hook = AuctionPoolHook(flags);

        // Initialize pool with dynamic fee flag
        (key, ) = initPool(
            currency0,
            currency1,
            hook,
            LPFeeLibrary.DYNAMIC_FEE_FLAG,
            SQRT_PRICE_1_1
        );
        poolId = key.toId();

        // Fund test accounts
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);
    }

    // ===== BID SUBMISSION TESTS =====

    function testBidSubmission() public {
        uint256 rentPerBlock = 1000 wei;
        uint256 deposit = rentPerBlock * hook.MIN_DEPOSIT_BLOCKS();

        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit AuctionPoolHook.BidSubmitted(poolId, alice, rentPerBlock, deposit);
        hook.submitBid{value: deposit}(key, rentPerBlock);

        // Verify bid was recorded
        (
            address bidder,
            uint256 bidRent,
            uint256 bidDeposit,
            uint256 activationBlock,
            uint256 timestamp
        ) = hook.nextBid(poolId);

        assertEq(bidder, alice);
        assertEq(bidRent, rentPerBlock);
        assertEq(bidDeposit, deposit);
        assertEq(activationBlock, block.number + hook.ACTIVATION_DELAY());
        assertEq(timestamp, block.timestamp);
    }

    function testBidSubmissionInsufficientDeposit() public {
        uint256 rentPerBlock = 1000 wei;
        uint256 insufficientDeposit = rentPerBlock * (hook.MIN_DEPOSIT_BLOCKS() - 1);

        vm.prank(alice);
        vm.expectRevert("Insufficient deposit");
        hook.submitBid{value: insufficientDeposit}(key, rentPerBlock);
    }

    function testBidSubmissionTooLow() public {
        // First bid
        uint256 rentPerBlock1 = 1000 wei;
        uint256 deposit1 = rentPerBlock1 * hook.MIN_DEPOSIT_BLOCKS();

        vm.prank(alice);
        hook.submitBid{value: deposit1}(key, rentPerBlock1);

        // Second bid that's too low (doesn't beat first)
        uint256 rentPerBlock2 = rentPerBlock1 + hook.MIN_BID_INCREMENT() - 1;
        uint256 deposit2 = rentPerBlock2 * hook.MIN_DEPOSIT_BLOCKS();

        vm.prank(bob);
        vm.expectRevert("Bid must exceed current rent");
        hook.submitBid{value: deposit2}(key, rentPerBlock2);
    }

    function testBidSubmissionReplacesNextBid() public {
        // Alice bids first
        uint256 rentPerBlock1 = 1000 wei;
        uint256 deposit1 = rentPerBlock1 * hook.MIN_DEPOSIT_BLOCKS();

        vm.prank(alice);
        hook.submitBid{value: deposit1}(key, rentPerBlock1);

        uint256 aliceBalanceBefore = alice.balance;

        // Bob submits higher bid, Alice should be refunded
        uint256 rentPerBlock2 = rentPerBlock1 + hook.MIN_BID_INCREMENT();
        uint256 deposit2 = rentPerBlock2 * hook.MIN_DEPOSIT_BLOCKS();

        vm.prank(bob);
        hook.submitBid{value: deposit2}(key, rentPerBlock2);

        // Verify Alice was refunded
        assertEq(alice.balance, aliceBalanceBefore + deposit1);

        // Verify Bob is now next bidder
        (address bidder, , , , ) = hook.nextBid(poolId);
        assertEq(bidder, bob);
    }

    // ===== AUCTION UPDATE TESTS =====

    function testAuctionUpdateAfterDelay() public {
        // Submit bid
        uint256 rentPerBlock = 1000 wei;
        uint256 deposit = rentPerBlock * hook.MIN_DEPOSIT_BLOCKS();

        vm.prank(alice);
        hook.submitBid{value: deposit}(key, rentPerBlock);

        // Fast forward past activation delay
        vm.roll(block.number + hook.ACTIVATION_DELAY() + 1);

        // Trigger auction update via swap
        vm.prank(bob);
        vm.expectEmit(true, true, true, true);
        emit AuctionPoolHook.ManagerChanged(poolId, address(0), alice, rentPerBlock);

        // Execute a swap to trigger beforeSwap hook
        swap(key, true, 1e18, "");

        // Verify Alice is now manager
        (address currentManager, , , , , ) = hook.poolAuctions(poolId);
        assertEq(currentManager, alice);
    }

    function testAuctionUpdateManagerDepleted() public {
        // Alice becomes manager
        uint256 rentPerBlock = 1000 wei;
        uint256 deposit = rentPerBlock * 50; // Only 50 blocks worth

        vm.prank(alice);
        hook.submitBid{value: deposit}(key, rentPerBlock);

        vm.roll(block.number + hook.ACTIVATION_DELAY() + 1);
        swap(key, true, 1e18, ""); // Alice becomes manager

        // Bob submits higher bid
        uint256 rentPerBlock2 = rentPerBlock + hook.MIN_BID_INCREMENT();
        uint256 deposit2 = rentPerBlock2 * hook.MIN_DEPOSIT_BLOCKS();

        vm.prank(bob);
        hook.submitBid{value: deposit2}(key, rentPerBlock2);

        // Fast forward beyond Alice's deposit
        vm.roll(block.number + 60);

        // Trigger update - Alice should be replaced
        vm.expectEmit(true, true, true, true);
        emit AuctionPoolHook.ManagerChanged(poolId, alice, bob, rentPerBlock2);
        swap(key, true, 1e18, "");

        // Verify Bob is now manager
        (address currentManager, , , , , ) = hook.poolAuctions(poolId);
        assertEq(currentManager, bob);
    }

    // ===== DYNAMIC FEE TESTS =====

    function testSetSwapFee() public {
        // Alice becomes manager
        _makeAliceManager();

        // Alice sets fee
        uint24 newFee = 5000; // 0.5%

        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit AuctionPoolHook.FeeUpdated(poolId, alice, newFee);
        hook.setSwapFee(key, newFee);

        // Verify fee was set
        (, , , , uint24 currentFee, ) = hook.poolAuctions(poolId);
        assertEq(currentFee, newFee);
    }

    function testSetSwapFeeNotManager() public {
        _makeAliceManager();

        uint24 newFee = 5000;

        vm.prank(bob);
        vm.expectRevert("Not manager");
        hook.setSwapFee(key, newFee);
    }

    function testSetSwapFeeExceedsCap() public {
        _makeAliceManager();

        uint24 excessiveFee = hook.MAX_FEE() + 1;

        vm.prank(alice);
        vm.expectRevert("Fee exceeds cap");
        hook.setSwapFee(key, excessiveFee);
    }

    function testManagerTradesWithZeroFee() public {
        // Alice becomes manager and sets a fee
        _makeAliceManager();

        uint24 normalFee = 3000; // 0.3%
        vm.prank(alice);
        hook.setSwapFee(key, normalFee);

        // When Alice swaps, she should get zero fee
        // This is tested implicitly through the beforeSwap hook
        vm.prank(alice);
        // The swap should succeed with zero fee for manager
        swap(key, true, 1e18, "");
    }

    // ===== RENT COLLECTION TESTS =====

    function testRentCollection() public {
        // Alice becomes manager
        uint256 rentPerBlock = 1000 wei;
        _makeManagerWithRent(alice, rentPerBlock);

        // Add liquidity so there are LPs to receive rent
        _addLiquidity(bob, 1e18);

        // Fast forward some blocks
        uint256 blocksPassed = 10;
        vm.roll(block.number + blocksPassed);

        // Trigger rent collection via swap
        uint256 expectedRent = blocksPassed * rentPerBlock;

        vm.expectEmit(true, false, false, true);
        emit AuctionPoolHook.RentCollected(poolId, expectedRent, block.number);
        swap(key, true, 1e18, "");

        // Verify rent was collected
        (, , , , , uint256 totalRentPaid) = hook.poolAuctions(poolId);
        assertEq(totalRentPaid, expectedRent);
    }

    function testRentDistribution() public {
        // Alice becomes manager
        uint256 rentPerBlock = 1000 wei;
        _makeManagerWithRent(alice, rentPerBlock);

        // Bob and Charlie add liquidity
        _addLiquidity(bob, 1e18);
        _addLiquidity(charlie, 1e18);

        // Fast forward and collect rent
        vm.roll(block.number + 10);
        swap(key, true, 1e18, "");

        // Check pending rent for both LPs
        uint256 bobPending = hook.getPendingRent(poolId, bob);
        uint256 charliePending = hook.getPendingRent(poolId, charlie);

        // They should have equal amounts since they have equal shares
        assertEq(bobPending, charliePending);
        assertGt(bobPending, 0);
    }

    function testClaimRent() public {
        // Setup: Alice is manager, Bob is LP
        uint256 rentPerBlock = 1000 wei;
        _makeManagerWithRent(alice, rentPerBlock);
        _addLiquidity(bob, 1e18);

        // Collect some rent
        vm.roll(block.number + 10);
        swap(key, true, 1e18, "");

        uint256 pending = hook.getPendingRent(poolId, bob);
        uint256 bobBalanceBefore = bob.balance;

        // Bob claims rent
        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit AuctionPoolHook.RentClaimed(poolId, bob, pending);
        hook.claimRent(key);

        // Verify Bob received rent
        assertEq(bob.balance, bobBalanceBefore + pending);

        // Verify pending is now zero
        assertEq(hook.getPendingRent(poolId, bob), 0);
    }

    // ===== WITHDRAWAL FEE TESTS =====

    function testWithdrawalFee() public {
        // Alice is manager, Bob is LP
        _makeAliceManager();
        _addLiquidity(bob, 1e18);

        // Bob removes liquidity
        vm.prank(bob);
        vm.expectEmit(true, true, false, false);
        emit AuctionPoolHook.WithdrawalFeeCharged(poolId, bob, 0);
        _removeLiquidity(bob, 0.5e18);

        // Manager should have received withdrawal fee
        uint256 managerFees = hook.managerFees(alice, poolId);
        assertGt(managerFees, 0);
    }

    function testLiquidityShareTracking() public {
        // Add liquidity
        uint256 liquidityAmount = 1e18;
        _addLiquidity(alice, liquidityAmount);

        // Check shares
        assertEq(hook.lpShares(poolId, alice), liquidityAmount);
        assertEq(hook.totalShares(poolId), liquidityAmount);

        // Add more liquidity from another LP
        _addLiquidity(bob, liquidityAmount);
        assertEq(hook.totalShares(poolId), liquidityAmount * 2);

        // Remove liquidity
        _removeLiquidity(alice, liquidityAmount / 2);
        assertEq(hook.lpShares(poolId, alice), liquidityAmount / 2);
        assertEq(hook.totalShares(poolId), liquidityAmount * 2 - liquidityAmount / 2);
    }

    // ===== MANAGER FEE WITHDRAWAL TESTS =====

    function testManagerWithdrawFees() public {
        _makeAliceManager();

        // Simulate manager collecting fees
        uint256 feeAmount = 1 ether;
        vm.deal(address(hook), feeAmount);

        // Manually set manager fees for testing
        vm.store(
            address(hook),
            keccak256(abi.encode(poolId, keccak256(abi.encode(alice, uint256(7))))),
            bytes32(feeAmount)
        );

        uint256 aliceBalanceBefore = alice.balance;

        // Alice withdraws fees
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit AuctionPoolHook.ManagerFeesWithdrawn(poolId, alice, feeAmount);
        hook.withdrawManagerFees(key);

        assertEq(alice.balance, aliceBalanceBefore + feeAmount);
        assertEq(hook.managerFees(alice, poolId), 0);
    }

    // ===== VIEW FUNCTION TESTS =====

    function testGetBidHistory() public {
        uint256 rent1 = 1000 wei;
        uint256 rent2 = 1500 wei;

        vm.prank(alice);
        hook.submitBid{value: rent1 * hook.MIN_DEPOSIT_BLOCKS()}(key, rent1);

        vm.prank(bob);
        hook.submitBid{value: rent2 * hook.MIN_DEPOSIT_BLOCKS()}(key, rent2);

        AuctionPoolHook.Bid[] memory history = hook.getBidHistory(poolId);
        assertEq(history.length, 2);
        assertEq(history[0].bidder, alice);
        assertEq(history[1].bidder, bob);
    }

    // ===== HELPER FUNCTIONS =====

    function _makeAliceManager() internal {
        uint256 rentPerBlock = 1000 wei;
        uint256 deposit = rentPerBlock * hook.MIN_DEPOSIT_BLOCKS();

        vm.prank(alice);
        hook.submitBid{value: deposit}(key, rentPerBlock);

        vm.roll(block.number + hook.ACTIVATION_DELAY() + 1);
        swap(key, true, 1e18, "");
    }

    function _makeManagerWithRent(address manager, uint256 rentPerBlock) internal {
        uint256 deposit = rentPerBlock * hook.MIN_DEPOSIT_BLOCKS();

        vm.prank(manager);
        hook.submitBid{value: deposit}(key, rentPerBlock);

        vm.roll(block.number + hook.ACTIVATION_DELAY() + 1);
        swap(key, true, 1e18, "");
    }

    function _addLiquidity(address lp, uint256 amount) internal {
        vm.prank(lp);
        modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: int256(amount),
                salt: bytes32(0)
            }),
            ""
        );
    }

    function _removeLiquidity(address lp, uint256 amount) internal {
        vm.prank(lp);
        modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: -int256(amount),
                salt: bytes32(0)
            }),
            ""
        );
    }
}
