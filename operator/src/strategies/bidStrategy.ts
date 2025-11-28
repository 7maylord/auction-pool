/**
 * Bid strategy engine - decides when and how much to bid
 * Pure functional implementation
 */

import { BigNumber } from 'ethers';
import {
  BidDecision,
  PoolState,
  MarketData,
  AuctionState,
  OptimalFee,
  Address,
  Wei,
  Result,
  Right,
  Left
} from '../core/types';

// ============================================================================
// Configuration
// ============================================================================

export interface BidStrategyConfig {
  readonly operatorAddress: Address;
  readonly minProfitMargin: number; // 0.0 to 1.0 (e.g., 0.001 = 0.1%)
  readonly maxBidAmountWei: BigNumber;
  readonly riskTolerance: number; // 0.0 to 1.0 (higher = more aggressive)
  readonly minDepositBlocks: number; // From hook contract
  readonly activationDelay: number; // From hook contract
}

export interface BidStrategyInput {
  readonly poolState: PoolState;
  readonly marketData: MarketData;
  readonly auctionState: AuctionState;
  readonly optimalFee: OptimalFee;
  readonly config: BidStrategyConfig;
  readonly currentBlockNumber: number;
  readonly gasPrice: BigNumber;
}

// ============================================================================
// Revenue Estimation (Pure Functions)
// ============================================================================

/**
 * Estimate swap fee revenue per block
 */
const estimateSwapFeeRevenue = (
  volume24h: BigNumber,
  fee: number
): BigNumber => {
  // Convert 24h volume to per-block volume (assuming 12s blocks = 7200 blocks/day)
  const volumePerBlock = volume24h.div(7200);

  // Revenue = volume * fee
  // fee is in hundredths of basis points (1/1,000,000)
  return volumePerBlock.mul(fee).div(1000000);
};

/**
 * Estimate withdrawal fee revenue per block
 * Assuming some % of liquidity is withdrawn per day
 */
const estimateWithdrawalFeeRevenue = (
  totalLiquidity: BigNumber,
  withdrawalFee: number = 10 // 0.01% = 10 in hundredths of basis points
): BigNumber => {
  // Assume 5% of liquidity withdrawn per day
  const dailyWithdrawals = totalLiquidity.mul(5).div(100);
  const withdrawalsPerBlock = dailyWithdrawals.div(7200);

  return withdrawalsPerBlock.mul(withdrawalFee).div(1000000);
};

/**
 * Estimate arbitrage revenue (manager trades fee-free)
 */
const estimateArbitrageRevenue = (
  volatility: number,
  liquidity: BigNumber
): BigNumber => {
  // Higher volatility = more arbitrage opportunities
  // Rough estimate: arbitrage revenue = volatility * liquidity * 0.1%
  const arbitrageFactor = Math.floor(volatility * 1000); // Scale volatility

  return liquidity
    .mul(arbitrageFactor)
    .div(1000) // Volatility scaling
    .mul(10).div(100000); // 0.01% capture rate
};

/**
 * Calculate total expected revenue per block
 */
const calculateExpectedRevenuePerBlock = (
  marketData: MarketData,
  poolState: PoolState,
  optimalFee: OptimalFee
): BigNumber => {
  const swapRevenue = estimateSwapFeeRevenue(
    optimalFee.expectedVolume,
    optimalFee.fee
  );

  const withdrawalRevenue = estimateWithdrawalFeeRevenue(poolState.liquidity);

  const arbitrageRevenue = estimateArbitrageRevenue(
    marketData.volatility,
    poolState.liquidity
  );

  return swapRevenue.add(withdrawalRevenue).add(arbitrageRevenue);
};

// ============================================================================
// Cost Estimation (Pure Functions)
// ============================================================================

/**
 * Calculate required deposit for a rent bid
 */
const calculateRequiredDeposit = (
  rentPerBlock: BigNumber,
  minDepositBlocks: number
): BigNumber => {
  return rentPerBlock.mul(minDepositBlocks);
};

/**
 * Estimate gas costs for manager operations
 */
const estimateOperationGasCosts = (
  gasPrice: BigNumber,
  activationDelay: number
): BigNumber => {
  // Estimate gas costs per block:
  // - Setting fees: ~40k gas, might do this every 10 blocks
  // - Withdrawing fees: ~100k gas, might do this every 100 blocks
  // - Average: ~4k gas per block

  const avgGasPerBlock = 4000;
  return gasPrice.mul(avgGasPerBlock);
};

/**
 * Calculate opportunity cost of locked deposit
 */
const calculateOpportunityCost = (
  deposit: BigNumber,
  annualYield: number = 0.05 // 5% APY
): BigNumber => {
  // Convert annual yield to per-block yield
  // Blocks per year = 365.25 * 24 * 60 * 60 / 12 = 2,628,000
  const blocksPerYear = 2628000;
  const yieldPerBlock = Math.floor((annualYield * 1e18) / blocksPerYear);

  return deposit.mul(yieldPerBlock).div(1e18);
};

/**
 * Calculate total expected costs per block
 */
const calculateExpectedCostPerBlock = (
  rentPerBlock: BigNumber,
  deposit: BigNumber,
  gasPrice: BigNumber,
  activationDelay: number
): BigNumber => {
  const rent = rentPerBlock;
  const gasCosts = estimateOperationGasCosts(gasPrice, activationDelay);
  const opportunityCost = calculateOpportunityCost(deposit);

  return rent.add(gasCosts).add(opportunityCost);
};

// ============================================================================
// Profit Calculation (Pure Functions)
// ============================================================================

/**
 * Calculate expected profit per block
 */
const calculateExpectedProfitPerBlock = (
  revenue: BigNumber,
  costs: BigNumber
): BigNumber => {
  return revenue.sub(costs);
};

/**
 * Calculate profit margin
 */
const calculateProfitMargin = (
  profit: BigNumber,
  revenue: BigNumber
): number => {
  if (revenue.isZero()) return 0;
  return profit.mul(10000).div(revenue).toNumber() / 10000;
};

/**
 * Estimate total profit over expected management period
 */
const estimateTotalProfit = (
  profitPerBlock: BigNumber,
  deposit: BigNumber,
  rentPerBlock: BigNumber
): BigNumber => {
  // Management period = deposit / rentPerBlock (blocks until deposit runs out)
  if (rentPerBlock.isZero()) return BigNumber.from(0);

  const managementPeriod = deposit.div(rentPerBlock);
  return profitPerBlock.mul(managementPeriod);
};

// ============================================================================
// Risk Assessment (Pure Functions)
// ============================================================================

/**
 * Calculate risk score based on multiple factors
 */
const calculateRiskScore = (
  marketData: MarketData,
  poolState: PoolState,
  auctionState: AuctionState,
  optimalFee: OptimalFee
): number => {
  let risk = 0;

  // High volatility = higher risk
  if (marketData.volatility > 0.5) risk += 0.3;
  else if (marketData.volatility > 0.3) risk += 0.15;

  // Low liquidity = higher risk
  const liquidityEth = parseFloat(poolState.liquidity.toString()) / 1e18;
  if (liquidityEth < 10) risk += 0.3;
  else if (liquidityEth < 50) risk += 0.15;

  // Low confidence in fee optimization = higher risk
  if (optimalFee.confidence < 0.5) risk += 0.2;
  else if (optimalFee.confidence < 0.7) risk += 0.1;

  // Active next bidder = competition risk
  if (auctionState.nextBidder !== null) risk += 0.1;

  // Declining volume = higher risk
  if (marketData.volumeChange < -20) risk += 0.2;

  return Math.min(1.0, risk);
};

// ============================================================================
// Bid Amount Calculation (Pure Functions)
// ============================================================================

/**
 * Calculate optimal rent bid amount
 */
const calculateOptimalRent = (
  currentRent: BigNumber,
  expectedProfit: BigNumber,
  riskScore: number,
  riskTolerance: number,
  minBidIncrement: BigNumber
): BigNumber => {
  // Start with current rent + minimum increment
  let bidRent = currentRent.add(minBidIncrement);

  // Adjust based on expected profit
  // Bid up to 50% of expected profit per block
  const maxBidIncrease = expectedProfit.div(2);

  // Adjust for risk (higher risk = lower bid)
  const riskMultiplier = Math.max(0.1, 1 - riskScore + riskTolerance);
  const riskAdjustedIncrease = maxBidIncrease.mul(Math.floor(riskMultiplier * 1000)).div(1000);

  bidRent = bidRent.add(riskAdjustedIncrease);

  // Round to reasonable value
  return bidRent;
};

// ============================================================================
// Main Bid Decision Function
// ============================================================================

/**
 * Decide whether to bid and calculate bid amount
 */
export const calculateBidDecision = (
  input: BidStrategyInput
): Result<string, BidDecision> => {
  const {
    poolState,
    marketData,
    auctionState,
    optimalFee,
    config,
    currentBlockNumber,
    gasPrice
  } = input;

  // Don't bid if we're already the current manager
  if (
    auctionState.currentManager?.value === config.operatorAddress.value
  ) {
    return Right({
      shouldBid: false,
      rentAmount: { value: BigNumber.from(0) },
      expectedProfit: { value: BigNumber.from(0) },
      profitMargin: 0,
      riskScore: 0,
      reasoning: 'Already the current manager'
    });
  }

  // Don't bid if we're the next bidder and activation is pending
  if (
    auctionState.nextBidder?.value === config.operatorAddress.value &&
    currentBlockNumber < auctionState.activationBlock.value
  ) {
    return Right({
      shouldBid: false,
      rentAmount: { value: BigNumber.from(0) },
      expectedProfit: { value: BigNumber.from(0) },
      profitMargin: 0,
      riskScore: 0,
      reasoning: 'Already the next bidder, waiting for activation'
    });
  }

  // Calculate expected revenue
  const expectedRevenue = calculateExpectedRevenuePerBlock(
    marketData,
    poolState,
    optimalFee
  );

  // Calculate risk score
  const riskScore = calculateRiskScore(marketData, poolState, auctionState, optimalFee);

  // Determine rent to bid
  const minBidIncrement = BigNumber.from(1); // From hook contract
  const currentRent = auctionState.nextBidder
    ? auctionState.nextRent.value
    : auctionState.currentRent.value;

  const proposedRent = calculateOptimalRent(
    currentRent,
    expectedRevenue,
    riskScore,
    config.riskTolerance,
    minBidIncrement
  );

  // Calculate required deposit
  const requiredDeposit = calculateRequiredDeposit(
    proposedRent,
    config.minDepositBlocks
  );

  // Check if deposit exceeds maximum
  if (requiredDeposit.gt(config.maxBidAmountWei)) {
    return Right({
      shouldBid: false,
      rentAmount: { value: proposedRent },
      expectedProfit: { value: BigNumber.from(0) },
      profitMargin: 0,
      riskScore,
      reasoning: `Required deposit (${requiredDeposit.toString()}) exceeds maximum (${config.maxBidAmountWei.toString()})`
    });
  }

  // Calculate expected costs
  const expectedCost = calculateExpectedCostPerBlock(
    proposedRent,
    requiredDeposit,
    gasPrice,
    config.activationDelay
  );

  // Calculate expected profit
  const profitPerBlock = calculateExpectedProfitPerBlock(expectedRevenue, expectedCost);
  const profitMargin = calculateProfitMargin(profitPerBlock, expectedRevenue);

  // Check minimum profit margin
  if (profitMargin < config.minProfitMargin) {
    return Right({
      shouldBid: false,
      rentAmount: { value: proposedRent },
      expectedProfit: { value: profitPerBlock },
      profitMargin,
      riskScore,
      reasoning: `Profit margin (${(profitMargin * 100).toFixed(2)}%) below minimum (${(config.minProfitMargin * 100).toFixed(2)}%)`
    });
  }

  // Estimate total profit
  const totalProfit = estimateTotalProfit(profitPerBlock, requiredDeposit, proposedRent);

  // Build reasoning
  const reasoning = [
    `Revenue: ${expectedRevenue.toString()} wei/block`,
    `Cost: ${expectedCost.toString()} wei/block (rent: ${proposedRent.toString()})`,
    `Profit: ${profitPerBlock.toString()} wei/block (${(profitMargin * 100).toFixed(2)}%)`,
    `Total expected: ${totalProfit.toString()} wei`,
    `Risk: ${(riskScore * 100).toFixed(1)}%`,
    `Confidence: ${(optimalFee.confidence * 100).toFixed(1)}%`
  ].join(' | ');

  return Right({
    shouldBid: true,
    rentAmount: { value: proposedRent },
    expectedProfit: { value: profitPerBlock },
    profitMargin,
    riskScore,
    reasoning
  });
};

// ============================================================================
// Alternative Bid Strategies
// ============================================================================

/**
 * Aggressive bidding: Higher rent to outcompete others
 */
export const aggressiveBidStrategy = (
  input: BidStrategyInput
): Result<string, BidDecision> => {
  const modifiedConfig = {
    ...input.config,
    riskTolerance: Math.min(1.0, input.config.riskTolerance + 0.3),
    minProfitMargin: input.config.minProfitMargin * 0.7 // Accept lower margin
  };

  return calculateBidDecision({ ...input, config: modifiedConfig });
};

/**
 * Conservative bidding: Lower rent, higher profit margin
 */
export const conservativeBidStrategy = (
  input: BidStrategyInput
): Result<string, BidDecision> => {
  const modifiedConfig = {
    ...input.config,
    riskTolerance: Math.max(0, input.config.riskTolerance - 0.3),
    minProfitMargin: input.config.minProfitMargin * 1.5 // Require higher margin
  };

  return calculateBidDecision({ ...input, config: modifiedConfig });
};

/**
 * Adaptive bidding: Adjust based on competition
 */
export const adaptiveBidStrategy = (
  input: BidStrategyInput
): Result<string, BidDecision> => {
  const { auctionState, marketData } = input;

  // If there's a next bidder (competition), be more aggressive
  if (auctionState.nextBidder !== null) {
    return aggressiveBidStrategy(input);
  }

  // If market is volatile, be conservative
  if (marketData.volatility > 0.5) {
    return conservativeBidStrategy(input);
  }

  // Otherwise, balanced
  return calculateBidDecision(input);
};
