// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {AuctionPoolAVSServiceManager} from "../AuctionPoolAVSServiceManager.sol";
import {IAVSDirectory} from "eigenlayer-contracts/src/contracts/interfaces/IAVSDirectory.sol";

/**
 * @title DeployAVSScript
 * @notice Deployment script for AuctionPoolAVSServiceManager on Sepolia
 *
 * Sepolia EigenLayer contracts:
 * - AVSDirectory: 0xa789c91ECDdae96865913130B786140Ee17aF545
 * - DelegationManager: 0xD4A7E1Bd8015057293f0D0A557088c286942e84b
 * - Chain ID: 11155111
 *
 * Usage:
 *   source ../.env
 *   forge script --root /Users/macbook/Programming/uniswap/auction-pool/avs \
 *     script/DeployAVS.s.sol:DeployAVSScript \
 *     --rpc-url $RPC_URL \
 *     --broadcast \
 *     --verify \
 *     -vvvv
 */
contract DeployAVSScript is Script {
    // Sepolia EigenLayer AVSDirectory
    address constant AVS_DIRECTORY = 0xa789c91ECDdae96865913130B786140Ee17aF545;

    function run() external {
        // Load deployer from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Load configuration
        uint256 minStakeWei = vm.envOr("MIN_STAKE_AMOUNT_ETH", uint256(10000000000000000)); // 0.01 ETH default

        console2.log("=== Deploying AuctionPool AVS ===");
        console2.log("Deployer:", deployer);
        console2.log("EigenLayer AVSDirectory:", AVS_DIRECTORY);
        console2.log("Min Stake:", minStakeWei);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy AVS Service Manager
        AuctionPoolAVSServiceManager avsManager = new AuctionPoolAVSServiceManager(
            IAVSDirectory(AVS_DIRECTORY),
            minStakeWei
        );

        vm.stopBroadcast();

        console2.log("\n=== Deployment Complete ===");
        console2.log("AuctionPoolAVSServiceManager deployed at:", address(avsManager));
        console2.log("AVSDirectory:", AVS_DIRECTORY);
        console2.log("\nVerify with:");
        console2.log("forge verify-contract", address(avsManager), "AuctionPoolAVSServiceManager --chain sepolia");
    }
}
