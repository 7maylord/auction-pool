// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {AuctionPoolTaskAVSRegistrar} from "../src/l1-contracts/AuctionPoolTaskAVSRegistrar.sol";
import {AuctionPoolTaskHook} from "../src/l2-contracts/AuctionPoolTaskHook.sol";
import {IAllocationManager} from "@eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";
import {IKeyRegistrar} from "@eigenlayer-contracts/src/contracts/interfaces/IKeyRegistrar.sol";
import {IPermissionController} from "@eigenlayer-contracts/src/contracts/interfaces/IPermissionController.sol";

/**
 * @title Deploy AuctionPool AVS
 * @notice Deploys AuctionPool AVS contracts to Sepolia testnet
 */
contract DeployAVSScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("=== Deploying AuctionPool AVS to Sepolia ===");
        console2.log("Deployer:", deployer);
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Task Hook (L2/Sepolia)
        console2.log("Deploying AuctionPoolTaskHook...");
        AuctionPoolTaskHook taskHook = new AuctionPoolTaskHook(deployer);
        console2.log("  TaskHook:", address(taskHook));
        console2.log("");

        // Note: AVS Registrar deployment requires EigenLayer core contracts
        // For hackathon demo, we can skip full registrar deployment
        // and focus on the task hook + operator logic

        console2.log("=== DEPLOYMENT COMPLETE ===");
        console2.log("");
        console2.log("Next steps:");
        console2.log("1. Configure operators to monitor AuctionPoolHook");
        console2.log("2. Operators bid autonomously based on profitability");
        console2.log("3. TaskHook validates operator registration");

        vm.stopBroadcast();
    }
}
