/**
 * EigenLayer AVS Integration Module
 * Connects operator node to AuctionPoolAVSServiceManager contract
 */

import { Contract, Wallet, providers, BigNumber } from 'ethers';
import {
  Address,
  Logger,
  TaskEither,
  taskEitherTryCatch,
  PoolId,
  Wei
} from '../core/types';
import { retry } from '../core/functional';

// ============================================================================
// AVS Service Manager ABI
// ============================================================================

const AVS_SERVICE_MANAGER_ABI = [
  'function registerOperator() external payable',
  'function deregisterOperator() external',
  'function increaseStake() external payable',
  'function submitPerformanceProof(uint256 taskId, uint256 feeOptimizations, uint256 revenueGenerated, uint256 gasUsed, bytes32 proofHash) external',
  'function operators(address) external view returns (bool isRegistered, uint256 stakedAmount, uint256 registrationBlock, uint256 totalTasksCompleted, uint256 totalTasksFailed, uint256 lastPerformanceUpdate, bool isSlashed)',
  'function getOperatorPerformanceScore(address operator) external view returns (uint256)',
  'function isOperatorRegistered(address operator) external view returns (bool)',
  'function minStakeAmount() external view returns (uint256)',
  'function tasks(uint256) external view returns (bytes32 poolId, address assignedOperator, uint256 startBlock, uint256 endBlock, uint256 expectedFeeOptimizations, uint256 actualFeeOptimizations, uint256 revenueGenerated, bool isCompleted, bool isValidated)'
];

// ============================================================================
// Configuration
// ============================================================================

export interface AVSIntegrationConfig {
  readonly provider: providers.Provider;
  readonly wallet: Wallet;
  readonly avsServiceManagerAddress: string;
  readonly minStakeAmount: BigNumber;
  readonly logger: Logger;
}

// ============================================================================
// Types
// ============================================================================

export interface OperatorStatus {
  readonly isRegistered: boolean;
  readonly stakedAmount: BigNumber;
  readonly registrationBlock: number;
  readonly totalTasksCompleted: number;
  readonly totalTasksFailed: number;
  readonly performanceScore: number; // 0-10000 basis points
  readonly isSlashed: boolean;
}

export interface TaskInfo {
  readonly poolId: string;
  readonly assignedOperator: string;
  readonly startBlock: number;
  readonly endBlock: number;
  readonly expectedFeeOptimizations: number;
  readonly isCompleted: boolean;
}

export interface PerformanceMetrics {
  readonly feeOptimizations: number;
  readonly revenueGenerated: BigNumber;
  readonly gasUsed: BigNumber;
  readonly uptime: number; // percentage
}

// ============================================================================
// AVS Integration Module
// ============================================================================

export const createAVSIntegration = (config: AVSIntegrationConfig) => {
  const { provider, wallet, avsServiceManagerAddress, minStakeAmount, logger } = config;

  const avsContract = new Contract(
    avsServiceManagerAddress,
    AVS_SERVICE_MANAGER_ABI,
    wallet
  );

  /**
   * Register as AVS operator
   */
  const registerOperator = (
    stakeAmount?: BigNumber
  ): TaskEither<string, { txHash: string; blockNumber: number }> =>
    taskEitherTryCatch(
      async () => {
        const stake = stakeAmount || minStakeAmount;

        logger.info('Registering as AVS operator', {
          stakeAmount: stake.toString()
        });

        const tx = await avsContract.registerOperator({ value: stake });
        const receipt = await tx.wait(1);

        logger.info('Operator registered successfully', {
          txHash: receipt.transactionHash,
          blockNumber: receipt.blockNumber
        });

        return {
          txHash: receipt.transactionHash,
          blockNumber: receipt.blockNumber
        };
      },
      (error) => {
        logger.error('Failed to register operator', { error });
        return `Registration failed: ${error}`;
      }
    );

  /**
   * Deregister and withdraw stake
   */
  const deregisterOperator = (): TaskEither<string, { txHash: string }> =>
    taskEitherTryCatch(
      async () => {
        logger.info('Deregistering operator');

        const tx = await avsContract.deregisterOperator();
        const receipt = await tx.wait(1);

        logger.info('Operator deregistered', {
          txHash: receipt.transactionHash
        });

        return { txHash: receipt.transactionHash };
      },
      (error) => `Deregistration failed: ${error}`
    );

  /**
   * Increase operator stake
   */
  const increaseStake = (
    amount: BigNumber
  ): TaskEither<string, { txHash: string }> =>
    taskEitherTryCatch(
      async () => {
        logger.info('Increasing stake', { amount: amount.toString() });

        const tx = await avsContract.increaseStake({ value: amount });
        const receipt = await tx.wait(1);

        logger.info('Stake increased', { txHash: receipt.transactionHash });

        return { txHash: receipt.transactionHash };
      },
      (error) => `Stake increase failed: ${error}`
    );

  /**
   * Get operator status
   */
  const getOperatorStatus = (
    operatorAddress: Address
  ): TaskEither<string, OperatorStatus> =>
    taskEitherTryCatch(
      async () => {
        const [operatorInfo, performanceScore] = await Promise.all([
          avsContract.operators(operatorAddress.value),
          avsContract.getOperatorPerformanceScore(operatorAddress.value)
        ]);

        return {
          isRegistered: operatorInfo.isRegistered,
          stakedAmount: operatorInfo.stakedAmount,
          registrationBlock: operatorInfo.registrationBlock.toNumber(),
          totalTasksCompleted: operatorInfo.totalTasksCompleted.toNumber(),
          totalTasksFailed: operatorInfo.totalTasksFailed.toNumber(),
          performanceScore: performanceScore.toNumber(),
          isSlashed: operatorInfo.isSlashed
        };
      },
      (error) => `Failed to get operator status: ${error}`
    );

  /**
   * Submit performance proof for a task
   */
  const submitPerformanceProof = (
    taskId: number,
    metrics: PerformanceMetrics
  ): TaskEither<string, { txHash: string; proofHash: string }> =>
    taskEitherTryCatch(
      async () => {
        // Generate proof hash from metrics
        const proofData = {
          feeOptimizations: metrics.feeOptimizations,
          revenueGenerated: metrics.revenueGenerated.toString(),
          gasUsed: metrics.gasUsed.toString(),
          uptime: metrics.uptime,
          timestamp: Date.now()
        };

        const proofHash = require('ethers').utils.keccak256(
          require('ethers').utils.toUtf8Bytes(JSON.stringify(proofData))
        );

        logger.info('Submitting performance proof', {
          taskId,
          proofHash,
          ...metrics
        });

        const tx = await avsContract.submitPerformanceProof(
          taskId,
          metrics.feeOptimizations,
          metrics.revenueGenerated,
          metrics.gasUsed,
          proofHash
        );

        const receipt = await tx.wait(1);

        logger.info('Performance proof submitted', {
          txHash: receipt.transactionHash,
          taskId
        });

        return {
          txHash: receipt.transactionHash,
          proofHash
        };
      },
      (error) => {
        logger.error('Failed to submit performance proof', { error, taskId });
        return `Performance proof submission failed: ${error}`;
      }
    );

  /**
   * Get task information
   */
  const getTaskInfo = (taskId: number): TaskEither<string, TaskInfo> =>
    taskEitherTryCatch(
      async () => {
        const task = await avsContract.tasks(taskId);

        return {
          poolId: task.poolId,
          assignedOperator: task.assignedOperator,
          startBlock: task.startBlock.toNumber(),
          endBlock: task.endBlock.toNumber(),
          expectedFeeOptimizations: task.expectedFeeOptimizations.toNumber(),
          isCompleted: task.isCompleted
        };
      },
      (error) => `Failed to get task info: ${error}`
    );

  /**
   * Check if operator is registered
   */
  const isRegistered = (
    operatorAddress: Address
  ): TaskEither<string, boolean> =>
    taskEitherTryCatch(
      async () => {
        return await avsContract.isOperatorRegistered(operatorAddress.value);
      },
      (error) => `Failed to check registration: ${error}`
    );

  return {
    registerOperator: (stakeAmount?: BigNumber) =>
      retry(registerOperator(stakeAmount), 3, 5000),

    deregisterOperator: () =>
      retry(deregisterOperator(), 3, 5000),

    increaseStake: (amount: BigNumber) =>
      retry(increaseStake(amount), 3, 5000),

    submitPerformanceProof: (taskId: number, metrics: PerformanceMetrics) =>
      retry(submitPerformanceProof(taskId, metrics), 3, 5000),

    getOperatorStatus,
    getTaskInfo,
    isRegistered
  };
};

// ============================================================================
// Type Export
// ============================================================================

export type AVSIntegration = ReturnType<typeof createAVSIntegration>;

// ============================================================================
// Performance Tracking Helper
// ============================================================================

export class PerformanceTracker {
  private feeOptimizationCount = 0;
  private totalRevenue = BigNumber.from(0);
  private totalGasUsed = BigNumber.from(0);
  private startTime = Date.now();
  private uptimeStart = Date.now();

  incrementFeeOptimizations(): void {
    this.feeOptimizationCount++;
  }

  addRevenue(amount: BigNumber): void {
    this.totalRevenue = this.totalRevenue.add(amount);
  }

  addGasUsed(gas: BigNumber): void {
    this.totalGasUsed = this.totalGasUsed.add(gas);
  }

  getMetrics(): PerformanceMetrics {
    const uptime = ((Date.now() - this.uptimeStart) / (Date.now() - this.startTime)) * 100;

    return {
      feeOptimizations: this.feeOptimizationCount,
      revenueGenerated: this.totalRevenue,
      gasUsed: this.totalGasUsed,
      uptime: Math.min(100, uptime)
    };
  }

  reset(): void {
    this.feeOptimizationCount = 0;
    this.totalRevenue = BigNumber.from(0);
    this.totalGasUsed = BigNumber.from(0);
    this.startTime = Date.now();
    this.uptimeStart = Date.now();
  }
}
