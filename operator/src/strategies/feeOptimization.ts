/**
 * Fee optimization strategies using pure functional programming
 */

import { BigNumber } from 'ethers';
import {
  FeeOptimizationInput,
  OptimalFee,
  MarketData,
  PoolState,
  OptimizationConfig,
  Result,
  Right,
  Left
} from '../core/types';
import { pipe, map, validate } from '../core/functional';

// ============================================================================
// Pure Strategy Functions
// ============================================================================

/**
 * Volatility-based fee calculation
 * Higher volatility = higher fees (impermanent loss protection)
 */
const calculateVolatilityBasedFee = (volatility: number, config: OptimizationConfig): number => {
  // Scale volatility (0-1) to fee range
  const normalizedVolatility = Math.min(volatility / 2, 1); // Cap at 200% volatility
  const feeRange = config.maxFee - config.minFee;
  return config.minFee + (normalizedVolatility * feeRange);
};

/**
 * Volume-based fee calculation
 * Higher volume = lower fees (attract more trades)
 */
const calculateVolumeBasedFee = (
  volume24h: BigNumber,
  volumeChange: number,
  config: OptimizationConfig
): number => {
  // Inverse relationship: high volume -> low fees
  const volumeEth = parseFloat(volume24h.toString()) / 1e18;
  const volumeScore = Math.min(volumeEth / 1000, 1); // Normalize to 0-1 (1000 ETH = max)

  // If volume is growing, reduce fees to maintain momentum
  const growthMultiplier = volumeChange > 0 ? 0.9 : 1.1;

  const feeRange = config.maxFee - config.minFee;
  return config.minFee + ((1 - volumeScore) * feeRange) * growthMultiplier;
};

/**
 * Spread-based fee calculation
 * Tighter spread = can charge more (price discovery is good)
 */
const calculateSpreadBasedFee = (spread: number, config: OptimizationConfig): number => {
  // Inverse relationship: tight spread -> higher fees
  const normalizedSpread = Math.min(spread / 0.01, 1); // 1% spread = max
  const feeRange = config.maxFee - config.minFee;
  return config.minFee + ((1 - normalizedSpread) * feeRange);
};

/**
 * Weighted combination of all strategies
 */
const calculateWeightedFee = (
  volatilityFee: number,
  volumeFee: number,
  spreadFee: number,
  config: OptimizationConfig
): number => {
  const weighted =
    volatilityFee * config.volatilityWeight +
    volumeFee * config.volumeWeight +
    spreadFee * config.spreadWeight;

  // Ensure within bounds
  return Math.max(config.minFee, Math.min(config.maxFee, weighted));
};

/**
 * Estimate expected volume based on fee
 * Lower fees -> higher volume (price elasticity of demand)
 */
const estimateVolume = (
  currentVolume: BigNumber,
  currentFee: number,
  proposedFee: number
): BigNumber => {
  // Simple elasticity model: 10% fee reduction -> 20% volume increase
  const elasticity = 2;
  const feeRatio = proposedFee / Math.max(currentFee, 1);
  const volumeMultiplier = Math.pow(feeRatio, -elasticity);

  return currentVolume.mul(Math.floor(volumeMultiplier * 1000)).div(1000);
};

/**
 * Calculate expected revenue from fee
 */
const calculateExpectedRevenue = (
  estimatedVolume: BigNumber,
  fee: number
): BigNumber => {
  // Revenue = volume * fee
  // fee is in hundredths of basis points, so divide by 1,000,000
  return estimatedVolume.mul(fee).div(1000000);
};

/**
 * Calculate confidence score based on data quality
 */
const calculateConfidence = (
  marketData: MarketData,
  poolState: PoolState
): number => {
  let confidence = 1.0;

  // Reduce confidence if low trade count
  if (marketData.trades < 10) confidence *= 0.5;

  // Reduce confidence if low liquidity
  const liquidityEth = parseFloat(poolState.liquidity.toString()) / 1e18;
  if (liquidityEth < 10) confidence *= 0.7;

  // Reduce confidence if stale data
  const dataAge = Date.now() - marketData.timestamp;
  if (dataAge > 60000) confidence *= 0.8; // More than 1 minute old

  return Math.max(0.1, Math.min(1.0, confidence));
};

// ============================================================================
// Main Optimization Function
// ============================================================================

/**
 * Calculate optimal fee using multiple strategies
 */
export const calculateOptimalFee = (input: FeeOptimizationInput): Result<string, OptimalFee> => {
  const { poolState, marketData, config } = input;

  // Validate inputs
  if (poolState.liquidity.isZero()) {
    return Left('Cannot optimize fee for pool with zero liquidity');
  }

  // Calculate individual strategy fees
  const volatilityFee = calculateVolatilityBasedFee(marketData.volatility, config);
  const volumeFee = calculateVolumeBasedFee(marketData.volume24h, marketData.volumeChange, config);
  const spreadFee = calculateSpreadBasedFee(marketData.spread, config);

  // Combine with weights
  const optimalFee = calculateWeightedFee(volatilityFee, volumeFee, spreadFee, config);

  // Round to nearest valid value (fees are in hundredths of basis points)
  const roundedFee = Math.round(optimalFee);

  // Estimate outcomes
  const estimatedVolume = estimateVolume(
    marketData.volume24h,
    poolState.swapFee,
    roundedFee
  );

  const expectedRevenue = calculateExpectedRevenue(estimatedVolume, roundedFee);

  const confidence = calculateConfidence(marketData, poolState);

  // Build reasoning
  const reasoning = [
    `Volatility: ${(marketData.volatility * 100).toFixed(2)}% → ${volatilityFee.toFixed(0)} fee (weight: ${config.volatilityWeight})`,
    `Volume: ${marketData.volume24h.toString()} → ${volumeFee.toFixed(0)} fee (weight: ${config.volumeWeight})`,
    `Spread: ${(marketData.spread * 100).toFixed(2)}% → ${spreadFee.toFixed(0)} fee (weight: ${config.spreadWeight})`,
    `Weighted average: ${roundedFee}`,
    `Expected volume: ${estimatedVolume.toString()}`,
    `Expected revenue: ${expectedRevenue.toString()}`,
    `Confidence: ${(confidence * 100).toFixed(1)}%`
  ].join(' | ');

  return Right({
    fee: roundedFee,
    confidence,
    expectedVolume: estimatedVolume,
    expectedRevenue: { value: expectedRevenue },
    reasoning
  });
};

// ============================================================================
// Alternative Strategies
// ============================================================================

/**
 * Aggressive strategy: Maximize fees (good for low competition)
 */
export const aggressiveFeeStrategy = (input: FeeOptimizationInput): Result<string, OptimalFee> => {
  const modifiedConfig = {
    ...input.config,
    volatilityWeight: 0.6, // Emphasize volatility
    volumeWeight: 0.2,
    spreadWeight: 0.2
  };

  return calculateOptimalFee({ ...input, config: modifiedConfig });
};

/**
 * Conservative strategy: Attract volume with lower fees
 */
export const conservativeFeeStrategy = (input: FeeOptimizationInput): Result<string, OptimalFee> => {
  const modifiedConfig = {
    ...input.config,
    volatilityWeight: 0.2,
    volumeWeight: 0.6, // Emphasize volume attraction
    spreadWeight: 0.2
  };

  return calculateOptimalFee({ ...input, config: modifiedConfig });
};

/**
 * Adaptive strategy: Adjust based on market conditions
 */
export const adaptiveFeeStrategy = (input: FeeOptimizationInput): Result<string, OptimalFee> => {
  const { marketData } = input;

  // High volatility -> aggressive
  if (marketData.volatility > 0.5) {
    return aggressiveFeeStrategy(input);
  }

  // High volume growth -> conservative (keep it going)
  if (marketData.volumeChange > 20) {
    return conservativeFeeStrategy(input);
  }

  // Otherwise, balanced
  return calculateOptimalFee(input);
};

// ============================================================================
// Fee Optimization with Multiple Strategies
// ============================================================================

export interface StrategyResult {
  readonly strategy: string;
  readonly result: Result<string, OptimalFee>;
}

/**
 * Run multiple strategies and compare results
 */
export const runAllStrategies = (input: FeeOptimizationInput): readonly StrategyResult[] => {
  return [
    { strategy: 'balanced', result: calculateOptimalFee(input) },
    { strategy: 'aggressive', result: aggressiveFeeStrategy(input) },
    { strategy: 'conservative', result: conservativeFeeStrategy(input) },
    { strategy: 'adaptive', result: adaptiveFeeStrategy(input) }
  ];
};

/**
 * Select best strategy based on expected revenue
 */
export const selectBestStrategy = (
  strategies: readonly StrategyResult[]
): Result<string, OptimalFee> => {
  const validStrategies = strategies
    .filter(s => s.result.tag === 'Right')
    .map(s => ({ strategy: s.strategy, fee: s.result.right }));

  if (validStrategies.length === 0) {
    return Left('No valid strategies produced results');
  }

  // Select strategy with highest expected revenue
  const best = validStrategies.reduce((best, current) =>
    current.fee.expectedRevenue.value.gt(best.fee.expectedRevenue.value) ? current : best
  );

  return Right({
    ...best.fee,
    reasoning: `[${best.strategy}] ${best.fee.reasoning}`
  });
};

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Check if fee change is significant enough to warrant gas cost
 */
export const shouldUpdateFee = (
  currentFee: number,
  optimalFee: number,
  gasPrice: BigNumber,
  expectedRevenueDelta: BigNumber
): boolean => {
  const feeChangePct = Math.abs(optimalFee - currentFee) / currentFee;

  // Only update if change is > 5%
  if (feeChangePct < 0.05) return false;

  // Estimate gas cost (40k gas for setSwapFee)
  const gasCost = gasPrice.mul(40000);

  // Update if expected revenue gain exceeds gas cost by 2x
  return expectedRevenueDelta.gt(gasCost.mul(2));
};
