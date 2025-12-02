// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IAllocationManager} from "@eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";
import {IKeyRegistrar} from "@eigenlayer-contracts/src/contracts/interfaces/IKeyRegistrar.sol";
import {IPermissionController} from "@eigenlayer-contracts/src/contracts/interfaces/IPermissionController.sol";
import {TaskAVSRegistrarBase} from "@eigenlayer-middleware/src/avs/task/TaskAVSRegistrarBase.sol";

/**
 * @title AuctionPoolTaskAVSRegistrar
 * @notice Extends TaskAVSRegistrarBase to manage auction pool operators
 * @dev Integrates with Hourglass framework for task-based operator management
 */
contract AuctionPoolTaskAVSRegistrar is TaskAVSRegistrarBase {

    // ============================================================================
    // State Variables
    // ============================================================================

    /// @notice Minimum stake required for operators (in wei)
    uint256 public minStakeAmount;

    // ============================================================================
    // Events
    // ============================================================================

    event OperatorSlashed(address indexed operator, string reason);
    event MinStakeAmountUpdated(uint256 newAmount);

    // ============================================================================
    // Constructor & Initialization
    // ============================================================================

    /**
     * @dev Constructor that passes parameters to parent TaskAVSRegistrarBase
     * @param _allocationManager The AllocationManager contract address
     * @param _keyRegistrar The KeyRegistrar contract address
     * @param _permissionController The PermissionController contract address
     */
    constructor(
        IAllocationManager _allocationManager,
        IKeyRegistrar _keyRegistrar,
        IPermissionController _permissionController
    ) TaskAVSRegistrarBase(_allocationManager, _keyRegistrar, _permissionController) {}

    /**
     * @dev Initializer that calls parent initializer
     * @param _avs The address of the AVS
     * @param _owner The owner of the contract
     * @param _initialConfig The initial AVS configuration
     * @param _minStakeAmount Minimum stake amount for operators
     */
    function initialize(
        address _avs,
        address _owner,
        AvsConfig memory _initialConfig,
        uint256 _minStakeAmount
    ) external initializer {
        __TaskAVSRegistrarBase_init(_avs, _owner, _initialConfig);
        minStakeAmount = _minStakeAmount;
    }

    // ============================================================================
    // Slashing (Simplified)
    // ============================================================================

    /**
     * @notice Slash an operator for misconduct
     * @param operator The operator to slash
     * @param reason Human-readable reason
     */
    function slashOperator(address operator, string calldata reason) external onlyOwner {
        emit OperatorSlashed(operator, reason);

        // TODO: Implement actual slashing logic via EigenLayer
        // This would typically involve calling AllocationManager to slash stake
    }

    // ============================================================================
    // Configuration
    // ============================================================================

    function setMinStakeAmount(uint256 _minStakeAmount) external onlyOwner {
        minStakeAmount = _minStakeAmount;
        emit MinStakeAmountUpdated(_minStakeAmount);
    }
}
