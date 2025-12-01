// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {AuctionPoolHook} from "../src/AuctionPoolHook.sol";

/**
 * @title Salt Mining Script for AuctionPoolHook
 * @notice Finds a salt that will deploy AuctionPoolHook at an address matching the required hook flags
 * @dev Uses CREATE2 to predictably compute addresses and finds the right salt
 */
contract MineSaltScript is Script {
    // Hook flags required by AuctionPoolHook
    uint160 constant HOOK_FLAGS =
        Hooks.BEFORE_SWAP_FLAG |
        Hooks.AFTER_SWAP_FLAG |
        Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
        Hooks.AFTER_ADD_LIQUIDITY_FLAG;

    // Mask for the lower bits that must match the flags
    uint160 constant FLAGS_MASK = 0xFFFF; // Lower 16 bits

    function run() public {
        address poolManager = vm.envAddress("POOL_MANAGER_ADDRESS");
        address userDeployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        // Foundry uses CREATE2 deployer when broadcasting with {salt: salt}
        // This is the canonical CREATE2 factory address
        address create2Deployer = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

        console2.log("=== Mining Salt for AuctionPoolHook ===");
        console2.log("Pool Manager:", poolManager);
        console2.log("User Deployer:", userDeployer);
        console2.log("CREATE2 Deployer:", create2Deployer);
        console2.log("Required Flags:", HOOK_FLAGS);
        console2.log("");

        // Get the creation code
        bytes memory creationCode = abi.encodePacked(
            type(AuctionPoolHook).creationCode,
            abi.encode(poolManager)
        );
        bytes32 creationCodeHash = keccak256(creationCode);

        console2.log("Mining salt...");
        console2.log("This may take a while depending on the flags required");
        console2.log("");

        // Mine for a salt using CREATE2 deployer address
        (bytes32 salt, address hookAddress) = mineSalt(create2Deployer, creationCodeHash, HOOK_FLAGS);

        console2.log("=== FOUND VALID SALT ===");
        console2.log("Salt:", vm.toString(salt));
        console2.log("Hook Address:", hookAddress);
        console2.log("Address Flags:", uint160(hookAddress) & FLAGS_MASK);
        console2.log("Required Flags:", HOOK_FLAGS);
        console2.log("");

        // Verify the address matches
        require(
            uint160(hookAddress) & FLAGS_MASK == HOOK_FLAGS,
            "Address does not match required flags"
        );

        console2.log("=== VERIFICATION PASSED ===");
        console2.log("");
        console2.log("Save these to your .env file:");
        console2.log("HOOK_SALT=", vm.toString(salt));
        console2.log("");
        console2.log("Then run the deployment script:");
        console2.log("forge script script/Deploy.s.sol:DeployWithSaltScript --rpc-url <RPC_URL> --broadcast");
    }

    /**
     * @notice Mines for a salt that will produce an address with the correct flags
     * @param deployer The address that will deploy the contract
     * @param creationCodeHash The hash of the creation code
     * @param flags The required hook flags
     * @return salt The salt that produces a valid address
     * @return hookAddress The address that will be deployed with this salt
     */
    function mineSalt(
        address deployer,
        bytes32 creationCodeHash,
        uint160 flags
    ) internal view returns (bytes32 salt, address hookAddress) {
        uint256 attempts = 0;
        uint256 maxAttempts = 100000000; // 100M attempts max

        for (uint256 i = 0; i < maxAttempts; i++) {
            salt = bytes32(i);
            hookAddress = computeCreate2Address(deployer, salt, creationCodeHash);
            attempts++;

            // Check if the lower bits match the required flags
            if (uint160(hookAddress) & FLAGS_MASK == flags) {
                console2.log("Found valid salt after", attempts, "attempts");
                return (salt, hookAddress);
            }

            // Progress indicator every 10k attempts
            if (attempts % 10000 == 0) {
                console2.log("Attempts:", attempts);
            }
        }

        revert("Could not find valid salt within max attempts");
    }

    /**
     * @notice Computes the CREATE2 address for a given salt
     * @param deployer The deployer address
     * @param salt The salt value
     * @param creationCodeHash The hash of the creation code
     * @return The computed address
     */
    function computeCreate2Address(
        address deployer,
        bytes32 salt,
        bytes32 creationCodeHash
    ) internal pure returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            deployer,
                            salt,
                            creationCodeHash
                        )
                    )
                )
            )
        );
    }
}
