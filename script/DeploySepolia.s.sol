// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {AuctionPoolHook} from "../src/AuctionPoolHook.sol";
import {TestToken} from "../src/TestToken.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {PoolModifyLiquidityTest} from "v4-core/test/PoolModifyLiquidityTest.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Complete Sepolia Deployment
 * @notice Deploys test tokens, hook, initializes pool, and adds liquidity
 */
contract DeploySepoliaScript is Script {
    // Initial token supply: 1 million tokens
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 1e18;

    // Initial liquidity: 10,000 tokens each
    uint256 constant INITIAL_LIQUIDITY = 10_000 * 1e18;

    // Pool fee: 0.3% (3000 basis points)
    uint24 constant POOL_FEE = 3000;

    // Initial sqrt price (1:1 ratio)
    uint160 constant SQRT_PRICE_1_1 = 79228162514264337593543950336;

    function run() public {
        // Load config from .env
        address poolManager = vm.envAddress("POOL_MANAGER_ADDRESS");
        address positionManager = vm.envAddress("POSITION_MANAGER");
        address modifyLiquidityRouter = vm.envAddress("POOL_MODIFY_LIQUIDITY_TEST");
        bytes32 salt = vm.envBytes32("HOOK_SALT");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("=== Complete AuctionPool Deployment to Sepolia ===");
        console2.log("Pool Manager:", poolManager);
        console2.log("Position Manager:", positionManager);
        console2.log("Modify Liquidity Router:", modifyLiquidityRouter);
        console2.log("Salt:", vm.toString(salt));
        console2.log("Deployer:", deployer);
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy test tokens
        console2.log("Step 1: Deploying test tokens...");
        TestToken tokenA = new TestToken("Test Token A", "TKA", INITIAL_SUPPLY);
        TestToken tokenB = new TestToken("Test Token B", "TKB", INITIAL_SUPPLY);

        // Ensure token0 < token1 (required by Uniswap)
        (address token0Addr, address token1Addr) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));

        console2.log("Token0:", token0Addr);
        console2.log("Token1:", token1Addr);
        console2.log("");

        // 2. Deploy AuctionPoolHook
        console2.log("Step 2: Deploying AuctionPoolHook...");
        AuctionPoolHook hook = new AuctionPoolHook{salt: salt}(
            poolManager
        );
        console2.log("Hook Address:", address(hook));
        console2.log("");

        // 3. Initialize the pool
        console2.log("Step 3: Initializing pool...");
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(token0Addr),
            currency1: Currency.wrap(token1Addr),
            fee: POOL_FEE,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });

        // Initialize pool with 1:1 price ratio
        IPoolManager(poolManager).initialize(poolKey, SQRT_PRICE_1_1);
        console2.log("Pool initialized with 1:1 price ratio");
        console2.log("");

        // 4. Approve tokens for liquidity provision
        console2.log("Step 4: Approving tokens...");
        IERC20(token0Addr).approve(modifyLiquidityRouter, type(uint256).max);
        IERC20(token1Addr).approve(modifyLiquidityRouter, type(uint256).max);
        console2.log("Tokens approved for liquidity router");
        console2.log("");

        // 5. Add initial liquidity
        console2.log("Step 5: Adding initial liquidity...");
        PoolModifyLiquidityTest liquidityRouter = PoolModifyLiquidityTest(modifyLiquidityRouter);

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

        vm.stopBroadcast();

        // Print summary
        console2.log("=== DEPLOYMENT COMPLETE ===");
        console2.log("");
        console2.log("Deployed Contracts:");
        console2.log("-------------------");
        console2.log("Token0 (TKA/TKB):", token0Addr);
        console2.log("Token1 (TKA/TKB):", token1Addr);
        console2.log("AuctionPoolHook:", address(hook));
        console2.log("");
        console2.log("Pool Details:");
        console2.log("-------------");
        console2.log("Fee:", POOL_FEE / 10000, "%");
        console2.log("Initial Liquidity:", INITIAL_LIQUIDITY / 1e18, "tokens each");
        console2.log("Price Ratio: 1:1");
        console2.log("");
        console2.log("Update your .env file:");
        console2.log("----------------------");
        console2.log("HOOK_ADDRESS=", vm.toString(address(hook)));
        console2.log("TOKEN0=", token0Addr);
        console2.log("TOKEN1=", token1Addr);
        console2.log("");
        console2.log("Next Steps:");
        console2.log("-----------");
        console2.log("1. Deploy AVS contracts");
        console2.log("2. Run operator with hook address:", address(hook));
        console2.log("3. Test auction by submitting bids");
    }
}
