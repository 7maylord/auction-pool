// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {SwapParams} from "v4-core/types/PoolOperation.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Trigger Swap to Activate Auction
 * @notice Makes a small swap to trigger the auction manager update
 */
contract TriggerSwapScript is Script {
    function run() public {
        // Load from env
        address poolManager = vm.envAddress("POOL_MANAGER_ADDRESS");
        address hook = vm.envAddress("HOOK_ADDRESS");
        address token0 = vm.envAddress("TOKEN0");
        address token1 = vm.envAddress("TOKEN1");
        address swapRouter = 0x9B6b46e2c869aa39918Db7f52f5557FE577B6eEe; // PoolSwapTest on Sepolia
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        console2.log("=== Triggering Swap to Activate Auction ===");
        console2.log("Hook:", hook);
        console2.log("SwapRouter:", swapRouter);
        console2.log("");

        vm.startBroadcast(privateKey);

        // Create pool key
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hook)
        });

        // Approve tokens for swap router
        IERC20(token0).approve(swapRouter, type(uint256).max);
        IERC20(token1).approve(swapRouter, type(uint256).max);

        // Create swap params - swap 0.001 tokens
        // Use positive amount for exact input (selling tokens)
        SwapParams memory params = SwapParams({
            zeroForOne: true,  // Swap token0 for token1
            amountSpecified: -1000000000000000, // Negative = exact output (0.001 tokens)
            sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1 // Price limit for zeroForOne
        });

        console2.log("Executing swap...");
        console2.log("Amount: 0.001 tokens");

        // Execute swap - PoolSwapTest.swap takes 4 parameters
        PoolSwapTest(swapRouter).swap(poolKey, params, PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}), "");

        console2.log("Swap completed! Auction should now be updated.");

        vm.stopBroadcast();
    }
}
