// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {SwapMath} from '@uniswap/v4-core/src/libraries/SwapMath.sol';
import {Hooks, IHooks} from '@uniswap/v4-core/src/libraries/Hooks.sol';
import {BalanceDelta} from '@uniswap/v4-core/src/types/BalanceDelta.sol';
import {Currency, CurrencyLibrary} from '@uniswap/v4-core/src/types/Currency.sol';
import {PoolId, PoolIdLibrary} from '@uniswap/v4-core/src/types/PoolId.sol';
import {PoolKey} from '@uniswap/v4-core/src/types/PoolKey.sol';
import {BeforeSwapDelta, BeforeSwapDeltaLibrary, toBeforeSwapDelta} from '@uniswap/v4-core/src/types/BeforeSwapDelta.sol';
import {ModifyLiquidityParams, SwapParams} from '@uniswap/v4-core/src/types/PoolOperation.sol';
import {StateLibrary} from '@uniswap/v4-core/src/libraries/StateLibrary.sol';
import {CurrencySettler} from '@uniswap/v4-core/test/utils/CurrencySettler.sol';
import {LPFeeLibrary} from '@uniswap/v4-core/src/libraries/LPFeeLibrary.sol';

import {IERC20Minimal} from '@uniswap/v4-core/src/interfaces/external/IERC20Minimal.sol';
import {IPoolManager} from '@uniswap/v4-core/src/interfaces/IPoolManager.sol';

import {BaseHook} from 'v4-periphery/src/utils/BaseHook.sol';


contract AuctionPoolHook is BaseHook {

    using CurrencyLibrary for Currency;
    using CurrencySettler for Currency;
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;

    struct AuctionState {
        address currentManager;      // Current pool manager address
        uint256 rentPerBlock;        // Current rent rate (wei per block)
        uint256 managerDeposit;      // Manager's remaining deposit
        uint256 lastRentBlock;       // Last block rent was collected
        uint24 currentFee;           // Current swap fee (in hundredths of bps)
        uint256 totalRentPaid;       // Cumulative rent paid (for stats)
    }

    struct Bid {
        address bidder;              // Address of bidder
        uint256 rentPerBlock;        // Rent they're willing to pay
        uint256 deposit;             // Upfront deposit amount
        uint256 activationBlock;     // Block when bid becomes active
        uint256 timestamp;           // When bid was submitted
    }

    uint24 public constant MAX_FEE = 10000;           // 1% max fee (in hundredths of bps)
    uint256 public constant ACTIVATION_DELAY = 5;      // blocks
    uint24 public constant WITHDRAWAL_FEE = 1;         // 0.01% (in hundredths of bps)
    uint256 public constant MIN_BID_INCREMENT = 100;   // 100 wei/block minimum increase
    uint256 public constant MIN_DEPOSIT_BLOCKS = 100;  // Deposit must cover 100 blocks

    /// Pool ID => Auction State
    mapping(PoolId => AuctionState) public poolAuctions;

    /// Pool ID => Next highest bid (waiting to activate)
    mapping(PoolId => Bid) public nextBid;

    /// Pool ID => Bid history (for analytics)
    mapping(PoolId => Bid[]) public bidHistory;

    /// Pool ID => LP address => shares
    mapping(PoolId => mapping(address => uint256)) public lpShares;

    /// Pool ID => total shares
    mapping(PoolId => uint256) public totalShares;

    /// Pool ID => accumulated rent per share (scaled by 1e18)
    mapping(PoolId => uint256) public rentPerShareAccumulated;

    /// Pool ID => LP address => rent per share already claimed
    mapping(PoolId => mapping(address => uint256)) public rentPerShareClaimed;

    /// Manager address => Pool ID => collected fees
    mapping(address => mapping(PoolId => uint256)) public managerFees;

    
    constructor(address _poolManager) BaseHook(IPoolManager(_poolManager)) {}

    // ===== EVENTS =====

    event BidSubmitted(
        PoolId indexed poolId,
        address indexed bidder,
        uint256 rentPerBlock,
        uint256 deposit
    );

    event ManagerChanged(
        PoolId indexed poolId,
        address indexed oldManager,
        address indexed newManager,
        uint256 rentPerBlock
    );

    event FeeUpdated(
        PoolId indexed poolId,
        address indexed manager,
        uint24 newFee
    );

    event RentCollected(
        PoolId indexed poolId,
        uint256 amount,
        uint256 blockNumber
    );

    event RentClaimed(
        PoolId indexed poolId,
        address indexed lp,
        uint256 amount
    );

    event WithdrawalFeeCharged(
        PoolId indexed poolId,
        address indexed lp,
        uint256 fee
    );

    event ManagerFeesWithdrawn(
        PoolId indexed poolId,
        address indexed manager,
        uint256 amount
    );

    event LiquidityUpdated(
        PoolId indexed poolId,
        address indexed lp,
        uint256 shares,
        bool isAddition
    );

    
    function submitBid(
        PoolKey calldata key,
        uint256 rentPerBlock
    ) external payable {
        PoolId poolId = key.toId();
        AuctionState storage state = poolAuctions[poolId];

        // Check against the higher of current state rent or next bid rent
        uint256 currentRent = state.rentPerBlock > nextBid[poolId].rentPerBlock
            ? state.rentPerBlock
            : nextBid[poolId].rentPerBlock;

        // Validation
        require(
            rentPerBlock >= currentRent + MIN_BID_INCREMENT,
            "Bid must exceed current rent"
        );
        require(
            msg.value >= rentPerBlock * MIN_DEPOSIT_BLOCKS,
            "Insufficient deposit"
        );

        // Create bid with activation delay (censorship resistance)
        Bid memory newBid = Bid({
            bidder: msg.sender,
            rentPerBlock: rentPerBlock,
            deposit: msg.value,
            activationBlock: block.number + ACTIVATION_DELAY,
            timestamp: block.timestamp
        });

        // Refund previous next bidder if exists
        if (nextBid[poolId].bidder != address(0)) {
            _refundBid(poolId);
        }

        nextBid[poolId] = newBid;
        bidHistory[poolId].push(newBid);

        emit BidSubmitted(poolId, msg.sender, rentPerBlock, msg.value);
    }

    
    function setSwapFee(
        PoolKey calldata key,
        uint24 newFee
    ) external {
        PoolId poolId = key.toId();
        AuctionState storage state = poolAuctions[poolId];

        require(msg.sender == state.currentManager, "Not manager");
        require(newFee <= MAX_FEE, "Fee exceeds cap");

        state.currentFee = newFee;

        emit FeeUpdated(poolId, msg.sender, newFee);
    }

    
    function claimRent(PoolKey calldata key) external {
        PoolId poolId = key.toId();

        uint256 userShares = lpShares[poolId][msg.sender];
        require(userShares > 0, "No LP position");

        uint256 claimable = getPendingRent(poolId, msg.sender);
        require(claimable > 0, "No rent to claim");

        // Update claimed amount
        rentPerShareClaimed[poolId][msg.sender] = rentPerShareAccumulated[poolId];

        payable(msg.sender).transfer(claimable);

        emit RentClaimed(poolId, msg.sender, claimable);
    }

    
    function withdrawManagerFees(PoolKey calldata key) external {
        PoolId poolId = key.toId();

        uint256 fees = managerFees[msg.sender][poolId];
        require(fees > 0, "No fees to withdraw");

        managerFees[msg.sender][poolId] = 0;

        payable(msg.sender).transfer(fees);

        emit ManagerFeesWithdrawn(poolId, msg.sender, fees);
    }

    
    function getSwapFee(PoolId poolId, address sender) public view returns (uint24 swapFee) {
        AuctionState storage state = poolAuctions[poolId];

        // Manager gets zero fee for arbitrage capture
        if (sender == state.currentManager) {
            return 0;
        }

        // Everyone else pays current dynamic fee
        return state.currentFee;
    }

    
    function getPendingRent(PoolId poolId, address lp) public view returns (uint256) {
        uint256 userShares = lpShares[poolId][lp];
        if (userShares == 0) return 0;

        uint256 accumulatedRent = rentPerShareAccumulated[poolId];
        uint256 claimedRent = rentPerShareClaimed[poolId][lp];

        return (userShares * (accumulatedRent - claimedRent)) / 1e18;
    }

    
    function getBidHistory(PoolId poolId) external view returns (Bid[] memory) {
        return bidHistory[poolId];
    }

   
    function _updateAuction(PoolId poolId) internal {
        // Skip state updates during quotes (eth_call has tx.origin == address(0))
        if (tx.origin == address(0)) return;

        AuctionState storage state = poolAuctions[poolId];
        Bid storage next = nextBid[poolId];

        // Check if next bid should activate
        bool shouldActivate = (
            next.bidder != address(0) &&
            next.activationBlock <= block.number &&
            next.rentPerBlock > state.rentPerBlock
        );

        // Check if current manager ran out of deposit
        uint256 blocksSinceRent = state.lastRentBlock > 0 ? block.number - state.lastRentBlock : 0;
        uint256 rentOwed = blocksSinceRent * state.rentPerBlock;
        bool managerDepleted = (state.managerDeposit > 0 && rentOwed >= state.managerDeposit);

        if (shouldActivate || managerDepleted) {
            // Collect any outstanding rent before transition
            if (state.currentManager != address(0) && state.managerDeposit > 0 && blocksSinceRent > 0) {
                uint256 finalRent = rentOwed > state.managerDeposit ? state.managerDeposit : rentOwed;
                state.managerDeposit -= finalRent;
                state.totalRentPaid += finalRent;
                _distributeRent(poolId, finalRent);
            }

            // Refund old manager's remaining deposit
            if (state.currentManager != address(0) && state.managerDeposit > 0) {
                payable(state.currentManager).transfer(state.managerDeposit);
            }

            // Install new manager
            address oldManager = state.currentManager;
            address newManager = next.bidder;
            uint256 newRent = next.rentPerBlock;

            state.currentManager = newManager;
            state.rentPerBlock = newRent;
            state.managerDeposit = next.deposit;
            state.lastRentBlock = block.number;

            // Clear next bid
            delete nextBid[poolId];

            emit ManagerChanged(poolId, oldManager, newManager, newRent);
        }
    }

    
    function _collectRent(PoolId poolId) internal {
        // Skip state updates during quotes (eth_call has tx.origin == address(0))
        if (tx.origin == address(0)) return;

        AuctionState storage state = poolAuctions[poolId];

        if (state.currentManager == address(0) || state.lastRentBlock == 0) return;

        uint256 blocksSinceRent = block.number - state.lastRentBlock;
        uint256 rentOwed = blocksSinceRent * state.rentPerBlock;

        if (rentOwed > 0 && rentOwed <= state.managerDeposit) {
            // Deduct from manager's deposit
            state.managerDeposit -= rentOwed;
            state.lastRentBlock = block.number;
            state.totalRentPaid += rentOwed;

            // Distribute to LPs proportionally
            _distributeRent(poolId, rentOwed);

            emit RentCollected(poolId, rentOwed, block.number);
        }
    }

    
    function _distributeRent(PoolId poolId, uint256 amount) internal {
        uint256 total = totalShares[poolId];

        if (total == 0) return;

        // Update accumulated rent per share (scaled by 1e18 for precision)
        rentPerShareAccumulated[poolId] += (amount * 1e18) / total;
    }

    
    function _refundBid(PoolId poolId) internal {
        Bid storage bid = nextBid[poolId];
        if (bid.bidder != address(0) && bid.deposit > 0) {
            payable(bid.bidder).transfer(bid.deposit);
        }
    }

    
    function _beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) internal override returns (bytes4 selector_, BeforeSwapDelta beforeSwapDelta_, uint24 swapFee_) {
        PoolId poolId = key.toId();

        // Step 1: Update auction if needed (skips on quotes via tx.origin check)
        _updateAuction(poolId);

        // Step 2: Collect rent from current manager (skips on quotes via tx.origin check)
        _collectRent(poolId);

        // Step 3: Get current dynamic fee (works for both quotes and actual swaps)
        uint24 swapFee = getSwapFee(poolId, sender);

        return (
            IHooks.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            swapFee | LPFeeLibrary.OVERRIDE_FEE_FLAG
        );
    }

   
    function _afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) internal override returns (bytes4 selector_, int128 hookDeltaUnspecified_) {
        // Fees are collected by PoolManager and can be tracked here if needed
        // For now, we just return the selector
        return (IHooks.afterSwap.selector, 0);
    }

    
    function _beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) internal override returns (bytes4) {
        PoolId poolId = key.toId();
        AuctionState storage state = poolAuctions[poolId];

        // Decode actual LP address from hookData, fallback to sender if not provided
        address lp = hookData.length > 0 ? abi.decode(hookData, (address)) : sender;

        // Only charge fee if liquidity is being removed (negative delta)
        if (params.liquidityDelta < 0) {
            uint256 withdrawalAmount = uint256(-params.liquidityDelta);
            uint256 withdrawalFee = (withdrawalAmount * WITHDRAWAL_FEE) / 1000000;

            // Credit withdrawal fee to current manager (in ETH/native token)
            if (state.currentManager != address(0)) {
                managerFees[state.currentManager][poolId] += withdrawalFee;
            }

            // Claim any pending rent before shares change
            uint256 pending = getPendingRent(poolId, lp);
            if (pending > 0) {
                rentPerShareClaimed[poolId][lp] = rentPerShareAccumulated[poolId];
                payable(lp).transfer(pending);
                emit RentClaimed(poolId, lp, pending);
            }

            // Update LP shares
            lpShares[poolId][lp] -= withdrawalAmount;
            totalShares[poolId] -= withdrawalAmount;

            emit WithdrawalFeeCharged(poolId, lp, withdrawalFee);
            emit LiquidityUpdated(poolId, lp, withdrawalAmount, false);
        }

        return IHooks.beforeRemoveLiquidity.selector;
    }

   
    function _afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) internal override returns (bytes4 selector_, BalanceDelta hookDelta_) {
        PoolId poolId = key.toId();

        // Decode actual LP address from hookData, fallback to sender if not provided
        address lp = hookData.length > 0 ? abi.decode(hookData, (address)) : sender;

        // Adding liquidity - update shares (skip if lp is address(0))
        if (params.liquidityDelta > 0 && lp != address(0)) {
            uint256 addAmount = uint256(params.liquidityDelta);

            // Claim any pending rent before shares change
            uint256 pending = getPendingRent(poolId, lp);
            if (pending > 0) {
                rentPerShareClaimed[poolId][lp] = rentPerShareAccumulated[poolId];
                payable(lp).transfer(pending);
                emit RentClaimed(poolId, lp, pending);
            }

            // Update shares
            lpShares[poolId][lp] += addAmount;
            totalShares[poolId] += addAmount;

            // Set claimed to current accumulated if first deposit
            if (rentPerShareClaimed[poolId][lp] == 0) {
                rentPerShareClaimed[poolId][lp] = rentPerShareAccumulated[poolId];
            }

            emit LiquidityUpdated(poolId, lp, addAmount, true);
        }

        return (IHooks.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }

    
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

}
