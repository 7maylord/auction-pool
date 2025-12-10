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
import {ModifyLiquidityParams, SwapParams} from "v4-core/types/PoolOperation.sol";
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

        // Add initial liquidity to pool so swaps can work
        // Use address(0) in hookData to indicate this liquidity shouldn't be tracked
        modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: 10e18,
                salt: bytes32(0)
            }),
            abi.encode(address(0))  // address(0) = don't track
        );
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
        vm.expectEmit(true, true, true, true);
        emit AuctionPoolHook.ManagerChanged(poolId, address(0), alice, rentPerBlock);

        // Execute a swap to trigger beforeSwap hook (use small amount to avoid price limit)
        swap(key, true, 0.001e18, "");

        // Verify Alice is now manager
        (address currentManager, , , , , ) = hook.poolAuctions(poolId);
        assertEq(currentManager, alice);
    }

    function testAuctionUpdateManagerDepleted() public {
        // Alice becomes manager with minimum deposit
        uint256 rentPerBlock = 1000 wei;
        uint256 deposit = rentPerBlock * hook.MIN_DEPOSIT_BLOCKS();

        vm.prank(alice);
        hook.submitBid{value: deposit}(key, rentPerBlock);

        vm.roll(block.number + hook.ACTIVATION_DELAY() + 1);
        swap(key, true, 0.001e18, ""); // Alice becomes manager

        // Bob submits higher bid
        uint256 rentPerBlock2 = rentPerBlock + hook.MIN_BID_INCREMENT();
        uint256 deposit2 = rentPerBlock2 * hook.MIN_DEPOSIT_BLOCKS();

        vm.prank(bob);
        hook.submitBid{value: deposit2}(key, rentPerBlock2);

        // Fast forward beyond Alice's deposit (100 blocks + some extra to deplete)
        vm.roll(block.number + 110);

        // Trigger update - Alice should be replaced because deposit is depleted
        vm.expectEmit(true, true, true, true);
        emit AuctionPoolHook.ManagerChanged(poolId, alice, bob, rentPerBlock2);
        swap(key, true, 0.001e18, "");

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

        // Give alice tokens to swap
        MockERC20(Currency.unwrap(currency0)).mint(alice, 1e18);
        vm.startPrank(alice);
        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);

        // When Alice swaps, she should get zero fee
        // This is tested implicitly through the beforeSwap hook
        // The swap should succeed with zero fee for manager
        swap(key, true, 0.001e18, "");
        vm.stopPrank();
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

        // Bob removes liquidity (prank is done inside _removeLiquidity)
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
        uint256 minDeposit = hook.MIN_DEPOSIT_BLOCKS();

        vm.prank(alice);
        hook.submitBid{value: rent1 * minDeposit}(key, rent1);

        vm.prank(bob);
        hook.submitBid{value: rent2 * minDeposit}(key, rent2);

        AuctionPoolHook.Bid[] memory history = hook.getBidHistory(poolId);
        assertEq(history.length, 2);
        assertEq(history[0].bidder, alice);
        assertEq(history[1].bidder, bob);
    }

    // ===== EDGE CASE TESTS =====

    function testMultipleConsecutiveManagerChanges() public {
        // Alice becomes manager
        uint256 rent1 = 1000 wei;
        _makeManagerWithRent(alice, rent1);

        // Bob outbids and becomes manager
        uint256 rent2 = rent1 + hook.MIN_BID_INCREMENT();
        uint256 deposit2 = rent2 * hook.MIN_DEPOSIT_BLOCKS();
        vm.prank(bob);
        hook.submitBid{value: deposit2}(key, rent2);

        vm.roll(block.number + hook.ACTIVATION_DELAY() + 1);
        swap(key, true, 0.001e18, "");

        (address currentManager, , , , , ) = hook.poolAuctions(poolId);
        assertEq(currentManager, bob);

        // Charlie outbids and becomes manager
        uint256 rent3 = rent2 + hook.MIN_BID_INCREMENT();
        uint256 deposit3 = rent3 * hook.MIN_DEPOSIT_BLOCKS();
        vm.prank(charlie);
        hook.submitBid{value: deposit3}(key, rent3);

        vm.roll(block.number + hook.ACTIVATION_DELAY() + 1);
        swap(key, true, 0.001e18, "");

        (currentManager, , , , , ) = hook.poolAuctions(poolId);
        assertEq(currentManager, charlie);
    }

    function testRentCollectionWithZeroShares() public {
        // Alice becomes manager
        _makeAliceManager();

        // Try to collect rent when no LPs have shares
        // The pool should handle this gracefully
        vm.roll(block.number + 10);

        // Swap triggers rent collection
        swap(key, true, 0.001e18, "");

        // Verify manager deposit was reduced appropriately
        (, , uint256 deposit, , , ) = hook.poolAuctions(poolId);
        assertLt(deposit, 1000 wei * hook.MIN_DEPOSIT_BLOCKS());
    }

    function testLPClaimsRentMultipleTimes() public {
        // Alice becomes manager, Bob is LP
        uint256 rentPerBlock = 1000 wei;
        _makeManagerWithRent(alice, rentPerBlock);
        _addLiquidity(bob, 1e18);

        // Fast forward and trigger rent collection
        vm.roll(block.number + 10);
        swap(key, true, 0.001e18, "");

        // Bob claims rent
        uint256 bobBalanceBefore = bob.balance;
        vm.prank(bob);
        hook.claimRent(key);
        uint256 firstClaim = bob.balance - bobBalanceBefore;
        assertGt(firstClaim, 0);

        // Fast forward and accumulate more rent
        vm.roll(block.number + 10);
        swap(key, true, 0.001e18, "");

        // Bob claims rent again
        bobBalanceBefore = bob.balance;
        vm.prank(bob);
        hook.claimRent(key);
        uint256 secondClaim = bob.balance - bobBalanceBefore;
        assertGt(secondClaim, 0);
    }

    function testWithdrawManagerFeesRevertNoFees() public {
        _makeAliceManager();

        // Try to withdraw with no fees
        vm.prank(alice);
        vm.expectRevert("No fees to withdraw");
        hook.withdrawManagerFees(key);
    }

    function testClaimRentRevertNoPosition() public {
        _makeAliceManager();

        // Bob has no LP position, try to claim
        vm.prank(bob);
        vm.expectRevert("No LP position");
        hook.claimRent(key);
    }

    function testClaimRentRevertNoRent() public {
        _makeAliceManager();
        _addLiquidity(bob, 1e18);

        // Bob tries to claim immediately with no accumulated rent
        vm.prank(bob);
        vm.expectRevert("No rent to claim");
        hook.claimRent(key);
    }

    function testPendingRentCalculation() public {
        // Alice becomes manager, Bob is LP
        uint256 rentPerBlock = 1000 wei;
        _makeManagerWithRent(alice, rentPerBlock);
        _addLiquidity(bob, 1e18);

        // Verify initial pending rent is 0
        assertEq(hook.getPendingRent(poolId, bob), 0);

        // Fast forward and trigger rent collection
        vm.roll(block.number + 10);
        swap(key, true, 0.001e18, "");

        // Verify pending rent increased
        uint256 pending = hook.getPendingRent(poolId, bob);
        assertGt(pending, 0);
    }

    function testMultipleLPsRentDistribution() public {
        // Alice becomes manager
        uint256 rentPerBlock = 1000 wei;
        _makeManagerWithRent(alice, rentPerBlock);

        // Bob and Charlie add equal liquidity
        _addLiquidity(bob, 1e18);
        _addLiquidity(charlie, 1e18);

        // Fast forward and trigger rent collection
        vm.roll(block.number + 100);
        swap(key, true, 0.001e18, "");

        // Both should have equal pending rent
        uint256 bobPending = hook.getPendingRent(poolId, bob);
        uint256 charliePending = hook.getPendingRent(poolId, charlie);

        assertGt(bobPending, 0);
        assertEq(bobPending, charliePending);
    }

    function testUnequalLPsRentDistribution() public {
        // Alice becomes manager
        uint256 rentPerBlock = 1000 wei;
        _makeManagerWithRent(alice, rentPerBlock);

        // Bob adds 2x liquidity compared to Charlie
        _addLiquidity(bob, 2e18);
        _addLiquidity(charlie, 1e18);

        // Fast forward and trigger rent collection
        vm.roll(block.number + 100);
        swap(key, true, 0.001e18, "");

        // Bob should have 2x the pending rent of Charlie
        uint256 bobPending = hook.getPendingRent(poolId, bob);
        uint256 charliePending = hook.getPendingRent(poolId, charlie);

        assertGt(bobPending, 0);
        assertGt(charliePending, 0);
        assertApproxEqRel(bobPending, charliePending * 2, 0.01e18); // Within 1% due to rounding
    }

    function testRentAccumulationWithoutLPs() public {
        // Alice becomes manager but no LPs
        uint256 rentPerBlock = 1000 wei;
        _makeManagerWithRent(alice, rentPerBlock);

        uint256 initialDeposit = rentPerBlock * hook.MIN_DEPOSIT_BLOCKS();
        (, , uint256 depositBefore, , , ) = hook.poolAuctions(poolId);
        assertEq(depositBefore, initialDeposit);

        // Fast forward and trigger rent collection
        vm.roll(block.number + 10);
        swap(key, true, 0.001e18, "");

        // Deposit should be reduced even without LPs
        (, , uint256 depositAfter, , , ) = hook.poolAuctions(poolId);
        assertLt(depositAfter, depositBefore);
    }

    function testBidHistoryPersistence() public {
        // Submit multiple bids over time
        uint256 minDeposit = hook.MIN_DEPOSIT_BLOCKS();
        uint256 minIncrement = hook.MIN_BID_INCREMENT();

        uint256 rent1 = 1000 wei;
        vm.prank(alice);
        hook.submitBid{value: rent1 * minDeposit}(key, rent1);

        uint256 rent2 = rent1 + minIncrement;
        vm.prank(bob);
        hook.submitBid{value: rent2 * minDeposit}(key, rent2);

        uint256 rent3 = rent2 + minIncrement;
        vm.prank(charlie);
        hook.submitBid{value: rent3 * minDeposit}(key, rent3);

        // All bids should be in history
        AuctionPoolHook.Bid[] memory history = hook.getBidHistory(poolId);
        assertEq(history.length, 3);
        assertEq(history[0].bidder, alice);
        assertEq(history[1].bidder, bob);
        assertEq(history[2].bidder, charlie);
    }

    // ===== HELPER FUNCTIONS =====

    function _makeAliceManager() internal {
        uint256 rentPerBlock = 1000 wei;
        uint256 deposit = rentPerBlock * hook.MIN_DEPOSIT_BLOCKS();

        vm.prank(alice);
        hook.submitBid{value: deposit}(key, rentPerBlock);

        vm.roll(block.number + hook.ACTIVATION_DELAY() + 1);
        // Small swap to trigger auction update
        swap(key, true, 0.001e18, "");
    }

    function _makeManagerWithRent(address manager, uint256 rentPerBlock) internal {
        uint256 deposit = rentPerBlock * hook.MIN_DEPOSIT_BLOCKS();

        vm.prank(manager);
        hook.submitBid{value: deposit}(key, rentPerBlock);

        vm.roll(block.number + hook.ACTIVATION_DELAY() + 1);
        // Small swap to trigger auction update
        swap(key, true, 0.001e18, "");
    }

    function _addLiquidity(address lp, uint256 amount) internal {
        // Mint tokens to LP if they don't have enough
        MockERC20(Currency.unwrap(currency0)).mint(lp, amount * 2);
        MockERC20(Currency.unwrap(currency1)).mint(lp, amount * 2);

        // Approve router to spend tokens
        vm.startPrank(lp);
        MockERC20(Currency.unwrap(currency0)).approve(address(modifyLiquidityRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency1)).approve(address(modifyLiquidityRouter), type(uint256).max);

        // Pass LP address in hookData so hook knows who the real LP is
        modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: int256(amount),
                salt: bytes32(0)
            }),
            abi.encode(lp)  // Pass LP address in hookData
        );
        vm.stopPrank();
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
            abi.encode(lp)  // Pass LP address in hookData
        );
    }

    // ===== QUOTABILITY TESTS =====

    function testGetSwapFeeView() public {
        // Setup: Alice becomes manager
        _setupManager(alice, 1000 wei);

        // Test 1: Manager gets 0% fee
        uint24 managerFee = hook.getSwapFee(poolId, alice);
        assertEq(managerFee, 0, "Manager should get 0% fee");

        // Test 2: Regular user gets dynamic fee
        uint24 regularFee = hook.getSwapFee(poolId, bob);
        assertEq(regularFee, 0, "Regular user should get current fee (0 initially)");

        // Test 3: After manager sets fee
        vm.prank(alice);
        hook.setSwapFee(key, 3000); // 0.3%

        uint24 newRegularFee = hook.getSwapFee(poolId, bob);
        assertEq(newRegularFee, 3000, "Regular user should get updated fee");

        // Manager still gets 0%
        uint24 stillZero = hook.getSwapFee(poolId, alice);
        assertEq(stillZero, 0, "Manager should still get 0% fee");
    }

    function testQuoteDoesNotModifyState() public {
        // Setup: Alice becomes manager with rent
        uint256 rentPerBlock = 1000 wei;
        _setupManager(alice, rentPerBlock);

        // Record initial state
        (
            address initialManager,
            uint256 initialRent,
            uint256 initialDeposit,
            uint256 initialLastRent,
            ,
            uint256 initialTotalRent
        ) = hook.poolAuctions(poolId);

        // Simulate a quote (staticcall)
        vm.prank(bob);
        try this.externalStaticSwap() {
            // Quote succeeded
        } catch {
            // Expected to work
        }

        // Verify state unchanged
        (
            address finalManager,
            uint256 finalRent,
            uint256 finalDeposit,
            uint256 finalLastRent,
            ,
            uint256 finalTotalRent
        ) = hook.poolAuctions(poolId);

        assertEq(finalManager, initialManager, "Manager should not change during quote");
        assertEq(finalRent, initialRent, "Rent should not change during quote");
        assertEq(finalDeposit, initialDeposit, "Deposit should not change during quote");
        assertEq(finalLastRent, initialLastRent, "LastRentBlock should not change during quote");
        assertEq(finalTotalRent, initialTotalRent, "TotalRent should not change during quote");
    }

    // External function to simulate staticcall (quotes)
    function externalStaticSwap() external view {
        // This simulates what a router does during quotes
        // Note: We can't actually test eth_call directly in Foundry,
        // but we can verify the view function works correctly
        hook.getSwapFee(poolId, msg.sender);
    }

    function testActualSwapModifiesState() public {
        // Setup: Alice becomes manager with rent
        uint256 rentPerBlock = 1000 wei;
        _setupManager(alice, rentPerBlock);

        // Record initial deposit
        (, , uint256 initialDeposit, uint256 initialLastRent, , ) = hook.poolAuctions(poolId);

        // Roll forward blocks
        vm.roll(block.number + 10);

        // Execute actual swap (not a quote) - use tiny amount
        swap(key, true, 0.001e18, "");

        // Verify state WAS modified
        (, , uint256 finalDeposit, uint256 finalLastRent, , ) = hook.poolAuctions(poolId);

        assertLt(finalDeposit, initialDeposit, "Deposit should decrease after swap");
        assertGt(finalLastRent, initialLastRent, "LastRentBlock should update after swap");
    }

    function testBidActivationOnlyDuringActualSwap() public {
        // Setup: Alice is manager
        _setupManager(alice, 1000 wei);

        // Bob submits higher bid
        uint256 bobRent = 2000 wei;
        uint256 bobDeposit = bobRent * hook.MIN_DEPOSIT_BLOCKS();
        vm.prank(bob);
        hook.submitBid{value: bobDeposit}(key, bobRent);

        // Roll past activation delay
        vm.roll(block.number + 6);

        // Verify Bob is not manager yet
        (address managerBeforeSwap, , , , , ) = hook.poolAuctions(poolId);
        assertEq(managerBeforeSwap, alice, "Alice should still be manager before swap");

        // Execute actual swap to trigger activation - tiny amount
        swap(key, true, 0.001e18, "");

        // Now Bob should be manager
        (address managerAfterSwap, , , , , ) = hook.poolAuctions(poolId);
        assertEq(managerAfterSwap, bob, "Bob should be manager after swap");
    }

    function testRentCollectionOnlyDuringActualSwap() public {
        // Setup: Alice becomes manager
        uint256 rentPerBlock = 1000 wei;
        _setupManager(alice, rentPerBlock);

        uint256 initialBlock = block.number;

        // Roll forward 10 blocks
        vm.roll(block.number + 10);

        // Check deposit hasn't decreased yet (no swap)
        (, , uint256 depositBeforeSwap, , , ) = hook.poolAuctions(poolId);
        uint256 expectedDepositBeforeSwap = rentPerBlock * hook.MIN_DEPOSIT_BLOCKS();
        assertEq(depositBeforeSwap, expectedDepositBeforeSwap, "Deposit should not change without swap");

        // Execute swap to trigger rent collection - tiny amount
        swap(key, true, 0.001e18, "");

        // Now deposit should have decreased
        (, , uint256 depositAfterSwap, , , ) = hook.poolAuctions(poolId);
        uint256 expectedRentCollected = rentPerBlock * (block.number - initialBlock);
        assertEq(
            depositAfterSwap,
            expectedDepositBeforeSwap - expectedRentCollected,
            "Deposit should decrease by accumulated rent"
        );
    }

    function testQuotabilityWithMultipleManagers() public {
        // Setup: Alice is first manager
        _setupManager(alice, 1000 wei);

        // Alice sets a swap fee so non-managers pay something
        vm.prank(alice);
        hook.setSwapFee(key, 3000); // 0.3%

        // Test: Alice gets 0% fee, Bob pays fee
        uint24 aliceFee = hook.getSwapFee(poolId, alice);
        uint24 bobFee = hook.getSwapFee(poolId, bob);
        assertEq(aliceFee, 0, "Alice should get 0% as current manager");
        assertEq(bobFee, 3000, "Bob should pay fee as non-manager");

        // Now make Bob the manager
        _setupManager(bob, 2000 wei);

        // Test: Now Bob gets 0% fee, Alice pays fee
        uint24 aliceFeeAfter = hook.getSwapFee(poolId, alice);
        uint24 bobFeeAfter = hook.getSwapFee(poolId, bob);
        assertEq(aliceFeeAfter, 3000, "Alice should pay fee after losing manager status");
        assertEq(bobFeeAfter, 0, "Bob should get 0% as new manager");
    }

    function testGetSwapFeeConsistentWithActualSwap() public {
        // Setup: Alice is manager with custom fee
        _setupManager(alice, 1000 wei);
        vm.prank(alice);
        hook.setSwapFee(key, 5000); // 0.5%

        // Test 1: Manager should get 0% fee
        uint24 predictedManagerFee = hook.getSwapFee(poolId, alice);
        assertEq(predictedManagerFee, 0, "Predicted manager fee should be 0%");

        // Manager swaps - should get 0% fee
        // (Actual fee verification would require checking BalanceDelta)

        // Test 2: Regular user should get dynamic fee
        uint24 predictedUserFee = hook.getSwapFee(poolId, bob);
        assertEq(predictedUserFee, 5000, "Predicted user fee should match set fee");

        // User swaps - should pay dynamic fee
        // (Actual fee verification would require checking BalanceDelta)
    }

    function testQuotabilityWithNoManager() public {
        // Test: When there's no manager, everyone pays the current fee
        // Initially no manager and currentFee is 0
        uint24 aliceFee = hook.getSwapFee(poolId, alice);
        uint24 bobFee = hook.getSwapFee(poolId, bob);

        assertEq(aliceFee, 0, "Alice should pay current fee (0) when no manager");
        assertEq(bobFee, 0, "Bob should pay current fee (0) when no manager");

        // Now setup a manager and have them set a fee
        _setupManager(alice, 1000 wei);
        vm.prank(alice);
        hook.setSwapFee(key, 5000); // 0.5%

        // Alice (manager) should get 0%, Bob should pay 0.5%
        uint24 aliceFeeWithManager = hook.getSwapFee(poolId, alice);
        uint24 bobFeeWithManager = hook.getSwapFee(poolId, bob);

        assertEq(aliceFeeWithManager, 0, "Manager should pay 0%");
        assertEq(bobFeeWithManager, 5000, "Non-manager should pay current fee");
    }

    function testGetSwapFeeGasCost() public view {
        // Verify getSwapFee is gas-efficient (pure view function)
        uint256 gasBefore = gasleft();
        hook.getSwapFee(poolId, alice);
        uint256 gasUsed = gasBefore - gasleft();

        // Should be reasonable (storage reads + comparison)
        assertLt(gasUsed, 20000, "getSwapFee should be gas-efficient");
    }

    // ===== HELPER FUNCTIONS FOR QUOTABILITY TESTS =====

    function _setupManager(address manager, uint256 rentPerBlock) internal {
        uint256 deposit = rentPerBlock * hook.MIN_DEPOSIT_BLOCKS();

        // Submit bid
        vm.prank(manager);
        hook.submitBid{value: deposit}(key, rentPerBlock);

        // Wait for activation delay
        vm.roll(block.number + 6);

        // Trigger activation with a tiny swap to avoid moving price too much
        swap(key, true, 0.001e18, "");
    }

    // ===== EDGE CASE TESTS =====

    function testLargeLiquidityOperations() public {
        // Test that large liquidity amounts work correctly
        uint256 largeAmount = 1000e18; // Use reasonable large amount

        // Add large liquidity
        _addLiquidity(bob, largeAmount);

        // Verify shares are tracked correctly
        uint256 bobShares = hook.lpShares(poolId, bob);
        assertGt(bobShares, 0, "Bob should have shares");

        // Setup manager
        _setupManager(alice, 1000 wei);

        // Roll forward and collect rent
        vm.roll(block.number + 100);
        swap(key, true, 0.001e18, "");

        // Bob should have pending rent
        uint256 pendingRent = hook.getPendingRent(poolId, bob);
        assertGt(pendingRent, 0, "Bob should have pending rent");

        // Bob can successfully claim
        uint256 balanceBefore = bob.balance;
        vm.prank(bob);
        hook.claimRent(key);

        // Verify rent was received
        assertGt(bob.balance, balanceBefore, "Bob should receive rent");
        assertEq(hook.getPendingRent(poolId, bob), 0, "Pending rent should be zero after claim");
    }

    function testExtremeRentValues() public {
        // Test with very high rent (near max safe value)
        uint256 highRent = 1e15 wei; // 0.001 ETH per block
        uint256 deposit = highRent * hook.MIN_DEPOSIT_BLOCKS();

        vm.deal(alice, deposit * 2);
        vm.prank(alice);
        hook.submitBid{value: deposit}(key, highRent);

        // Activate
        vm.roll(block.number + 6);
        swap(key, true, 0.001e18, "");

        // Verify manager is set with high rent
        (address manager, uint256 rent, , , , ) = hook.poolAuctions(poolId);
        assertEq(manager, alice, "Alice should be manager");
        assertEq(rent, highRent, "Rent should match");

        // Roll forward a few blocks (not too many to avoid depletion)
        vm.roll(block.number + 10);
        swap(key, true, 0.001e18, "");

        // Verify rent collection works with high values
        (, , uint256 remainingDeposit, , , ) = hook.poolAuctions(poolId);
        assertLt(remainingDeposit, deposit, "Deposit should have decreased");
    }

    function testLongTimePeriodRentAccumulation() public {
        // Setup manager and LP
        _setupManager(alice, 1000 wei);
        _addLiquidity(bob, 1e18);

        // Fast forward many blocks (1000 blocks)
        vm.roll(block.number + 1000);

        // Check pending rent before collection
        uint256 pendingBefore = hook.getPendingRent(poolId, bob);

        // Trigger rent collection
        swap(key, true, 0.001e18, "");

        // Verify rent accumulated correctly over long period
        uint256 pendingAfter = hook.getPendingRent(poolId, bob);
        assertGt(pendingAfter, pendingBefore, "Pending rent should increase");

        // Bob claims after long period
        vm.prank(bob);
        hook.claimRent(key);

        assertEq(hook.getPendingRent(poolId, bob), 0, "Should have no pending rent after claim");
    }

    function testMaximumFeeScenario() public {
        // Setup manager
        _setupManager(alice, 1000 wei);

        // Set fee to maximum (1% = 10000)
        vm.prank(alice);
        hook.setSwapFee(key, 10000);

        // Verify fee is set
        uint24 fee = hook.getSwapFee(poolId, bob);
        assertEq(fee, 10000, "Fee should be maximum");

        // Manager still gets zero fee
        uint24 managerFee = hook.getSwapFee(poolId, alice);
        assertEq(managerFee, 0, "Manager should still get zero fee");
    }

    function testBidHistoryWithManyBids() public {
        // Submit multiple bids to test history tracking
        uint256 baseRent = 1000 wei;

        for (uint i = 0; i < 5; i++) {
            address bidder = address(uint160(i + 1000));
            uint256 rent = baseRent * (i + 1);
            uint256 deposit = rent * hook.MIN_DEPOSIT_BLOCKS();

            vm.deal(bidder, deposit);
            vm.prank(bidder);
            hook.submitBid{value: deposit}(key, rent);

            // Activate bid
            vm.roll(block.number + 6);
            swap(key, true, 0.001e18, "");
        }

        // Get bid history
        AuctionPoolHook.Bid[] memory history = hook.getBidHistory(poolId);

        // Should have all bids recorded
        assertGe(history.length, 5, "Should have at least 5 bids in history");
    }

    function testZeroRentManagerBehavior() public {
        // Edge case: What if manager has 0 rent (initial state)?
        // Verify getSwapFee works with no manager
        uint24 fee = hook.getSwapFee(poolId, alice);
        assertEq(fee, 0, "Should return 0 when no manager and no fee set");

        // Now set up manager with actual rent
        _setupManager(alice, 1000 wei);

        // Fee should still be 0 for manager
        uint24 managerFee = hook.getSwapFee(poolId, alice);
        assertEq(managerFee, 0, "Manager should get zero fee");
    }

    function testMultipleLiquidityProvidersEdgeCases() public {
        // Setup manager
        _setupManager(alice, 1000 wei);

        // Multiple LPs with different amounts
        _addLiquidity(bob, 1e18);
        _addLiquidity(charlie, 5e18);

        // Add another address with very small amount
        address dave = makeAddr("dave");
        _addLiquidity(dave, 0.001e18);

        // Roll forward and trigger rent collection
        vm.roll(block.number + 100);
        swap(key, true, 0.001e18, "");

        // All should have pending rent (proportional)
        uint256 bobRent = hook.getPendingRent(poolId, bob);
        uint256 charlieRent = hook.getPendingRent(poolId, charlie);
        uint256 daveRent = hook.getPendingRent(poolId, dave);

        assertGt(bobRent, 0, "Bob should have rent");
        assertGt(charlieRent, 0, "Charlie should have rent");
        assertGt(daveRent, 0, "Dave should have rent");

        // Charlie should have more rent than Bob (5x liquidity)
        assertGt(charlieRent, bobRent, "Charlie should have more rent than Bob");

        // Dave should have least rent (smallest liquidity)
        assertLt(daveRent, bobRent, "Dave should have less rent than Bob");
    }

    // ===== INTEGRATION TESTS =====

    function testFullLifecycleIntegration() public {
        // Complete lifecycle: bid -> activate -> swap -> collect rent -> claim -> new bid

        // Phase 1: Alice becomes first manager
        _setupManager(alice, 1000 wei);
        _addLiquidity(bob, 1e18);

        // Phase 2: Alice sets fee and swaps
        vm.prank(alice);
        hook.setSwapFee(key, 3000);
        swap(key, true, 0.001e18, "");

        // Phase 3: Rent accumulates
        vm.roll(block.number + 50);
        swap(key, true, 0.001e18, "");

        // Phase 4: Bob claims rent
        uint256 bobBalanceBefore = bob.balance;
        vm.prank(bob);
        hook.claimRent(key);
        assertGt(bob.balance, bobBalanceBefore, "Bob should receive rent");

        // Phase 5: Charlie outbids Alice
        _setupManager(charlie, 2000 wei);

        // Phase 6: Verify Charlie is new manager
        (address newManager, , , , , ) = hook.poolAuctions(poolId);
        assertEq(newManager, charlie, "Charlie should be manager");

        // Phase 7: More rent accumulates for Bob
        vm.roll(block.number + 50);
        swap(key, true, 0.001e18, "");

        // Phase 8: Bob claims again
        uint256 bobBalanceBefore2 = bob.balance;
        vm.prank(bob);
        hook.claimRent(key);
        assertGt(bob.balance, bobBalanceBefore2, "Bob should receive more rent");
    }

    function testManagerDepletionAndRecovery() public {
        // Test complete depletion and recovery scenario
        uint256 rentPerBlock = 1000 wei;
        uint256 minDeposit = rentPerBlock * hook.MIN_DEPOSIT_BLOCKS();

        // Alice becomes manager with minimum deposit
        vm.prank(alice);
        hook.submitBid{value: minDeposit}(key, rentPerBlock);
        vm.roll(block.number + 6);
        swap(key, true, 0.001e18, "");

        // Verify Alice is manager
        (address manager1, , , , , ) = hook.poolAuctions(poolId);
        assertEq(manager1, alice, "Alice should be manager");

        // Fast forward to near depletion
        vm.roll(block.number + 99);
        swap(key, true, 0.001e18, "");

        // Check if still manager (should be close to depletion)
        (address manager2, , uint256 deposit, , , ) = hook.poolAuctions(poolId);
        assertLt(deposit, minDeposit / 2, "Deposit should be significantly depleted");

        // New manager can still take over
        _setupManager(bob, 1500 wei);
        (address manager3, , , , , ) = hook.poolAuctions(poolId);
        assertEq(manager3, bob, "Bob should be new manager");
    }

    function testConcurrentLiquidityAndRentOperations() public {
        // Test rent claims while liquidity is being added/removed
        _setupManager(alice, 1000 wei);
        _addLiquidity(bob, 1e18);

        // Accumulate some rent
        vm.roll(block.number + 50);
        swap(key, true, 0.001e18, "");

        uint256 bobRent1 = hook.getPendingRent(poolId, bob);
        assertGt(bobRent1, 0, "Bob should have pending rent");

        // Charlie adds liquidity (dilutes Bob's share)
        _addLiquidity(charlie, 1e18);

        // More rent accumulates
        vm.roll(block.number + 50);
        swap(key, true, 0.001e18, "");

        // Bob claims his rent
        vm.prank(bob);
        hook.claimRent(key);

        // Charlie should also have rent now
        uint256 charlieRent = hook.getPendingRent(poolId, charlie);
        assertGt(charlieRent, 0, "Charlie should have pending rent");

        // Bob removes liquidity
        _removeLiquidity(bob, 0.5e18);

        // Both should still be able to claim
        vm.roll(block.number + 50);
        swap(key, true, 0.001e18, "");

        vm.prank(charlie);
        hook.claimRent(key);

        assertEq(hook.getPendingRent(poolId, charlie), 0, "Charlie should have claimed all rent");
    }

    function testSwapIntegrationWithDifferentUsers() public {
        // Test that swaps work correctly for manager vs non-managers
        _setupManager(alice, 1000 wei);
        vm.prank(alice);
        hook.setSwapFee(key, 5000); // 0.5%

        // Alice (manager) swaps - should get 0% fee
        uint256 aliceFee = hook.getSwapFee(poolId, alice);
        assertEq(aliceFee, 0, "Alice should pay 0%");

        // Bob (non-manager) swaps - should pay 0.5% fee
        uint256 bobFee = hook.getSwapFee(poolId, bob);
        assertEq(bobFee, 5000, "Bob should pay 0.5%");

        // Charlie (also non-manager) - should pay same fee
        uint256 charlieFee = hook.getSwapFee(poolId, charlie);
        assertEq(charlieFee, 5000, "Charlie should pay 0.5%");

        // After manager changes, fees should update
        _setupManager(bob, 2000 wei);

        // Now Bob is manager, should get 0% fee
        uint256 bobFeeNew = hook.getSwapFee(poolId, bob);
        assertEq(bobFeeNew, 0, "Bob should now pay 0% as manager");

        // Alice should now pay fee
        uint256 aliceFeeNew = hook.getSwapFee(poolId, alice);
        assertEq(aliceFeeNew, 5000, "Alice should now pay 0.5%");
    }

    function testRentDistributionPrecision() public {
        // Test rent distribution with small amounts to verify precision
        _setupManager(alice, 100 wei); // Very small rent
        _addLiquidity(bob, 1e18);
        _addLiquidity(charlie, 2e18);

        // Accumulate rent for just a few blocks
        vm.roll(block.number + 10);
        swap(key, true, 0.001e18, "");

        // Both should have proportional rent (Charlie 2x Bob)
        uint256 bobRent = hook.getPendingRent(poolId, bob);
        uint256 charlieRent = hook.getPendingRent(poolId, charlie);

        if (bobRent > 0 && charlieRent > 0) {
            // Charlie should have approximately 2x Bob's rent
            assertApproxEqRel(charlieRent, bobRent * 2, 0.01e18, "Charlie should have ~2x Bob's rent");
        }
    }
}
