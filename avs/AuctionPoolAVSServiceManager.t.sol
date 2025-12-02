// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {AuctionPoolAVSServiceManager} from "../src/AuctionPoolAVSServiceManager.sol";

contract AuctionPoolAVSServiceManagerTest is Test {
    AuctionPoolAVSServiceManager public avsManager;

    address public owner;
    address public alice;
    address public bob;
    address public charlie;

    uint256 public constant MIN_STAKE = 1 ether;
    bytes32 public constant POOL_ID_1 = keccak256("pool1");
    bytes32 public constant POOL_ID_2 = keccak256("pool2");

    event OperatorRegistered(address indexed operator, uint256 stakeAmount);
    event OperatorDeregistered(address indexed operator);
    event OperatorSlashed(address indexed operator, uint256 amount, string reason);
    event TaskCreated(uint256 indexed taskId, bytes32 indexed poolId, address indexed operator);
    event TaskCompleted(uint256 indexed taskId, uint256 performanceScore);
    event PerformanceProofSubmitted(uint256 indexed taskId, address indexed operator, bytes32 proofHash);
    event PerformanceChallenged(uint256 indexed taskId, address indexed challenger);
    event StakeIncreased(address indexed operator, uint256 amount);
    event StakeWithdrawn(address indexed operator, uint256 amount);

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);

        vm.prank(owner);
        avsManager = new AuctionPoolAVSServiceManager(MIN_STAKE);
    }

    // ============================================================================
    // Operator Registration Tests
    // ============================================================================

    function testRegisterOperator() public {
        vm.expectEmit(true, false, false, true);
        emit OperatorRegistered(alice, MIN_STAKE);

        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        // Check operator info
        (
            bool isRegistered,
            uint256 stakedAmount,
            uint256 registrationBlock,
            uint256 totalTasksCompleted,
            uint256 totalTasksFailed,
            uint256 lastPerformanceUpdate,
            bool isSlashed
        ) = avsManager.operators(alice);

        assertTrue(isRegistered);
        assertEq(stakedAmount, MIN_STAKE);
        assertEq(registrationBlock, block.number);
        assertEq(totalTasksCompleted, 0);
        assertEq(totalTasksFailed, 0);
        assertEq(lastPerformanceUpdate, block.number);
        assertFalse(isSlashed);

        // Check operator list
        assertEq(avsManager.getOperatorCount(), 1);
        assertTrue(avsManager.isOperatorRegistered(alice));
    }

    function testRegisterOperatorWithExtraStake() public {
        uint256 extraStake = 5 ether;

        vm.prank(alice);
        avsManager.registerOperator{value: extraStake}();

        (, uint256 stakedAmount, , , , , ) = avsManager.operators(alice);
        assertEq(stakedAmount, extraStake);
    }

    function testRegisterOperatorRevertInsufficientStake() public {
        vm.prank(alice);
        vm.expectRevert("Insufficient stake");
        avsManager.registerOperator{value: MIN_STAKE - 1}();
    }

    function testRegisterOperatorRevertAlreadyRegistered() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(alice);
        vm.expectRevert("Already registered");
        avsManager.registerOperator{value: MIN_STAKE}();
    }

    function testMultipleOperatorsRegister() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(bob);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(charlie);
        avsManager.registerOperator{value: MIN_STAKE}();

        assertEq(avsManager.getOperatorCount(), 3);

        address[] memory operators = avsManager.getAllOperators();
        assertEq(operators.length, 3);
    }

    // ============================================================================
    // Operator Deregistration Tests
    // ============================================================================

    function testDeregisterOperator() public {
        // Register first
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        uint256 balanceBefore = alice.balance;

        // Deregister
        vm.expectEmit(true, false, false, false);
        emit OperatorDeregistered(alice);

        vm.prank(alice);
        avsManager.deregisterOperator();

        // Check operator is deregistered
        (bool isRegistered, uint256 stakedAmount, , , , , ) = avsManager.operators(alice);
        assertFalse(isRegistered);
        assertEq(stakedAmount, 0);

        // Check stake was returned
        assertEq(alice.balance, balanceBefore + MIN_STAKE);

        // Check operator list
        assertEq(avsManager.getOperatorCount(), 0);
        assertFalse(avsManager.isOperatorRegistered(alice));
    }

    function testDeregisterOperatorRevertNotRegistered() public {
        vm.prank(alice);
        vm.expectRevert("Not registered");
        avsManager.deregisterOperator();
    }

    function testDeregisterOperatorRevertWhenSlashed() public {
        // Register
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        // Slash operator
        vm.prank(owner);
        avsManager.slashOperator(alice, "Test slash");

        // Try to deregister
        vm.prank(alice);
        vm.expectRevert("Cannot deregister while slashed");
        avsManager.deregisterOperator();
    }

    // ============================================================================
    // Stake Management Tests
    // ============================================================================

    function testIncreaseStake() public {
        // Register
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        // Increase stake
        uint256 additionalStake = 2 ether;

        vm.expectEmit(true, false, false, true);
        emit StakeIncreased(alice, additionalStake);

        vm.prank(alice);
        avsManager.increaseStake{value: additionalStake}();

        // Check stake increased
        (, uint256 stakedAmount, , , , , ) = avsManager.operators(alice);
        assertEq(stakedAmount, MIN_STAKE + additionalStake);
    }

    function testIncreaseStakeRevertNotRegistered() public {
        vm.prank(alice);
        vm.expectRevert("Not registered");
        avsManager.increaseStake{value: 1 ether}();
    }

    function testIncreaseStakeRevertZeroAmount() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(alice);
        vm.expectRevert("Must stake non-zero amount");
        avsManager.increaseStake{value: 0}();
    }

    // ============================================================================
    // Task Management Tests
    // ============================================================================

    function testAssignPoolTask() public {
        // Register operator
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        uint256 duration = 1000; // blocks

        vm.expectEmit(true, true, true, false);
        emit TaskCreated(0, POOL_ID_1, alice);

        // Assign task (only owner can do this)
        vm.prank(owner);
        uint256 taskId = avsManager.assignPoolTask(POOL_ID_1, alice, duration);

        assertEq(taskId, 0);

        // Check task info
        (
            bytes32 poolId,
            address assignedOperator,
            uint256 startBlock,
            uint256 endBlock,
            uint256 expectedFeeOptimizations,
            uint256 actualFeeOptimizations,
            uint256 revenueGenerated,
            bool isCompleted,
            bool isValidated
        ) = avsManager.tasks(taskId);

        assertEq(poolId, POOL_ID_1);
        assertEq(assignedOperator, alice);
        assertEq(startBlock, block.number);
        assertEq(endBlock, block.number + duration);
        assertEq(expectedFeeOptimizations, 10);
        assertEq(actualFeeOptimizations, 0);
        assertEq(revenueGenerated, 0);
        assertFalse(isCompleted);
        assertFalse(isValidated);

        // Check pool operator mapping
        assertEq(avsManager.poolOperators(POOL_ID_1), alice);
    }

    function testAssignPoolTaskRevertNotRegistered() public {
        vm.prank(owner);
        vm.expectRevert("Operator not registered");
        avsManager.assignPoolTask(POOL_ID_1, alice, 1000);
    }

    function testAssignPoolTaskRevertOperatorSlashed() public {
        // Register
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        // Slash
        vm.prank(owner);
        avsManager.slashOperator(alice, "Test");

        // Try to assign task
        vm.prank(owner);
        vm.expectRevert("Operator is slashed");
        avsManager.assignPoolTask(POOL_ID_1, alice, 1000);
    }

    function testMultipleTaskAssignments() public {
        // Register operators
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(bob);
        avsManager.registerOperator{value: MIN_STAKE}();

        // Assign tasks
        vm.startPrank(owner);
        uint256 task1 = avsManager.assignPoolTask(POOL_ID_1, alice, 1000);
        uint256 task2 = avsManager.assignPoolTask(POOL_ID_2, bob, 2000);
        vm.stopPrank();

        assertEq(task1, 0);
        assertEq(task2, 1);
        assertEq(avsManager.poolOperators(POOL_ID_1), alice);
        assertEq(avsManager.poolOperators(POOL_ID_2), bob);
    }

    // ============================================================================
    // Performance Proof Tests
    // ============================================================================

    function testSubmitPerformanceProof() public {
        // Setup: Register and assign task
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(owner);
        uint256 taskId = avsManager.assignPoolTask(POOL_ID_1, alice, 100);

        // Move to after task end
        vm.roll(block.number + 101);

        // Submit proof
        uint256 feeOptimizations = 15;
        uint256 revenueGenerated = 10 ether;
        uint256 gasUsed = 1 ether;
        bytes32 proofHash = keccak256("proof");

        vm.expectEmit(true, true, false, true);
        emit PerformanceProofSubmitted(taskId, alice, proofHash);

        vm.prank(alice);
        avsManager.submitPerformanceProof(
            taskId,
            feeOptimizations,
            revenueGenerated,
            gasUsed,
            proofHash
        );

        // Check task updated
        (, , , , , uint256 actualFeeOpts, uint256 revenue, bool isCompleted, ) =
            avsManager.tasks(taskId);

        assertEq(actualFeeOpts, feeOptimizations);
        assertEq(revenue, revenueGenerated);
        assertTrue(isCompleted);

        // Check performance proof stored
        AuctionPoolAVSServiceManager.PerformanceProof memory proof = avsManager.getPerformanceProof(taskId);

        assertEq(proof.taskId, taskId);
        assertGt(proof.timestamp, 0);
        assertEq(proof.feeOptimizations, feeOptimizations);
        assertEq(proof.revenueGenerated, revenueGenerated);
        assertEq(proof.gasUsed, gasUsed);
        assertEq(proof.proofHash, proofHash);
        assertFalse(proof.isValidated);
        assertEq(proof.challenger, address(0));
    }

    function testSubmitPerformanceProofRevertNotAssigned() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(owner);
        uint256 taskId = avsManager.assignPoolTask(POOL_ID_1, alice, 100);

        vm.roll(block.number + 101);

        // Bob tries to submit proof for Alice's task
        vm.prank(bob);
        vm.expectRevert("Not assigned operator");
        avsManager.submitPerformanceProof(taskId, 10, 1 ether, 0.1 ether, keccak256("proof"));
    }

    function testSubmitPerformanceProofRevertTaskNotEnded() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(owner);
        uint256 taskId = avsManager.assignPoolTask(POOL_ID_1, alice, 100);

        // Don't move forward enough blocks
        vm.roll(block.number + 50);

        vm.prank(alice);
        vm.expectRevert("Task not ended yet");
        avsManager.submitPerformanceProof(taskId, 10, 1 ether, 0.1 ether, keccak256("proof"));
    }

    function testSubmitPerformanceProofRevertAlreadyCompleted() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(owner);
        uint256 taskId = avsManager.assignPoolTask(POOL_ID_1, alice, 100);

        vm.roll(block.number + 101);

        // Submit once
        vm.prank(alice);
        avsManager.submitPerformanceProof(taskId, 10, 1 ether, 0.1 ether, keccak256("proof"));

        // Try to submit again
        vm.prank(alice);
        vm.expectRevert("Task already completed");
        avsManager.submitPerformanceProof(taskId, 10, 1 ether, 0.1 ether, keccak256("proof"));
    }

    // ============================================================================
    // Performance Validation Tests
    // ============================================================================

    function testValidatePerformanceProofSuccess() public {
        // Setup and submit proof
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(owner);
        uint256 taskId = avsManager.assignPoolTask(POOL_ID_1, alice, 100);

        vm.roll(block.number + 101);

        vm.prank(alice);
        avsManager.submitPerformanceProof(taskId, 15, 10 ether, 1 ether, keccak256("proof"));

        // Validate
        vm.expectEmit(true, false, false, true);
        emit TaskCompleted(taskId, 10000); // 15/10 = 150% = capped at 10000

        vm.prank(owner);
        avsManager.validatePerformanceProof(taskId, true);

        // Check task validated
        (, , , , , , , , bool isValidated) = avsManager.tasks(taskId);
        assertTrue(isValidated);

        // Check operator stats updated
        (, , , uint256 totalCompleted, uint256 totalFailed, , bool isSlashed) =
            avsManager.operators(alice);

        assertEq(totalCompleted, 1);
        assertEq(totalFailed, 0);
        assertFalse(isSlashed); // Good performance, not slashed
    }

    function testValidatePerformanceProofLowPerformanceSlashed() public {
        // Setup and submit proof with low performance
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(owner);
        uint256 taskId = avsManager.assignPoolTask(POOL_ID_1, alice, 100);

        vm.roll(block.number + 101);

        // Only 5 optimizations when 10 expected = 50% performance
        vm.prank(alice);
        avsManager.submitPerformanceProof(taskId, 5, 1 ether, 0.5 ether, keccak256("proof"));

        uint256 stakeBefore = MIN_STAKE;

        // Validate - should trigger slashing (50% < 70% threshold)
        vm.prank(owner);
        avsManager.validatePerformanceProof(taskId, true);

        // Check operator was slashed
        (, uint256 stakeAfter, , , , , bool isSlashed) = avsManager.operators(alice);

        assertTrue(isSlashed);
        assertLt(stakeAfter, stakeBefore);
        // Should have lost 10% (slashing penalty)
        assertEq(stakeAfter, stakeBefore - (stakeBefore * 1000 / 10000));
    }

    function testValidatePerformanceProofInvalid() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(owner);
        uint256 taskId = avsManager.assignPoolTask(POOL_ID_1, alice, 100);

        vm.roll(block.number + 101);

        vm.prank(alice);
        avsManager.submitPerformanceProof(taskId, 15, 10 ether, 1 ether, keccak256("proof"));

        // Validate as invalid (fraud detected)
        vm.prank(owner);
        avsManager.validatePerformanceProof(taskId, false);

        // Check operator stats
        (, , , uint256 totalCompleted, uint256 totalFailed, , bool isSlashed) =
            avsManager.operators(alice);

        assertEq(totalCompleted, 0);
        assertEq(totalFailed, 1);
        assertTrue(isSlashed); // Slashed for invalid proof
    }

    function testValidatePerformanceProofRevertNotCompleted() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(owner);
        uint256 taskId = avsManager.assignPoolTask(POOL_ID_1, alice, 100);

        // Try to validate before proof submitted
        vm.prank(owner);
        vm.expectRevert("Task not completed");
        avsManager.validatePerformanceProof(taskId, true);
    }

    // ============================================================================
    // Performance Challenge Tests
    // ============================================================================

    function testChallengePerformanceProof() public {
        // Setup and submit proof
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(owner);
        uint256 taskId = avsManager.assignPoolTask(POOL_ID_1, alice, 100);

        vm.roll(block.number + 101);

        vm.prank(alice);
        avsManager.submitPerformanceProof(taskId, 15, 10 ether, 1 ether, keccak256("proof"));

        // Bob challenges the proof
        vm.expectEmit(true, true, false, false);
        emit PerformanceChallenged(taskId, bob);

        vm.prank(bob);
        avsManager.challengePerformanceProof(taskId);

        // Check challenge recorded
        AuctionPoolAVSServiceManager.PerformanceProof memory proof = avsManager.getPerformanceProof(taskId);
        assertEq(proof.challenger, bob);
    }

    function testChallengePerformanceProofRevertNoProof() public {
        vm.prank(bob);
        vm.expectRevert("No proof submitted");
        avsManager.challengePerformanceProof(999);
    }

    function testChallengePerformanceProofRevertExpired() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(owner);
        uint256 taskId = avsManager.assignPoolTask(POOL_ID_1, alice, 100);

        vm.roll(block.number + 101);

        vm.prank(alice);
        avsManager.submitPerformanceProof(taskId, 15, 10 ether, 1 ether, keccak256("proof"));

        // Move past challenge period (7200 blocks)
        vm.roll(block.number + 7201);

        vm.prank(bob);
        vm.expectRevert("Challenge period expired");
        avsManager.challengePerformanceProof(taskId);
    }

    // ============================================================================
    // Slashing Tests
    // ============================================================================

    function testManualSlashing() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        uint256 stakeBefore = MIN_STAKE;

        vm.expectEmit(true, false, false, true);
        emit OperatorSlashed(alice, stakeBefore * 1000 / 10000, "Manual slash");

        vm.prank(owner);
        avsManager.slashOperator(alice, "Manual slash");

        // Check slashed
        (, uint256 stakeAfter, , , , , bool isSlashed) = avsManager.operators(alice);

        assertTrue(isSlashed);
        assertEq(stakeAfter, stakeBefore - (stakeBefore * 1000 / 10000));
    }

    function testSlashingTwiceNoEffect() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(owner);
        avsManager.slashOperator(alice, "First slash");

        (, uint256 stakeAfterFirst, , , , , ) = avsManager.operators(alice);

        // Slash again - should not reduce stake further
        vm.prank(owner);
        avsManager.slashOperator(alice, "Second slash");

        (, uint256 stakeAfterSecond, , , , , ) = avsManager.operators(alice);

        assertEq(stakeAfterFirst, stakeAfterSecond);
    }

    // ============================================================================
    // Performance Score Tests
    // ============================================================================

    function testCalculatePerformanceScore() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(owner);
        uint256 taskId = avsManager.assignPoolTask(POOL_ID_1, alice, 100);

        vm.roll(block.number + 101);

        // Submit proof with 15 optimizations (expected 10)
        vm.prank(alice);
        avsManager.submitPerformanceProof(taskId, 15, 10 ether, 1 ether, keccak256("proof"));

        uint256 score = avsManager.calculatePerformanceScore(taskId);

        // 15/10 = 1.5 = 150%, capped at 100% = 10000 basis points
        assertEq(score, 10000);
    }

    function testCalculatePerformanceScoreLow() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(owner);
        uint256 taskId = avsManager.assignPoolTask(POOL_ID_1, alice, 100);

        vm.roll(block.number + 101);

        // Submit proof with 5 optimizations (expected 10) = 50%
        vm.prank(alice);
        avsManager.submitPerformanceProof(taskId, 5, 1 ether, 0.5 ether, keccak256("proof"));

        uint256 score = avsManager.calculatePerformanceScore(taskId);

        assertEq(score, 5000); // 50% = 5000 basis points
    }

    function testGetOperatorPerformanceScore() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        // Initially 0 (no tasks)
        uint256 initialScore = avsManager.getOperatorPerformanceScore(alice);
        assertEq(initialScore, 0);

        // Complete 2 tasks successfully
        vm.startPrank(owner);
        uint256 task1 = avsManager.assignPoolTask(POOL_ID_1, alice, 100);
        uint256 task2 = avsManager.assignPoolTask(POOL_ID_2, alice, 100);
        vm.stopPrank();

        vm.roll(block.number + 101);

        vm.startPrank(alice);
        avsManager.submitPerformanceProof(task1, 15, 10 ether, 1 ether, keccak256("proof1"));
        avsManager.submitPerformanceProof(task2, 12, 8 ether, 0.8 ether, keccak256("proof2"));
        vm.stopPrank();

        vm.startPrank(owner);
        avsManager.validatePerformanceProof(task1, true);
        avsManager.validatePerformanceProof(task2, true);
        vm.stopPrank();

        // 2 completed, 0 failed = 100%
        uint256 finalScore = avsManager.getOperatorPerformanceScore(alice);
        assertEq(finalScore, 10000);
    }

    // ============================================================================
    // Configuration Tests
    // ============================================================================

    function testSetMinStakeAmount() public {
        uint256 newMinStake = 2 ether;

        vm.prank(owner);
        avsManager.setMinStakeAmount(newMinStake);

        assertEq(avsManager.minStakeAmount(), newMinStake);
    }

    function testSetMinPerformanceScore() public {
        uint256 newMinScore = 8000; // 80%

        vm.prank(owner);
        avsManager.setMinPerformanceScore(newMinScore);

        assertEq(avsManager.minPerformanceScore(), newMinScore);
    }

    function testSetSlashingPenalty() public {
        uint256 newPenalty = 2000; // 20%

        vm.prank(owner);
        avsManager.setSlashingPenalty(newPenalty);

        assertEq(avsManager.slashingPenalty(), newPenalty);
    }

    function testSetChallengePeriod() public {
        uint256 newPeriod = 14400; // ~2 days

        vm.prank(owner);
        avsManager.setChallengePeriod(newPeriod);

        assertEq(avsManager.challengePeriod(), newPeriod);
    }

    // ============================================================================
    // View Function Tests
    // ============================================================================

    function testGetOperatorInfo() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        AuctionPoolAVSServiceManager.OperatorInfo memory info = avsManager.getOperatorInfo(alice);

        assertTrue(info.isRegistered);
        assertEq(info.stakedAmount, MIN_STAKE);
        assertEq(info.registrationBlock, block.number);
        assertEq(info.totalTasksCompleted, 0);
        assertEq(info.totalTasksFailed, 0);
        assertFalse(info.isSlashed);
    }

    function testGetTask() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(owner);
        uint256 taskId = avsManager.assignPoolTask(POOL_ID_1, alice, 1000);

        AuctionPoolAVSServiceManager.PoolTask memory task = avsManager.getTask(taskId);

        assertEq(task.poolId, POOL_ID_1);
        assertEq(task.assignedOperator, alice);
        assertEq(task.endBlock, task.startBlock + 1000);
        assertFalse(task.isCompleted);
        assertFalse(task.isValidated);
    }

    function testGetAllOperators() public {
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        vm.prank(bob);
        avsManager.registerOperator{value: MIN_STAKE}();

        address[] memory operators = avsManager.getAllOperators();

        assertEq(operators.length, 2);
        assertTrue(operators[0] == alice || operators[1] == alice);
        assertTrue(operators[0] == bob || operators[1] == bob);
    }

    // ============================================================================
    // Integration Tests
    // ============================================================================

    function testFullOperatorLifecycle() public {
        // 1. Register
        vm.prank(alice);
        avsManager.registerOperator{value: MIN_STAKE}();

        // 2. Get assigned task
        vm.prank(owner);
        uint256 taskId = avsManager.assignPoolTask(POOL_ID_1, alice, 1000);

        // 3. Complete task
        vm.roll(block.number + 1001);

        vm.prank(alice);
        avsManager.submitPerformanceProof(taskId, 12, 5 ether, 0.5 ether, keccak256("proof"));

        // 4. Validate
        vm.prank(owner);
        avsManager.validatePerformanceProof(taskId, true);

        // 5. Check stats
        (, , , uint256 completed, uint256 failed, , bool isSlashed) =
            avsManager.operators(alice);

        assertEq(completed, 1);
        assertEq(failed, 0);
        assertFalse(isSlashed);

        // 6. Deregister
        vm.prank(alice);
        avsManager.deregisterOperator();

        assertFalse(avsManager.isOperatorRegistered(alice));
    }

    function testMultipleOperatorsCompeting() public {
        // Register multiple operators
        vm.prank(alice);
        avsManager.registerOperator{value: 2 ether}();

        vm.prank(bob);
        avsManager.registerOperator{value: 3 ether}();

        vm.prank(charlie);
        avsManager.registerOperator{value: 1.5 ether}();

        // Assign tasks to different operators
        vm.startPrank(owner);
        uint256 task1 = avsManager.assignPoolTask(POOL_ID_1, alice, 500);
        uint256 task2 = avsManager.assignPoolTask(POOL_ID_2, bob, 500);
        vm.stopPrank();

        vm.roll(block.number + 501);

        // Alice performs well
        vm.prank(alice);
        avsManager.submitPerformanceProof(task1, 20, 15 ether, 1 ether, keccak256("alice"));

        // Bob performs poorly
        vm.prank(bob);
        avsManager.submitPerformanceProof(task2, 3, 1 ether, 0.5 ether, keccak256("bob"));

        // Validate
        vm.startPrank(owner);
        avsManager.validatePerformanceProof(task1, true);
        avsManager.validatePerformanceProof(task2, true);
        vm.stopPrank();

        // Alice not slashed (good performance)
        (, , , , , , bool aliceSlashed) = avsManager.operators(alice);
        assertFalse(aliceSlashed);

        // Bob slashed (poor performance: 3/10 = 30% < 70%)
        (, , , , , , bool bobSlashed) = avsManager.operators(bob);
        assertTrue(bobSlashed);
    }
}
