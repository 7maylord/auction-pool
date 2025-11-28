/**
 * Manager operations module - executes on-chain actions
 * Functional approach with side effects isolated in TaskEither
 */

import { BigNumber, Contract, Wallet, providers } from 'ethers';
import {
  PoolId,
  Wei,
  Address,
  Logger,
  TaskEither,
  taskEitherTryCatch,
  Result,
  Right,
  Left
} from '../core/types';
import { retry } from '../core/functional';

// ============================================================================
// Configuration
// ============================================================================

export interface ManagerOpsConfig {
  readonly provider: providers.Provider;
  readonly wallet: Wallet;
  readonly hookAddress: string;
  readonly poolManagerAddress: string;
  readonly logger: Logger;
  readonly gasMultiplier: number; // e.g., 1.2 = 20% above estimated
}

// ============================================================================
// Transaction Result Types
// ============================================================================

export interface TransactionResult {
  readonly hash: string;
  readonly blockNumber: number;
  readonly gasUsed: BigNumber;
  readonly effectiveGasPrice: BigNumber;
  readonly status: 'success' | 'failed';
}

// ============================================================================
// Contract ABIs
// ============================================================================

const HOOK_ABI = [
  'function submitBid(tuple(address currency0, address currency1, uint24 fee, int24 tickSpacing, address hooks) key, uint256 rentPerBlock) external payable',
  'function setSwapFee(tuple(address currency0, address currency1, uint24 fee, int24 tickSpacing, address hooks) key, uint24 newFee) external',
  'function withdrawManagerFees(tuple(address currency0, address currency1, uint24 fee, int24 tickSpacing, address hooks) key) external',
  'function claimRent(tuple(address currency0, address currency1, uint24 fee, int24 tickSpacing, address hooks) key) external',
  'function managerFees(address manager, bytes32 poolId) external view returns (uint256)',
  'function getPendingRent(bytes32 poolId, address lp) external view returns (uint256)'
];

const POOL_MANAGER_ABI = [
  'function getSlot0(bytes32 poolId) external view returns (uint160 sqrtPriceX96, int24 tick, uint24 protocolFee)'
];

// ============================================================================
// Pool Key Type
// ============================================================================

export interface PoolKey {
  readonly currency0: string;
  readonly currency1: string;
  readonly fee: number;
  readonly tickSpacing: number;
  readonly hooks: string;
}

// ============================================================================
// Pure Functions for Transaction Preparation
// ============================================================================

const calculateGasPrice = async (
  provider: providers.Provider,
  multiplier: number
): Promise<BigNumber> => {
  const feeData = await provider.getFeeData();
  const baseGasPrice = feeData.gasPrice || BigNumber.from('20000000000'); // 20 gwei fallback

  return baseGasPrice.mul(Math.floor(multiplier * 100)).div(100);
};

const estimateGasWithBuffer = (estimatedGas: BigNumber, buffer: number = 1.2): BigNumber => {
  return estimatedGas.mul(Math.floor(buffer * 100)).div(100);
};

// ============================================================================
// Manager Operations (Side Effects in TaskEither)
// ============================================================================

export const createManagerOps = (config: ManagerOpsConfig) => {
  const { provider, wallet, hookAddress, poolManagerAddress, logger, gasMultiplier } = config;

  const hook = new Contract(hookAddress, HOOK_ABI, wallet);
  const poolManager = new Contract(poolManagerAddress, POOL_MANAGER_ABI, provider);

  /**
   * Submit a bid for pool management
   */
  const submitBid = (
    poolKey: PoolKey,
    rentPerBlock: Wei
  ): TaskEither<string, TransactionResult> =>
    taskEitherTryCatch(
      async () => {
        logger.info('Submitting bid', {
          poolKey,
          rentPerBlock: rentPerBlock.value.toString()
        });

        // Calculate required deposit (MIN_DEPOSIT_BLOCKS = 100)
        const minDepositBlocks = 100;
        const deposit = rentPerBlock.value.mul(minDepositBlocks);

        // Get gas price
        const gasPrice = await calculateGasPrice(provider, gasMultiplier);

        // Estimate gas
        const estimatedGas = await hook.estimateGas.submitBid(
          poolKey,
          rentPerBlock.value,
          { value: deposit, gasPrice }
        );

        const gasLimit = estimateGasWithBuffer(estimatedGas);

        // Submit transaction
        const tx = await hook.submitBid(
          poolKey,
          rentPerBlock.value,
          {
            value: deposit,
            gasPrice,
            gasLimit
          }
        );

        logger.info('Bid transaction submitted', { hash: tx.hash });

        // Wait for confirmation
        const receipt = await tx.wait(1);

        logger.info('Bid confirmed', {
          hash: receipt.transactionHash,
          blockNumber: receipt.blockNumber,
          gasUsed: receipt.gasUsed.toString()
        });

        return {
          hash: receipt.transactionHash,
          blockNumber: receipt.blockNumber,
          gasUsed: receipt.gasUsed,
          effectiveGasPrice: receipt.effectiveGasPrice,
          status: receipt.status === 1 ? 'success' : 'failed'
        };
      },
      (error) => {
        logger.error('Failed to submit bid', { error });
        return `Failed to submit bid: ${error}`;
      }
    );

  /**
   * Set swap fee for a pool (manager only)
   */
  const setSwapFee = (
    poolKey: PoolKey,
    newFee: number
  ): TaskEither<string, TransactionResult> =>
    taskEitherTryCatch(
      async () => {
        logger.info('Setting swap fee', { poolKey, newFee });

        const gasPrice = await calculateGasPrice(provider, gasMultiplier);

        const estimatedGas = await hook.estimateGas.setSwapFee(
          poolKey,
          newFee,
          { gasPrice }
        );

        const gasLimit = estimateGasWithBuffer(estimatedGas);

        const tx = await hook.setSwapFee(poolKey, newFee, {
          gasPrice,
          gasLimit
        });

        logger.info('Set fee transaction submitted', { hash: tx.hash });

        const receipt = await tx.wait(1);

        logger.info('Fee updated', {
          hash: receipt.transactionHash,
          blockNumber: receipt.blockNumber,
          newFee
        });

        return {
          hash: receipt.transactionHash,
          blockNumber: receipt.blockNumber,
          gasUsed: receipt.gasUsed,
          effectiveGasPrice: receipt.effectiveGasPrice,
          status: receipt.status === 1 ? 'success' : 'failed'
        };
      },
      (error) => {
        logger.error('Failed to set swap fee', { error });
        return `Failed to set swap fee: ${error}`;
      }
    );

  /**
   * Withdraw collected manager fees
   */
  const withdrawManagerFees = (
    poolKey: PoolKey
  ): TaskEither<string, TransactionResult> =>
    taskEitherTryCatch(
      async () => {
        logger.info('Withdrawing manager fees', { poolKey });

        const gasPrice = await calculateGasPrice(provider, gasMultiplier);

        const estimatedGas = await hook.estimateGas.withdrawManagerFees(
          poolKey,
          { gasPrice }
        );

        const gasLimit = estimateGasWithBuffer(estimatedGas);

        const tx = await hook.withdrawManagerFees(poolKey, {
          gasPrice,
          gasLimit
        });

        logger.info('Withdraw transaction submitted', { hash: tx.hash });

        const receipt = await tx.wait(1);

        logger.info('Fees withdrawn', {
          hash: receipt.transactionHash,
          blockNumber: receipt.blockNumber
        });

        return {
          hash: receipt.transactionHash,
          blockNumber: receipt.blockNumber,
          gasUsed: receipt.gasUsed,
          effectiveGasPrice: receipt.effectiveGasPrice,
          status: receipt.status === 1 ? 'success' : 'failed'
        };
      },
      (error) => {
        logger.error('Failed to withdraw manager fees', { error });
        return `Failed to withdraw manager fees: ${error}`;
      }
    );

  /**
   * Check accumulated manager fees (read-only)
   */
  const checkManagerFees = (
    poolId: PoolId,
    managerAddress: Address
  ): TaskEither<string, Wei> =>
    taskEitherTryCatch(
      async () => {
        const fees: BigNumber = await hook.managerFees(
          managerAddress.value,
          poolId.value
        );

        logger.debug('Manager fees checked', {
          poolId: poolId.value,
          manager: managerAddress.value,
          fees: fees.toString()
        });

        return { value: fees };
      },
      (error) => `Failed to check manager fees: ${error}`
    );

  /**
   * Check pending rent for LP (read-only)
   */
  const checkPendingRent = (
    poolId: PoolId,
    lpAddress: Address
  ): TaskEither<string, Wei> =>
    taskEitherTryCatch(
      async () => {
        const rent: BigNumber = await hook.getPendingRent(
          poolId.value,
          lpAddress.value
        );

        logger.debug('Pending rent checked', {
          poolId: poolId.value,
          lp: lpAddress.value,
          rent: rent.toString()
        });

        return { value: rent };
      },
      (error) => `Failed to check pending rent: ${error}`
    );

  /**
   * Get current pool slot0 data (read-only)
   */
  const getPoolSlot0 = (
    poolId: PoolId
  ): TaskEither<string, { sqrtPriceX96: BigNumber; tick: number; protocolFee: number }> =>
    taskEitherTryCatch(
      async () => {
        const slot0 = await poolManager.getSlot0(poolId.value);

        return {
          sqrtPriceX96: slot0.sqrtPriceX96,
          tick: slot0.tick,
          protocolFee: slot0.protocolFee
        };
      },
      (error) => `Failed to get pool slot0: ${error}`
    );

  /**
   * Get wallet balance
   */
  const getBalance = (): TaskEither<string, Wei> =>
    taskEitherTryCatch(
      async () => {
        const balance = await wallet.getBalance();
        return { value: balance };
      },
      (error) => `Failed to get balance: ${error}`
    );

  return {
    submitBid: (poolKey: PoolKey, rentPerBlock: Wei) =>
      retry(submitBid(poolKey, rentPerBlock), 3, 5000),

    setSwapFee: (poolKey: PoolKey, newFee: number) =>
      retry(setSwapFee(poolKey, newFee), 3, 5000),

    withdrawManagerFees: (poolKey: PoolKey) =>
      retry(withdrawManagerFees(poolKey), 3, 5000),

    checkManagerFees,
    checkPendingRent,
    getPoolSlot0,
    getBalance
  };
};

// ============================================================================
// Type Export
// ============================================================================

export type ManagerOps = ReturnType<typeof createManagerOps>;

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Check if withdrawal is profitable (fees > gas cost)
 */
export const isWithdrawalProfitable = (
  accumulatedFees: Wei,
  gasPrice: BigNumber,
  minProfitMultiplier: number = 2
): boolean => {
  // Estimate gas for withdrawal (~100k gas)
  const estimatedGas = BigNumber.from(100000);
  const gasCost = gasPrice.mul(estimatedGas);

  // Only withdraw if fees are at least 2x the gas cost
  return accumulatedFees.value.gte(gasCost.mul(minProfitMultiplier));
};

/**
 * Calculate optimal fee update frequency
 * Returns number of blocks to wait before next update
 */
export const calculateFeeUpdateFrequency = (
  volatility: number,
  volumeChange: number,
  minBlocks: number = 10,
  maxBlocks: number = 100
): number => {
  // High volatility or volume changes = update more frequently
  const volatilityFactor = Math.max(0, 1 - volatility);
  const volumeChangeFactor = Math.max(0, 1 - Math.abs(volumeChange) / 100);

  const combinedFactor = (volatilityFactor + volumeChangeFactor) / 2;

  const blocks = Math.floor(minBlocks + (maxBlocks - minBlocks) * combinedFactor);

  return Math.max(minBlocks, Math.min(maxBlocks, blocks));
};
