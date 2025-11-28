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
 * @title Deploy Script for AuctionPoolHook (Simple)
 * @notice Deploys the AuctionPoolHook contract without CREATE2 (for testing)
 * @dev This will NOT produce an address with matching flags - use DeployWithSaltScript for production
 */
contract DeployScript is Script {
    using CurrencyLibrary for Currency;

    function run() public {
        // Read environment variables
        address poolManager = vm.envAddress("POOL_MANAGER");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console2.log("Deploying AuctionPoolHook (Simple)...");
        console2.log("WARNING: This deployment does NOT use CREATE2");
        console2.log("The hook address may not match required flags");
        console2.log("For production, use DeployWithSaltScript");
        console2.log("");
        console2.log("Pool Manager:", poolManager);
        console2.log("Deployer:", vm.addr(deployerPrivateKey));

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the hook
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
}

/**
 * @title Deploy With Salt Script for AuctionPoolHook
 * @notice Deploys the AuctionPoolHook using CREATE2 with a pre-mined salt
 * @dev Run MineSalt.s.sol first to find the salt, then use it here
 */
contract DeployWithSaltScript is Script {
    using CurrencyLibrary for Currency;

    // Hook flags required by AuctionPoolHook
    uint160 constant HOOK_FLAGS =
        Hooks.BEFORE_SWAP_FLAG |
        Hooks.AFTER_SWAP_FLAG |
        Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
        Hooks.AFTER_ADD_LIQUIDITY_FLAG;

    uint160 constant FLAGS_MASK = 0xFFFF;

    function run() public {
        // Read environment variables
        address poolManager = vm.envAddress("POOL_MANAGER");
        bytes32 salt = vm.envBytes32("HOOK_SALT");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console2.log("=== Deploying AuctionPoolHook with CREATE2 ===");
        console2.log("Pool Manager:", poolManager);
        console2.log("Salt:", vm.toString(salt));
        console2.log("Deployer:", vm.addr(deployerPrivateKey));
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy using CREATE2 with the salt
        AuctionPoolHook hook = new AuctionPoolHook{salt: salt}(poolManager);

        console2.log("Deployed AuctionPoolHook at:", address(hook));

        // Verify the address has correct flags
        uint160 addressFlags = uint160(address(hook)) & FLAGS_MASK;
        console2.log("Address Flags:", addressFlags);
        console2.log("Required Flags:", HOOK_FLAGS);

        require(
            addressFlags == HOOK_FLAGS,
            "Deployed address does not match required flags!"
        );

        console2.log("[OK] Address flags verified!");
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
        console2.log("=== Deployment Complete ===");
        console2.log("HOOK_ADDRESS=", address(hook));
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
