// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IAVSTaskHook} from "@eigenlayer-contracts/src/contracts/interfaces/IAVSTaskHook.sol";
import {ITaskMailboxTypes} from "@eigenlayer-contracts/src/contracts/interfaces/ITaskMailbox.sol";

/**
 * @title AuctionPoolTaskHook
 * @notice Minimal task hook for AuctionPool AVS
 * @dev Operators run autonomous strategies - no complex task orchestration needed
 */
contract AuctionPoolTaskHook is IAVSTaskHook {

    /// @notice Minimum task fee (in wei)
    uint96 public minTaskFee = 0.001 ether;

    /// @notice Owner for configuration
    address public owner;

    event MinTaskFeeUpdated(uint96 newFee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    // Minimal validation - operators act autonomously
    function validatePreTaskCreation(
        address,
        ITaskMailboxTypes.TaskParams memory
    ) external pure override {
        // No validation needed - operators decide independently
    }

    function handlePostTaskCreation(bytes32) external override {
        // No-op - operators monitor pool directly
    }

    function validatePreTaskResultSubmission(
        address,
        bytes32,
        bytes memory,
        bytes memory
    ) external pure override {
        // Operators submit bids/fee updates directly to hook, not via tasks
    }

    function handlePostTaskResultSubmission(address, bytes32) external override {
        // No-op
    }

    function calculateTaskFee(
        ITaskMailboxTypes.TaskParams memory
    ) external view override returns (uint96) {
        return minTaskFee;
    }

    function setMinTaskFee(uint96 _minTaskFee) external onlyOwner {
        minTaskFee = _minTaskFee;
        emit MinTaskFeeUpdated(_minTaskFee);
    }

    function setOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid owner");
        owner = _newOwner;
    }
}
