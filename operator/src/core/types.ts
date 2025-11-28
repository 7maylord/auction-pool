/**
 * Core types for AVS Operator using functional programming principles
 */

import { BigNumber } from 'ethers';
import * as t from 'io-ts';

// ============================================================================
// Domain Types
// ============================================================================

export interface PoolId {
  readonly value: string;
}

export interface Address {
  readonly value: string;
}

export interface Wei {
  readonly value: BigNumber;
}

export interface Percentage {
  readonly value: number; // 0.0 to 1.0
}

export interface BlockNumber {
  readonly value: number;
}

// ============================================================================
// Pool State
// ============================================================================

export interface PoolState {
  readonly poolId: PoolId;
  readonly token0: Address;
  readonly token1: Address;
  readonly currentManager: Address | null;
  readonly rentPerBlock: Wei;
  readonly swapFee: number; // in hundredths of basis points
  readonly liquidity: BigNumber;
  readonly sqrtPriceX96: BigNumber;
  readonly tick: number;
  readonly lastUpdateBlock: BlockNumber;
}

// ============================================================================
// Market Data
// ============================================================================

export interface MarketData {
  readonly poolId: PoolId;
  readonly timestamp: number;
  readonly volatility: number; // 24h historical volatility
  readonly volume24h: BigNumber;
  readonly volumeChange: number; // % change from previous period
  readonly priceChange: number; // % price change
  readonly spread: number; // bid-ask spread
  readonly trades: number; // number of trades in period
}

// ============================================================================
// Auction State
// ============================================================================

export interface AuctionState {
  readonly currentManager: Address | null;
  readonly currentRent: Wei;
  readonly nextBidder: Address | null;
  readonly nextRent: Wei;
  readonly activationBlock: BlockNumber;
  readonly managerDeposit: Wei;
}

// ============================================================================
// Operator State
// ============================================================================

export interface OperatorState {
  readonly address: Address;
  readonly isRegistered: boolean;
  readonly stake: Wei;
  readonly managedPools: readonly PoolId[];
  readonly totalFeesCollected: Wei;
  readonly totalRentPaid: Wei;
  readonly profitLoss: Wei;
}

// ============================================================================
// Fee Optimization Input
// ============================================================================

export interface FeeOptimizationInput {
  readonly poolState: PoolState;
  readonly marketData: MarketData;
  readonly auctionState: AuctionState;
  readonly config: OptimizationConfig;
}

export interface OptimizationConfig {
  readonly volatilityWeight: number;
  readonly volumeWeight: number;
  readonly spreadWeight: number;
  readonly minFee: number;
  readonly maxFee: number;
}

// ============================================================================
// Optimization Results
// ============================================================================

export interface OptimalFee {
  readonly fee: number; // in hundredths of basis points
  readonly confidence: number; // 0.0 to 1.0
  readonly expectedVolume: BigNumber;
  readonly expectedRevenue: Wei;
  readonly reasoning: string;
}

export interface BidDecision {
  readonly shouldBid: boolean;
  readonly rentAmount: Wei;
  readonly expectedProfit: Wei;
  readonly profitMargin: number;
  readonly riskScore: number; // 0.0 to 1.0
  readonly reasoning: string;
}

// ============================================================================
// Manager Operations
// ============================================================================

export interface ManagerOperation {
  readonly type: 'SET_FEE' | 'WITHDRAW_FEES' | 'EXECUTE_ARBITRAGE';
  readonly poolId: PoolId;
  readonly params: unknown;
  readonly estimatedGas: BigNumber;
  readonly priority: number; // 0-10, higher = more urgent
}

// ============================================================================
// Events
// ============================================================================

export interface PoolEvent {
  readonly type: 'SWAP' | 'ADD_LIQUIDITY' | 'REMOVE_LIQUIDITY' | 'BID_SUBMITTED' | 'MANAGER_CHANGED';
  readonly poolId: PoolId;
  readonly blockNumber: BlockNumber;
  readonly transactionHash: string;
  readonly data: unknown;
}

// ============================================================================
// Result Type (Either monad)
// ============================================================================

export type Result<E, A> =
  | { readonly tag: 'Left'; readonly left: E }
  | { readonly tag: 'Right'; readonly right: A };

export const Left = <E, A>(left: E): Result<E, A> => ({ tag: 'Left', left });
export const Right = <E, A>(right: A): Result<E, A> => ({ tag: 'Right', right });

export const isLeft = <E, A>(result: Result<E, A>): result is { tag: 'Left'; left: E } =>
  result.tag === 'Left';

export const isRight = <E, A>(result: Result<E, A>): result is { tag: 'Right'; right: A } =>
  result.tag === 'Right';

// ============================================================================
// Option Type (Maybe monad)
// ============================================================================

export type Option<A> =
  | { readonly tag: 'None' }
  | { readonly tag: 'Some'; readonly value: A };

export const None = <A>(): Option<A> => ({ tag: 'None' });
export const Some = <A>(value: A): Option<A> => ({ tag: 'Some', value });

export const isSome = <A>(option: Option<A>): option is { tag: 'Some'; value: A } =>
  option.tag === 'Some';

export const isNone = <A>(option: Option<A>): option is { tag: 'None' } =>
  option.tag === 'None';

// ============================================================================
// Task Type (Async computation)
// ============================================================================

export type Task<A> = () => Promise<A>;

export type TaskEither<E, A> = Task<Result<E, A>>;

// ============================================================================
// Logger Type
// ============================================================================

export interface Logger {
  readonly debug: (message: string, meta?: unknown) => void;
  readonly info: (message: string, meta?: unknown) => void;
  readonly warn: (message: string, meta?: unknown) => void;
  readonly error: (message: string, meta?: unknown) => void;
}

// ============================================================================
// Runtime Validators (using io-ts)
// ============================================================================

export const AddressCodec = t.type({
  value: t.string
});

export const PoolIdCodec = t.type({
  value: t.string
});

export const ConfigCodec = t.type({
  rpcUrl: t.string,
  chainId: t.number,
  operatorPrivateKey: t.string,
  poolManagerAddress: t.string,
  hookAddress: t.string,
  minProfitMargin: t.number,
  maxBidAmountEth: t.number,
  volatilityWeight: t.number,
  volumeWeight: t.number,
  spreadWeight: t.number
});

export type Config = t.TypeOf<typeof ConfigCodec>;
