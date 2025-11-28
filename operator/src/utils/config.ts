/**
 * Configuration management with validation
 */

import * as dotenv from 'dotenv';
import { BigNumber } from 'ethers';
import { Config, ConfigCodec, Result, Right, Left } from '../core/types';
import { isRight } from 'io-ts';

dotenv.config();

// ============================================================================
// Environment Variable Loading
// ============================================================================

const getEnvVar = (key: string, defaultValue?: string): string => {
  const value = process.env[key];
  if (value === undefined) {
    if (defaultValue !== undefined) {
      return defaultValue;
    }
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
};

const getEnvNumber = (key: string, defaultValue?: number): number => {
  const value = process.env[key];
  if (value === undefined) {
    if (defaultValue !== undefined) {
      return defaultValue;
    }
    throw new Error(`Missing required environment variable: ${key}`);
  }
  const num = parseFloat(value);
  if (isNaN(num)) {
    throw new Error(`Invalid number for environment variable ${key}: ${value}`);
  }
  return num;
};

// ============================================================================
// Configuration Loading
// ============================================================================

export const loadConfig = (): Result<string, Config> => {
  try {
    const config: Config = {
      rpcUrl: getEnvVar('RPC_URL'),
      chainId: getEnvNumber('CHAIN_ID'),
      operatorPrivateKey: getEnvVar('OPERATOR_PRIVATE_KEY'),
      poolManagerAddress: getEnvVar('POOL_MANAGER_ADDRESS'),
      hookAddress: getEnvVar('HOOK_ADDRESS'),
      minProfitMargin: getEnvNumber('MIN_PROFIT_MARGIN', 0.001),
      maxBidAmountEth: getEnvNumber('MAX_BID_AMOUNT_ETH', 1.0),
      volatilityWeight: getEnvNumber('VOLATILITY_WEIGHT', 0.4),
      volumeWeight: getEnvNumber('VOLUME_WEIGHT', 0.3),
      spreadWeight: getEnvNumber('SPREAD_WEIGHT', 0.3)
    };

    // Validate using io-ts
    const validation = ConfigCodec.decode(config);
    if (isRight(validation)) {
      return Right(validation.right);
    } else {
      return Left('Configuration validation failed');
    }
  } catch (error) {
    return Left(`Failed to load configuration: ${error}`);
  }
};

// ============================================================================
// Derived Configuration
// ============================================================================

export interface OperatorConfig {
  readonly network: {
    readonly rpcUrl: string;
    readonly chainId: number;
  };
  readonly operator: {
    readonly privateKey: string;
    readonly address: string;
  };
  readonly contracts: {
    readonly poolManager: string;
    readonly hook: string;
    readonly avsServiceManager?: string;
  };
  readonly strategy: {
    readonly minProfitMargin: number;
    readonly maxBidAmountWei: BigNumber;
    readonly riskTolerance: number;
  };
  readonly optimization: {
    readonly volatilityWeight: number;
    readonly volumeWeight: number;
    readonly spreadWeight: number;
    readonly minFee: number;
    readonly maxFee: number;
  };
  readonly monitoring: {
    readonly poolRefreshIntervalMs: number;
    readonly healthCheckIntervalMs: number;
    readonly updateFrequencyBlocks: number;
  };
  readonly gas: {
    readonly priceMultiplier: number;
    readonly maxPriorityFeePerGas?: BigNumber;
  };
}

export const createOperatorConfig = (baseConfig: Config): OperatorConfig => {
  return {
    network: {
      rpcUrl: baseConfig.rpcUrl,
      chainId: baseConfig.chainId
    },
    operator: {
      privateKey: baseConfig.operatorPrivateKey,
      address: '' // Will be derived from private key
    },
    contracts: {
      poolManager: baseConfig.poolManagerAddress,
      hook: baseConfig.hookAddress,
      avsServiceManager: process.env.AVS_SERVICE_MANAGER_ADDRESS
    },
    strategy: {
      minProfitMargin: baseConfig.minProfitMargin,
      maxBidAmountWei: BigNumber.from(baseConfig.maxBidAmountEth * 1e18),
      riskTolerance: getEnvNumber('RISK_TOLERANCE', 0.5)
    },
    optimization: {
      volatilityWeight: baseConfig.volatilityWeight,
      volumeWeight: baseConfig.volumeWeight,
      spreadWeight: baseConfig.spreadWeight,
      minFee: 100, // 0.01% in hundredths of basis points
      maxFee: 10000 // 1% in hundredths of basis points
    },
    monitoring: {
      poolRefreshIntervalMs: getEnvNumber('POOL_REFRESH_INTERVAL_MS', 12000),
      healthCheckIntervalMs: getEnvNumber('HEALTH_CHECK_INTERVAL_MS', 60000),
      updateFrequencyBlocks: getEnvNumber('UPDATE_FREQUENCY_BLOCKS', 10)
    },
    gas: {
      priceMultiplier: getEnvNumber('GAS_PRICE_MULTIPLIER', 1.2)
    }
  };
};

// ============================================================================
// Validation Functions
// ============================================================================

export const validateConfig = (config: OperatorConfig): Result<string, OperatorConfig> => {
  // Validate weights sum to 1.0
  const weightSum =
    config.optimization.volatilityWeight +
    config.optimization.volumeWeight +
    config.optimization.spreadWeight;

  if (Math.abs(weightSum - 1.0) > 0.01) {
    return Left(`Optimization weights must sum to 1.0, got ${weightSum}`);
  }

  // Validate addresses
  if (!config.contracts.poolManager.match(/^0x[a-fA-F0-9]{40}$/)) {
    return Left('Invalid pool manager address');
  }

  if (!config.contracts.hook.match(/^0x[a-fA-F0-9]{40}$/)) {
    return Left('Invalid hook address');
  }

  // Validate profit margin
  if (config.strategy.minProfitMargin <= 0 || config.strategy.minProfitMargin >= 1) {
    return Left('Min profit margin must be between 0 and 1');
  }

  // Validate risk tolerance
  if (config.strategy.riskTolerance < 0 || config.strategy.riskTolerance > 1) {
    return Left('Risk tolerance must be between 0 and 1');
  }

  return Right(config);
};
