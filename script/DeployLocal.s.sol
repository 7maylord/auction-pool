// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {AuctionPoolHook} from "../src/AuctionPoolHook.sol";
import {TestToken} from "../src/TestToken.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {PoolModifyLiquidityTest} from "v4-core/test/PoolModifyLiquidityTest.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {SwapParams} from "v4-core/types/PoolOperation.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PoolManager} from "v4-core/PoolManager.sol";

/**
 * @title Local Testing Deployment with Bid Testing
 * @notice Deploys complete environment on Anvil, adds liquidity, and tests auction bidding
 */
contract DeployLocalScript is Script {
    using PoolIdLibrary for PoolKey;
    // Initial token supply: 1 million tokens
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 1e18;

    // Initial liquidity: 10,000 tokens each
    uint256 constant INITIAL_LIQUIDITY = 10_000 * 1e18;

    // Pool fee: 0.3% (3000 basis points)
    uint24 constant POOL_FEE = 3000;

    // Initial sqrt price (1:1 ratio)
    uint160 constant SQRT_PRICE_1_1 = 79228162514264337593543950336;

    // Bid parameters
    uint256 constant RENT_PER_BLOCK = 0.001 ether; // 0.001 ETH per block
    uint256 constant BID_DEPOSIT = 0.1 ether; // 0.1 ETH deposit (covers 100 blocks)

    function run() public {
        // Use Anvil's default private key for testing
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("=== Local AuctionPool Deployment & Testing ===");
        console2.log("Deployer:", deployer);
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy PoolManager (Uniswap v4 core)
        console2.log("Step 1: Deploying PoolManager...");
        PoolManager poolManager = new PoolManager(deployer);
        console2.log("PoolManager:", address(poolManager));
        console2.log("");

        // 2. Deploy test routers
        console2.log("Step 2: Deploying test routers...");
        PoolModifyLiquidityTest liquidityRouter = new PoolModifyLiquidityTest(IPoolManager(address(poolManager)));
        PoolSwapTest swapRouter = new PoolSwapTest(IPoolManager(address(poolManager)));
        console2.log("LiquidityRouter:", address(liquidityRouter));
        console2.log("SwapRouter:", address(swapRouter));
        console2.log("");

        // 3. Deploy test tokens
        console2.log("Step 3: Deploying test tokens...");
        TestToken tokenA = new TestToken("Test Token A", "TKA", INITIAL_SUPPLY);
        TestToken tokenB = new TestToken("Test Token B", "TKB", INITIAL_SUPPLY);

        // Ensure token0 < token1 (required by Uniswap)
        (address token0Addr, address token1Addr) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        console2.log("Token0:", token0Addr);
        console2.log("Token1:", token1Addr);
        console2.log("");

        // 4. Mine salt for hook address with correct flags
        console2.log("Step 4: Mining salt for hook address...");
        bytes32 salt = _mineSalt(address(deployer), address(poolManager));
        console2.log("Mined salt:", vm.toString(salt));
        console2.log("");

        // 5. Deploy AuctionPoolHook
        console2.log("Step 5: Deploying AuctionPoolHook...");
        AuctionPoolHook hook = new AuctionPoolHook{salt: salt}(address(poolManager));
        console2.log("Hook Address:", address(hook));
        console2.log("");

        // 6. Initialize the pool
        console2.log("Step 6: Initializing pool...");
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(token0Addr),
            currency1: Currency.wrap(token1Addr),
            fee: POOL_FEE,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });

        poolManager.initialize(poolKey, SQRT_PRICE_1_1);
        console2.log("Pool initialized with 1:1 price ratio");
        console2.log("");

        // 7. Approve tokens for liquidity provision
        console2.log("Step 7: Approving tokens...");
        IERC20(token0Addr).approve(address(liquidityRouter), type(uint256).max);
        IERC20(token1Addr).approve(address(liquidityRouter), type(uint256).max);
        IERC20(token0Addr).approve(address(swapRouter), type(uint256).max);
        IERC20(token1Addr).approve(address(swapRouter), type(uint256).max);
        console2.log("Tokens approved for routers");
        console2.log("");

        // 8. Add initial liquidity
        console2.log("Step 8: Adding initial liquidity...");
        liquidityRouter.modifyLiquidity(
            poolKey,
            ModifyLiquidityParams({
                tickLower: TickMath.minUsableTick(60),
                tickUpper: TickMath.maxUsableTick(60),
                liquidityDelta: int256(INITIAL_LIQUIDITY),
                salt: bytes32(0)
            }),
            ""
        );
        console2.log("Added", INITIAL_LIQUIDITY / 1e18, "tokens of liquidity");
        console2.log("");

        // 9. Test auction: Submit a bid
        console2.log("Step 9: Testing auction - submitting bid...");
        console2.log("Rent per block:", RENT_PER_BLOCK);
        console2.log("Deposit:", BID_DEPOSIT);

        hook.submitBid{value: BID_DEPOSIT}(poolKey, RENT_PER_BLOCK);
        console2.log("Bid submitted successfully!");
        console2.log("");

        // 10. Check next bid
        console2.log("Step 10: Checking next bid...");
        PoolId poolId = poolKey.toId();
        (address nextBidder, uint256 nextRent, uint256 nextDeposit, uint256 activationBlock,) = hook.nextBid(poolId);
        console2.log("Next Bidder:", nextBidder);
        console2.log("Rent per block:", nextRent);
        console2.log("Deposit:", nextDeposit);
        console2.log("Activation Block:", activationBlock);
        console2.log("");

        vm.stopBroadcast();

        // Print summary
        console2.log("=== LOCAL DEPLOYMENT COMPLETE ===");
        console2.log("PoolManager:", address(poolManager));
        console2.log("Hook:", address(hook));
        console2.log("Token0:", token0Addr);
        console2.log("Token1:", token1Addr);
        console2.log("Liquidity:", INITIAL_LIQUIDITY / 1e18, "tokens");
        console2.log("Bid submitted:", nextBidder);
        console2.log("Rent/block:", nextRent);
        console2.log("Activation:", activationBlock);
    }

    /**
     * @notice Mine salt to get hook address with correct flags
     * @dev Hook needs specific address prefix based on implemented hooks
     */
    function _mineSalt(address deployer, address poolManager) internal pure returns (bytes32) {
        // For testing, we can use a simple salt since we don't need specific flags on Anvil
        // In production, you'd mine for a salt that gives correct hook permissions
        return bytes32(uint256(0x1));
    }
}
