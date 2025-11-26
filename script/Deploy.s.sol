// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {LPFeeLibrary} from "v4-core/libraries/LPFeeLibrary.sol";

import {AuctionPoolHook} from "../src/AuctionPoolHook.sol";

/**
 * @title Deploy Script for AuctionPoolHook
 * @notice Deploys the AuctionPoolHook contract with proper address flags
 * @dev Uses CREATE2 to deploy at the correct address that matches hook flags
 */
contract DeployScript is Script {
    using CurrencyLibrary for Currency;

    // Hook flags required by AuctionPoolHook
    uint160 constant HOOK_FLAGS =
        Hooks.BEFORE_SWAP_FLAG |
        Hooks.AFTER_SWAP_FLAG |
        Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
        Hooks.AFTER_ADD_LIQUIDITY_FLAG;

    function run() public {
        // Read environment variables
        address poolManager = vm.envAddress("POOL_MANAGER");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console2.log("Deploying AuctionPoolHook...");
        console2.log("Pool Manager:", poolManager);
        console2.log("Deployer:", vm.addr(deployerPrivateKey));

        vm.startBroadcast(deployerPrivateKey);

        // Calculate the target address with correct flags
        // The hook address must have the lower bits match the hook flags
        address hookAddress = _findHookAddress(poolManager, HOOK_FLAGS);

        console2.log("Target Hook Address:", hookAddress);
        console2.log("Hook Flags:", HOOK_FLAGS);

        // Deploy the hook (you may need to use CREATE2 with a salt to hit the exact address)
        AuctionPoolHook hook = new AuctionPoolHook(poolManager);

        console2.log("Deployed AuctionPoolHook at:", address(hook));
        console2.log("");
        console2.log("Hook Configuration:");
        console2.log("  MAX_FEE:", hook.MAX_FEE(), "(1%)");
        console2.log("  ACTIVATION_DELAY:", hook.ACTIVATION_DELAY(), "blocks");
        console2.log("  WITHDRAWAL_FEE:", hook.WITHDRAWAL_FEE(), "(0.01%)");
        console2.log("  MIN_BID_INCREMENT:", hook.MIN_BID_INCREMENT(), "wei");
        console2.log("  MIN_DEPOSIT_BLOCKS:", hook.MIN_DEPOSIT_BLOCKS(), "blocks");

        // Verify the hook permissions
        Hooks.Permissions memory permissions = hook.getHookPermissions();
        console2.log("");
        console2.log("Hook Permissions:");
        console2.log("  beforeSwap:", permissions.beforeSwap);
        console2.log("  afterSwap:", permissions.afterSwap);
        console2.log("  beforeRemoveLiquidity:", permissions.beforeRemoveLiquidity);
        console2.log("  afterAddLiquidity:", permissions.afterAddLiquidity);

        vm.stopBroadcast();

        console2.log("");
        console2.log("Deployment complete!");
        console2.log("Save this address to your .env file:");
        console2.log("HOOK_ADDRESS=", address(hook));
    }

    /**
     * @notice Helper to find a valid hook address
     * @dev In production, you would use CREATE2 with different salts to find an address
     * that matches the required flags
     */
    function _findHookAddress(address poolManager, uint160 flags) internal pure returns (address) {
        // The hook address must satisfy: address & FLAGS_MASK == flags
        // This is a simplified version - in production you'd iterate through salts
        return address(flags);
    }
}

/**
 * @title Deploy and Initialize Pool Script
 * @notice Deploys AuctionPoolHook and initializes a pool with it
 */
contract DeployAndInitPoolScript is Script {
    using CurrencyLibrary for Currency;

    function run() public {
        // Read environment variables
        address poolManager = vm.envAddress("POOL_MANAGER");
        address hookAddress = vm.envAddress("HOOK_ADDRESS");
        address token0 = vm.envAddress("TOKEN0");
        address token1 = vm.envAddress("TOKEN1");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console2.log("Initializing pool with AuctionPoolHook...");
        console2.log("Pool Manager:", poolManager);
        console2.log("Hook:", hookAddress);
        console2.log("Token0:", token0);
        console2.log("Token1:", token1);

        vm.startBroadcast(deployerPrivateKey);

        IPoolManager manager = IPoolManager(poolManager);
        AuctionPoolHook hook = AuctionPoolHook(hookAddress);

        // Create pool key
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG, // Use dynamic fee
            tickSpacing: 60,
            hooks: IHooks(hookAddress)
        });

        // Initialize pool at 1:1 price (sqrtPriceX96 = sqrt(1) * 2^96)
        uint160 sqrtPriceX96 = 79228162514264337593543950336; // sqrt(1) * 2^96

        manager.initialize(key, sqrtPriceX96);

        console2.log("Pool initialized!");
        console2.log("Pool ID:", uint256(keccak256(abi.encode(key))));

        vm.stopBroadcast();
    }
}

/**
 * @title Test Bid Script
 * @notice Submits a test bid to the auction
 */
contract TestBidScript is Script {
    function run() public {
        address hookAddress = vm.envAddress("HOOK_ADDRESS");
        address token0 = vm.envAddress("TOKEN0");
        address token1 = vm.envAddress("TOKEN1");
        uint256 bidderPrivateKey = vm.envUint("PRIVATE_KEY");

        console2.log("Submitting test bid...");
        console2.log("Hook:", hookAddress);
        console2.log("Bidder:", vm.addr(bidderPrivateKey));

        vm.startBroadcast(bidderPrivateKey);

        AuctionPoolHook hook = AuctionPoolHook(hookAddress);

        // Create pool key
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 60,
            hooks: IHooks(hookAddress)
        });

        // Submit bid: 1000 wei per block
        uint256 rentPerBlock = 1000 wei;
        uint256 deposit = rentPerBlock * hook.MIN_DEPOSIT_BLOCKS();

        console2.log("Rent per block:", rentPerBlock);
        console2.log("Deposit:", deposit);

        hook.submitBid{value: deposit}(key, rentPerBlock);

        console2.log("Bid submitted successfully!");
        console2.log("Activation block:", block.number + hook.ACTIVATION_DELAY());

        vm.stopBroadcast();
    }
}
