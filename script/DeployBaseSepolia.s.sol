// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {AuctionPoolHook} from "../src/AuctionPoolHook.sol";
import {AuctionPoolAVSServiceManager} from "../src/AuctionPoolAVSServiceManager.sol";
import {TestToken} from "../src/TestToken.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";

/**
 * @title DeployBaseSepoliaScript
 * @notice Deployment script for Base Sepolia testnet
 *
 * Base Sepolia has official Uniswap v4 deployment:
 * - PoolManager: 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408
 * - Chain ID: 84532
 *
 * Usage:
 *   source .env.base-sepolia
 *   forge script script/DeployBaseSepolia.s.sol:DeployBaseSepoliaScript \
 *     --rpc-url $RPC_URL \
 *     --broadcast \
 *     --verify \
 *     -vvvv
 */
contract DeployBaseSepoliaScript is Script {
    // Hook flags - must match deployed hook address
    uint160 constant HOOK_FLAGS =
        Hooks.BEFORE_SWAP_FLAG |
        Hooks.AFTER_SWAP_FLAG |
        Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
        Hooks.AFTER_ADD_LIQUIDITY_FLAG;

    uint160 constant FLAGS_MASK = 0xFFFF;

    // Base Sepolia Uniswap v4 PoolManager
    address constant POOL_MANAGER = 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408;

    function run() public {
        // Load configuration
        bytes32 salt = vm.envOr("HOOK_SALT", bytes32(0));
        uint256 minStakeEth = vm.envOr("MIN_STAKE_AMOUNT_ETH", uint256(1));
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("================================================================================");
        console2.log("Deploying to Base Sepolia");
        console2.log("================================================================================");
        console2.log("Network: Base Sepolia");
        console2.log("Chain ID: 84532");
        console2.log("RPC: https://sepolia.base.org");
        console2.log("Explorer: https://sepolia.basescan.org");
        console2.log("");
        console2.log("Deployer:", deployer);
        console2.log("Pool Manager:", POOL_MANAGER);
        console2.log("Min Stake:", minStakeEth, "ETH");
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        // =============================================================================
        // Step 1: Deploy AuctionPoolHook with CREATE2
        // =============================================================================

        console2.log("Step 1: Deploying AuctionPoolHook...");
        console2.log("--------------------------------------------------------------------------------");

        AuctionPoolHook hook;

        if (salt == bytes32(0)) {
            console2.log("WARNING: No HOOK_SALT provided!");
            console2.log("Deploying without CREATE2 - hook address will NOT match required flags.");
            console2.log("");
            console2.log("To fix:");
            console2.log("1. Run: forge script script/MineSalt.s.sol --rpc-url $RPC_URL");
            console2.log("2. Copy HOOK_SALT to .env.base-sepolia");
            console2.log("3. Re-run this script");
            console2.log("");

            hook = new AuctionPoolHook(IPoolManager(POOL_MANAGER));

            console2.log("[WARN] Hook deployed WITHOUT proper address!");
        } else {
            console2.log("Using CREATE2 salt:", vm.toString(salt));
            hook = new AuctionPoolHook{salt: salt}(IPoolManager(POOL_MANAGER));

            // Verify flags
            uint160 addressFlags = uint160(address(hook)) & FLAGS_MASK;
            require(
                addressFlags == HOOK_FLAGS,
                "Hook address flags mismatch!"
            );
            console2.log("[OK] Hook address flags verified!");
        }

        console2.log("AuctionPoolHook deployed at:", address(hook));
        console2.log("Address flags (lower 16 bits):", uint160(address(hook)) & FLAGS_MASK);
        console2.log("Required flags:", HOOK_FLAGS);
        console2.log("");

        // =============================================================================
        // Step 2: Deploy AuctionPoolAVSServiceManager
        // =============================================================================

        console2.log("Step 2: Deploying AuctionPoolAVSServiceManager...");
        console2.log("--------------------------------------------------------------------------------");

        uint256 minStakeWei = minStakeEth * 1 ether;
        AuctionPoolAVSServiceManager avsManager = new AuctionPoolAVSServiceManager(
            minStakeWei
        );

        console2.log("AuctionPoolAVSServiceManager deployed at:", address(avsManager));
        console2.log("Min stake requirement:", minStakeWei, "wei (", minStakeEth, "ETH)");
        console2.log("");

        // =============================================================================
        // Step 3: Deploy Test Tokens
        // =============================================================================

        console2.log("Step 3: Deploying Test Tokens...");
        console2.log("--------------------------------------------------------------------------------");

        // Deploy two test tokens with 1M supply each
        uint256 initialSupply = 1_000_000 * 1e18;

        TestToken tokenA = new TestToken("Test Token A", "TKA", initialSupply);
        TestToken tokenB = new TestToken("Test Token B", "TKB", initialSupply);

        // Sort tokens by address (lower address = token0)
        address token0Addr = address(tokenA) < address(tokenB) ? address(tokenA) : address(tokenB);
        address token1Addr = address(tokenA) < address(tokenB) ? address(tokenB) : address(tokenA);

        console2.log("Token A deployed:", address(tokenA));
        console2.log("Token B deployed:", address(tokenB));
        console2.log("");
        console2.log("Sorted for pool:");
        console2.log("  Token0 (lower):", token0Addr);
        console2.log("  Token1 (higher):", token1Addr);
        console2.log("  Initial supply:", initialSupply / 1e18, "tokens each");
        console2.log("");

        // =============================================================================
        // Step 4: Initialize Pool
        // =============================================================================

        console2.log("Step 4: Initializing Pool...");
        console2.log("--------------------------------------------------------------------------------");

        // Create pool key
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(token0Addr),
            currency1: Currency.wrap(token1Addr),
            fee: 3000, // 0.3% (ignored, hook controls fees)
            tickSpacing: 60,
            hooks: hook
        });

        // Calculate pool ID
        PoolId poolId = PoolIdLibrary.toId(poolKey);

        console2.log("Pool configuration:");
        console2.log("  Currency0:", Currency.unwrap(poolKey.currency0));
        console2.log("  Currency1:", Currency.unwrap(poolKey.currency1));
        console2.log("  Fee tier: 3000 (0.3%, ignored by hook)");
        console2.log("  Tick spacing: 60");
        console2.log("  Hook:", address(poolKey.hooks));
        console2.log("");

        // Initialize pool at 1:1 price (sqrtPriceX96)
        uint160 sqrtPriceX96 = 79228162514264337593543950336; // sqrt(1) << 96

        try IPoolManager(POOL_MANAGER).initialize(poolKey, sqrtPriceX96, "") {
            console2.log("[OK] Pool initialized successfully!");
            console2.log("Pool ID:", PoolId.unwrap(poolId));
            console2.log("Initial price: 1:1");
        } catch Error(string memory reason) {
            console2.log("[WARN] Pool initialization failed:", reason);
            console2.log("You may need to initialize manually");
        } catch {
            console2.log("[WARN] Pool initialization failed (unknown reason)");
            console2.log("You may need to initialize manually");
        }

        console2.log("");

        // =============================================================================
        // Step 5: Display Configuration
        // =============================================================================

        console2.log("Step 5: Deployment Summary");
        console2.log("================================================================================");
        console2.log("");
        console2.log("Network Information:");
        console2.log("  Network: Base Sepolia");
        console2.log("  Chain ID: 84532");
        console2.log("  Block Number:", block.number);
        console2.log("  Block Timestamp:", block.timestamp);
        console2.log("");

        console2.log("Deployed Contracts:");
        console2.log("  AuctionPoolHook:", address(hook));
        console2.log("  AVS Service Manager:", address(avsManager));
        console2.log("  Test Token A:", address(tokenA));
        console2.log("  Test Token B:", address(tokenB));
        console2.log("");

        console2.log("Test Pool:");
        console2.log("  Pool ID:", PoolId.unwrap(poolId));
        console2.log("  Token0:", token0Addr);
        console2.log("  Token1:", token1Addr);
        console2.log("  Tick Spacing: 60");
        console2.log("");

        console2.log("Uniswap v4 Infrastructure:");
        console2.log("  Pool Manager:", POOL_MANAGER);
        console2.log("  Position Manager: 0x4b2c77d209d3405f41a037ec6c77f7f5b8e2ca80");
        console2.log("  Universal Router: 0x492e6456d9528771018deb9e87ef7750ef184104");
        console2.log("");

        console2.log("Hook Configuration:");
        console2.log("  MIN_DEPOSIT_BLOCKS:", hook.MIN_DEPOSIT_BLOCKS());
        console2.log("  ACTIVATION_DELAY:", hook.ACTIVATION_DELAY(), "blocks");
        console2.log("  MIN_BID_INCREMENT:", hook.MIN_BID_INCREMENT(), "wei");
        console2.log("  MAX_SWAP_FEE:", hook.MAX_SWAP_FEE(), "(1%)");
        console2.log("  WITHDRAWAL_FEE:", hook.WITHDRAWAL_FEE(), "(0.01%)");
        console2.log("");

        console2.log("AVS Configuration:");
        console2.log("  Min Stake:", avsManager.minStakeAmount() / 1e18, "ETH");
        console2.log("  Min Performance Score:", avsManager.minPerformanceScore() / 100, "%");
        console2.log("  Slashing Penalty:", avsManager.slashingPenalty() / 100, "%");
        console2.log("  Challenge Period:", avsManager.challengePeriod(), "blocks (~1 day)");
        console2.log("");

        // =============================================================================
        // Step 6: Save Deployment Info
        // =============================================================================

        console2.log("Step 6: Saving deployment addresses...");
        console2.log("--------------------------------------------------------------------------------");

        string memory deploymentInfo = string.concat(
            "# Base Sepolia Deployment\n",
            "# Deployed at block ", vm.toString(block.number), "\n",
            "# Timestamp: ", vm.toString(block.timestamp), "\n\n",
            "BASE_SEPOLIA_HOOK_ADDRESS=", vm.toString(address(hook)), "\n",
            "BASE_SEPOLIA_AVS_MANAGER_ADDRESS=", vm.toString(address(avsManager)), "\n",
            "BASE_SEPOLIA_POOL_MANAGER=", vm.toString(POOL_MANAGER), "\n",
            "BASE_SEPOLIA_TOKEN_A=", vm.toString(address(tokenA)), "\n",
            "BASE_SEPOLIA_TOKEN_B=", vm.toString(address(tokenB)), "\n",
            "BASE_SEPOLIA_TOKEN0=", vm.toString(token0Addr), "\n",
            "BASE_SEPOLIA_TOKEN1=", vm.toString(token1Addr), "\n",
            "BASE_SEPOLIA_POOL_ID=", vm.toString(PoolId.unwrap(poolId)), "\n",
            "DEPLOYMENT_BLOCK=", vm.toString(block.number), "\n",
            "DEPLOYMENT_TIMESTAMP=", vm.toString(block.timestamp), "\n"
        );

        vm.writeFile(".env.base-sepolia.deployed", deploymentInfo);
        console2.log("[OK] Deployment info saved to .env.base-sepolia.deployed");
        console2.log("");

        // =============================================================================
        // Step 7: Next Steps
        // =============================================================================

        console2.log("================================================================================");
        console2.log("Deployment Complete!");
        console2.log("================================================================================");
        console2.log("");
        console2.log("View on BaseScan:");
        console2.log("  Hook:    https://sepolia.basescan.org/address/", vm.toString(address(hook)));
        console2.log("  AVS:     https://sepolia.basescan.org/address/", vm.toString(address(avsManager)));
        console2.log("  Token A: https://sepolia.basescan.org/address/", vm.toString(address(tokenA)));
        console2.log("  Token B: https://sepolia.basescan.org/address/", vm.toString(address(tokenB)));
        console2.log("");
        console2.log("Pool Details:");
        console2.log("  Pool ID:", PoolId.unwrap(poolId));
        console2.log("  Token0:", token0Addr);
        console2.log("  Token1:", token1Addr);
        console2.log("  Price: 1:1");
        console2.log("");
        console2.log("Next Steps:");
        console2.log("");
        console2.log("1. Verify contracts (if not auto-verified):");
        console2.log("   forge verify-contract", address(hook), "AuctionPoolHook \\");
        console2.log("     --chain-id 84532 \\");
        console2.log("     --watch \\");
        console2.log("     --constructor-args $(cast abi-encode 'constructor(address)' ", POOL_MANAGER, ")");
        console2.log("");
        console2.log("2. Configure operator node:");
        console2.log("   cd operator");
        console2.log("   cat > .env << EOF");
        console2.log("   RPC_URL=https://sepolia.base.org");
        console2.log("   CHAIN_ID=84532");
        console2.log("   POOL_MANAGER_ADDRESS=", POOL_MANAGER);
        console2.log("   HOOK_ADDRESS=", address(hook));
        console2.log("   AVS_SERVICE_MANAGER_ADDRESS=", address(avsManager));
        console2.log("   OPERATOR_PRIVATE_KEY=0x...");
        console2.log("   EOF");
        console2.log("");
        console2.log("3. Start operator:");
        console2.log("   npm install && npm start");
        console2.log("");
        console2.log("4. Submit first bid:");
        console2.log("   Pool is ready! You can now:");
        console2.log("   - Register as operator (via operator node)");
        console2.log("   - Submit bids to manage the pool");
        console2.log("   - Optimize fees dynamically");
        console2.log("");
        console2.log("   Use this pool ID for bids:");
        console2.log("   POOL_ID=", PoolId.unwrap(poolId));
        console2.log("");

        vm.stopBroadcast();

        console2.log("================================================================================");
        console2.log("All done! Ready to test on Base Sepolia.");
        console2.log("================================================================================");
    }
}
