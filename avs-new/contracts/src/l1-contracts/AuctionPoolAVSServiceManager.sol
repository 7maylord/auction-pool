// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAVSDirectory} from "eigenlayer-contracts/src/contracts/interfaces/IAVSDirectory.sol";
import {ISignatureUtilsMixinTypes} from "eigenlayer-contracts/src/contracts/interfaces/ISignatureUtilsMixin.sol";

/**
 * @title AuctionPoolAVSServiceManager
 * @notice EigenLayer AVS Service Manager for AuctionPool operators
 * @dev This contract manages operator registration, task validation, and slashing
 *      Integrated with EigenLayer's AVSDirectory for proper operator management
 */
contract AuctionPoolAVSServiceManager is Ownable {

    // ============================================================================
    // State Variables
    // ============================================================================

    /// @notice EigenLayer's AVSDirectory contract
    IAVSDirectory public immutable avsDirectory;

    /// @notice Minimum stake required to register as operator (in wei)
    uint256 public minStakeAmount;

    /// @notice Minimum performance score to avoid slashing (0-10000 basis points)
    uint256 public minPerformanceScore = 7000; // 70%

    /// @notice Slashing penalty percentage (in basis points)
    uint256 public slashingPenalty = 1000; // 10%

    /// @notice Challenge period for performance disputes (in blocks)
    uint256 public challengePeriod = 7200; // ~1 day at 12s blocks

    // ============================================================================
    // Operator State
    // ============================================================================

    struct OperatorInfo {
        bool isRegistered;
        uint256 stakedAmount;
        uint256 registrationBlock;
        uint256 totalTasksCompleted;
        uint256 totalTasksFailed;
        uint256 lastPerformanceUpdate;
        bool isSlashed;
    }

    /// @notice operator address => operator info
    mapping(address => OperatorInfo) public operators;

    /// @notice List of all registered operators
    address[] public operatorList;

    // ============================================================================
    // Task Management
    // ============================================================================

    struct PoolTask {
        bytes32 poolId;
        address assignedOperator;
        uint256 startBlock;
        uint256 endBlock;
        uint256 expectedFeeOptimizations;
        uint256 actualFeeOptimizations;
        uint256 revenueGenerated;
        bool isCompleted;
        bool isValidated;
    }

    /// @notice task ID => task info
    mapping(uint256 => PoolTask) public tasks;

    /// @notice Next task ID
    uint256 public nextTaskId;

    /// @notice poolId => current operator managing the pool
    mapping(bytes32 => address) public poolOperators;

    // ============================================================================
    // Performance Tracking
    // ============================================================================

    struct PerformanceProof {
        uint256 taskId;
        uint256 timestamp;
        uint256 feeOptimizations;
        uint256 revenueGenerated;
        uint256 gasUsed;
        bytes32 proofHash;
        bool isValidated;
        address challenger;
    }

    /// @notice task ID => performance proof
    mapping(uint256 => PerformanceProof) public performanceProofs;

    // ============================================================================
    // Events
    // ============================================================================

    event OperatorRegistered(address indexed operator, uint256 stakeAmount);
    event OperatorDeregistered(address indexed operator);
    event OperatorSlashed(address indexed operator, uint256 amount, string reason);
    event TaskCreated(uint256 indexed taskId, bytes32 indexed poolId, address indexed operator);
    event TaskCompleted(uint256 indexed taskId, uint256 performanceScore);
    event PerformanceProofSubmitted(uint256 indexed taskId, address indexed operator, bytes32 proofHash);
    event PerformanceChallenged(uint256 indexed taskId, address indexed challenger);
    event StakeIncreased(address indexed operator, uint256 amount);
    event StakeWithdrawn(address indexed operator, uint256 amount);

    // ============================================================================
    // Constructor
    // ============================================================================

    /**
     * @param _avsDirectory EigenLayer's AVSDirectory contract address
     * @param _minStakeAmount Minimum stake amount for operators (in wei)
     */
    constructor(
        IAVSDirectory _avsDirectory,
        uint256 _minStakeAmount
    ) Ownable(msg.sender) {
        avsDirectory = _avsDirectory;
        minStakeAmount = _minStakeAmount;
    }

    // ============================================================================
    // Operator Management
    // ============================================================================

    /**
     * @notice Register operator to the AVS
     * @dev Operator must be registered in EigenLayer first and provide signature
     * @param operatorSignature The operator's signature with salt and expiry for EigenLayer registration
     */
    function registerOperatorToAVS(
        address operator,
        ISignatureUtilsMixinTypes.SignatureWithSaltAndExpiry memory operatorSignature
    ) external payable {
        require(!operators[operator].isRegistered, "Already registered to AVS");
        require(msg.value >= minStakeAmount, "Insufficient stake");

        // Register operator to AVS through EigenLayer's AVSDirectory
        // This will verify the operator is registered in EigenLayer's DelegationManager
        avsDirectory.registerOperatorToAVS(operator, operatorSignature);

        // Track operator in our AVS
        operators[operator] = OperatorInfo({
            isRegistered: true,
            stakedAmount: msg.value,
            registrationBlock: block.number,
            totalTasksCompleted: 0,
            totalTasksFailed: 0,
            lastPerformanceUpdate: block.number,
            isSlashed: false
        });

        operatorList.push(operator);

        emit OperatorRegistered(operator, msg.value);
    }

    /**
     * @notice Deregister operator from AVS and withdraw stake
     * @dev Must have no active tasks and no pending challenges
     */
    function deregisterOperatorFromAVS(address operator) external {
        require(msg.sender == operator || msg.sender == owner(), "Unauthorized");

        OperatorInfo storage op = operators[operator];
        require(op.isRegistered, "Not registered");
        require(!op.isSlashed, "Cannot deregister while slashed");

        // Check no active tasks
        // In production, would check task assignments

        uint256 stakeToReturn = op.stakedAmount;

        // Deregister from EigenLayer's AVSDirectory
        avsDirectory.deregisterOperatorFromAVS(operator);

        op.isRegistered = false;
        op.stakedAmount = 0;

        // Remove from operator list
        for (uint256 i = 0; i < operatorList.length; i++) {
            if (operatorList[i] == operator) {
                operatorList[i] = operatorList[operatorList.length - 1];
                operatorList.pop();
                break;
            }
        }

        (bool success, ) = operator.call{value: stakeToReturn}("");
        require(success, "Stake transfer failed");

        emit OperatorDeregistered(operator);
    }

    /**
     * @notice Increase stake
     */
    function increaseStake() external payable {
        OperatorInfo storage op = operators[msg.sender];
        require(op.isRegistered, "Not registered");
        require(msg.value > 0, "Must stake non-zero amount");

        op.stakedAmount += msg.value;

        emit StakeIncreased(msg.sender, msg.value);
    }

    // ============================================================================
    // Task Management
    // ============================================================================

    /**
     * @notice Assign operator to manage a pool (called by hook or governance)
     * @param poolId The pool to manage
     * @param operator The operator to assign
     * @param duration Duration in blocks
     */
    function assignPoolTask(
        bytes32 poolId,
        address operator,
        uint256 duration
    ) external onlyOwner returns (uint256 taskId) {
        require(operators[operator].isRegistered, "Operator not registered");
        require(!operators[operator].isSlashed, "Operator is slashed");

        taskId = nextTaskId++;

        tasks[taskId] = PoolTask({
            poolId: poolId,
            assignedOperator: operator,
            startBlock: block.number,
            endBlock: block.number + duration,
            expectedFeeOptimizations: 10, // Could be calculated based on pool
            actualFeeOptimizations: 0,
            revenueGenerated: 0,
            isCompleted: false,
            isValidated: false
        });

        poolOperators[poolId] = operator;

        emit TaskCreated(taskId, poolId, operator);
    }

    // ============================================================================
    // Performance Reporting
    // ============================================================================

    /**
     * @notice Submit performance proof for a completed task
     * @param taskId The task ID
     * @param feeOptimizations Number of fee optimizations performed
     * @param revenueGenerated Total revenue generated (in wei)
     * @param gasUsed Total gas used
     * @param proofHash Hash of off-chain proof data
     */
    function submitPerformanceProof(
        uint256 taskId,
        uint256 feeOptimizations,
        uint256 revenueGenerated,
        uint256 gasUsed,
        bytes32 proofHash
    ) external {
        PoolTask storage task = tasks[taskId];
        require(task.assignedOperator == msg.sender, "Not assigned operator");
        require(!task.isCompleted, "Task already completed");
        require(block.number >= task.endBlock, "Task not ended yet");

        task.actualFeeOptimizations = feeOptimizations;
        task.revenueGenerated = revenueGenerated;
        task.isCompleted = true;

        performanceProofs[taskId] = PerformanceProof({
            taskId: taskId,
            timestamp: block.timestamp,
            feeOptimizations: feeOptimizations,
            revenueGenerated: revenueGenerated,
            gasUsed: gasUsed,
            proofHash: proofHash,
            isValidated: false,
            challenger: address(0)
        });

        emit PerformanceProofSubmitted(taskId, msg.sender, proofHash);
    }

    /**
     * @notice Validate performance proof (called by owner or governance)
     * @param taskId The task ID
     * @param isValid Whether the proof is valid
     */
    function validatePerformanceProof(uint256 taskId, bool isValid) external onlyOwner {
        PoolTask storage task = tasks[taskId];
        PerformanceProof storage proof = performanceProofs[taskId];

        require(task.isCompleted, "Task not completed");
        require(!proof.isValidated, "Already validated");

        proof.isValidated = true;
        task.isValidated = true;

        OperatorInfo storage op = operators[task.assignedOperator];

        if (isValid) {
            op.totalTasksCompleted++;

            // Calculate performance score
            uint256 performanceScore = calculatePerformanceScore(taskId);

            emit TaskCompleted(taskId, performanceScore);

            // If performance is too low, consider slashing
            if (performanceScore < minPerformanceScore) {
                _slashOperator(task.assignedOperator, "Low performance");
            }
        } else {
            op.totalTasksFailed++;
            _slashOperator(task.assignedOperator, "Invalid proof");
        }

        op.lastPerformanceUpdate = block.number;
    }

    /**
     * @notice Challenge a performance proof
     * @param taskId The task to challenge
     */
    function challengePerformanceProof(uint256 taskId) external {
        PerformanceProof storage proof = performanceProofs[taskId];
        require(proof.timestamp > 0, "No proof submitted");
        require(!proof.isValidated, "Already validated");
        require(block.number <= proof.timestamp + challengePeriod, "Challenge period expired");

        proof.challenger = msg.sender;

        emit PerformanceChallenged(taskId, msg.sender);
    }

    // ============================================================================
    // Performance Calculation
    // ============================================================================

    /**
     * @notice Calculate performance score for a task (0-10000 basis points)
     */
    function calculatePerformanceScore(uint256 taskId) public view returns (uint256) {
        PoolTask storage task = tasks[taskId];

        if (!task.isCompleted) return 0;

        // Score based on meeting expectations
        uint256 optimizationScore = task.actualFeeOptimizations >= task.expectedFeeOptimizations
            ? 10000
            : (task.actualFeeOptimizations * 10000) / task.expectedFeeOptimizations;

        // Could add more factors: uptime, gas efficiency, revenue vs costs, etc.

        return optimizationScore;
    }

    /**
     * @notice Get operator's overall performance score
     */
    function getOperatorPerformanceScore(address operator) external view returns (uint256) {
        OperatorInfo storage op = operators[operator];

        if (op.totalTasksCompleted + op.totalTasksFailed == 0) return 0;

        return (op.totalTasksCompleted * 10000) / (op.totalTasksCompleted + op.totalTasksFailed);
    }

    // ============================================================================
    // Slashing
    // ============================================================================

    /**
     * @notice Slash an operator for misconduct
     * @param operator The operator to slash
     * @param reason Human-readable reason
     */
    function _slashOperator(address operator, string memory reason) internal {
        OperatorInfo storage op = operators[operator];

        if (op.isSlashed) return; // Already slashed

        uint256 slashAmount = (op.stakedAmount * slashingPenalty) / 10000;

        op.stakedAmount -= slashAmount;
        op.isSlashed = true;

        // In production, slashed amount would go to protocol treasury or insurance fund

        emit OperatorSlashed(operator, slashAmount, reason);
    }

    /**
     * @notice Manually slash operator (governance/owner only)
     */
    function slashOperator(address operator, string calldata reason) external onlyOwner {
        _slashOperator(operator, reason);
    }

    // ============================================================================
    // AVS Metadata
    // ============================================================================

    /**
     * @notice Update AVS metadata URI
     * @param metadataURI The URI for the AVS metadata (typically IPFS hash)
     */
    function updateAVSMetadataURI(string calldata metadataURI) external onlyOwner {
        avsDirectory.updateAVSMetadataURI(metadataURI);
    }

    // ============================================================================
    // Configuration
    // ============================================================================

    function setMinStakeAmount(uint256 _minStakeAmount) external onlyOwner {
        minStakeAmount = _minStakeAmount;
    }

    function setMinPerformanceScore(uint256 _minPerformanceScore) external onlyOwner {
        require(_minPerformanceScore <= 10000, "Invalid score");
        minPerformanceScore = _minPerformanceScore;
    }

    function setSlashingPenalty(uint256 _slashingPenalty) external onlyOwner {
        require(_slashingPenalty <= 10000, "Invalid penalty");
        slashingPenalty = _slashingPenalty;
    }

    function setChallengePeriod(uint256 _challengePeriod) external onlyOwner {
        challengePeriod = _challengePeriod;
    }

    // ============================================================================
    // View Functions
    // ============================================================================

    function getOperatorInfo(address operator) external view returns (OperatorInfo memory) {
        return operators[operator];
    }

    function getTask(uint256 taskId) external view returns (PoolTask memory) {
        return tasks[taskId];
    }

    function getPerformanceProof(uint256 taskId) external view returns (PerformanceProof memory) {
        return performanceProofs[taskId];
    }

    function getOperatorCount() external view returns (uint256) {
        return operatorList.length;
    }

    function getAllOperators() external view returns (address[] memory) {
        return operatorList;
    }

    function isOperatorRegistered(address operator) external view returns (bool) {
        return operators[operator].isRegistered;
    }
}
