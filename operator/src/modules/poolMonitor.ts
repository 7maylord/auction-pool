/**
 * Pool monitoring module using functional reactive programming
 */

import { BigNumber, Contract, providers } from 'ethers';
import { Observable, interval, from, combineLatest } from 'rxjs';
import { map, switchMap, distinctUntilChanged, shareReplay, catchError, retry } from 'rxjs/operators';
import {
  PoolState,
  MarketData,
  AuctionState,
  PoolId,
  Address,
  Wei,
  BlockNumber,
  Logger,
  Result,
  Right,
  Left,
  TaskEither,
  taskEitherTryCatch
} from '../core/types';
import { pipe } from '../core/functional';

// ============================================================================
// Pool Monitor Configuration
// ============================================================================

export interface PoolMonitorConfig {
  readonly provider: providers.Provider;
  readonly poolManagerAddress: string;
  readonly hookAddress: string;
  readonly refreshIntervalMs: number;
  readonly logger: Logger;
}

// ============================================================================
// Pure Functions for Data Transformation
// ============================================================================

const calculateVolatility = (prices: readonly BigNumber[]): number => {
  if (prices.length < 2) return 0;

  const returns = prices.slice(1).map((price, i) =>
    Math.log(price.toBigInt() / prices[i].toBigInt())
  );

  const mean = returns.reduce((sum, r) => sum + r, 0) / returns.length;
  const variance = returns.reduce((sum, r) => sum + Math.pow(r - mean, 2), 0) / returns.length;

  return Math.sqrt(variance * 365); // Annualized volatility
};

const calculateSpread = (bestBid: BigNumber, bestAsk: BigNumber): number => {
  if (bestBid.isZero() || bestAsk.isZero()) return 0;
  return bestAsk.sub(bestBid).mul(10000).div(bestBid).toNumber() / 10000;
};

const calculatePriceChange = (currentPrice: BigNumber, previousPrice: BigNumber): number => {
  if (previousPrice.isZero()) return 0;
  return currentPrice.sub(previousPrice).mul(10000).div(previousPrice).toNumber() / 10000;
};

// ============================================================================
// Contract Interface Functions
// ============================================================================

const createPoolStateReader = (
  provider: providers.Provider,
  poolManagerAddress: string,
  hookAddress: string,
  logger: Logger
) => {
  const poolManagerAbi = [
    'function getSlot0(bytes32 poolId) external view returns (uint160 sqrtPriceX96, int24 tick, uint24 protocolFee)',
    'function getLiquidity(bytes32 poolId) external view returns (uint128)',
  ];

  const hookAbi = [
    'function poolAuctions(bytes32) external view returns (address currentManager, uint256 rentPerBlock, uint256 managerDeposit, uint256 lastRentBlock, uint256 totalRentCollected, uint24 currentFee)',
    'function nextBid(bytes32) external view returns (address bidder, uint256 rentPerBlock, uint256 deposit, uint256 activationBlock, uint256 timestamp)',
  ];

  const poolManager = new Contract(poolManagerAddress, poolManagerAbi, provider);
  const hook = new Contract(hookAddress, hookAbi, provider);

  return {
    getPoolState: (poolId: PoolId): TaskEither<string, PoolState> =>
      taskEitherTryCatch(
        async () => {
          logger.debug(`Fetching pool state for ${poolId.value}`);

          const [slot0, liquidity, auction] = await Promise.all([
            poolManager.getSlot0(poolId.value),
            poolManager.getLiquidity(poolId.value),
            hook.poolAuctions(poolId.value)
          ]);

          const blockNumber = await provider.getBlockNumber();

          return {
            poolId,
            token0: { value: '0x...' }, // Would extract from pool key
            token1: { value: '0x...' },
            currentManager: auction.currentManager !== '0x0000000000000000000000000000000000000000'
              ? { value: auction.currentManager }
              : null,
            rentPerBlock: { value: auction.rentPerBlock },
            swapFee: auction.currentFee,
            liquidity,
            sqrtPriceX96: slot0.sqrtPriceX96,
            tick: slot0.tick,
            lastUpdateBlock: { value: blockNumber }
          };
        },
        (error) => `Failed to fetch pool state: ${error}`
      ),

    getAuctionState: (poolId: PoolId): TaskEither<string, AuctionState> =>
      taskEitherTryCatch(
        async () => {
          logger.debug(`Fetching auction state for ${poolId.value}`);

          const [auction, next] = await Promise.all([
            hook.poolAuctions(poolId.value),
            hook.nextBid(poolId.value)
          ]);

          return {
            currentManager: auction.currentManager !== '0x0000000000000000000000000000000000000000'
              ? { value: auction.currentManager }
              : null,
            currentRent: { value: auction.rentPerBlock },
            nextBidder: next.bidder !== '0x0000000000000000000000000000000000000000'
              ? { value: next.bidder }
              : null,
            nextRent: { value: next.rentPerBlock },
            activationBlock: { value: next.activationBlock },
            managerDeposit: { value: auction.managerDeposit }
          };
        },
        (error) => `Failed to fetch auction state: ${error}`
      )
  };
};

// ============================================================================
// Market Data Calculation (Pure)
// ============================================================================

const createMarketDataCalculator = (logger: Logger) => {
  const priceHistory = new Map<string, BigNumber[]>();
  const volumeHistory = new Map<string, BigNumber[]>();

  return (poolId: PoolId, poolState: PoolState): MarketData => {
    const poolIdStr = poolId.value;

    // Update price history
    const prices = priceHistory.get(poolIdStr) || [];
    prices.push(poolState.sqrtPriceX96);
    if (prices.length > 100) prices.shift(); // Keep last 100 prices
    priceHistory.set(poolIdStr, prices);

    // Calculate metrics
    const volatility = calculateVolatility(prices);
    const priceChange = prices.length > 1
      ? calculatePriceChange(prices[prices.length - 1], prices[prices.length - 2])
      : 0;

    // Mock volume data - in production, fetch from events/subgraph
    const volume24h = BigNumber.from('1000000000000000000'); // 1 ETH
    const volumes = volumeHistory.get(poolIdStr) || [];
    volumes.push(volume24h);
    if (volumes.length > 24) volumes.shift();
    volumeHistory.set(poolIdStr, volumes);

    const volumeChange = volumes.length > 1
      ? volumes[volumes.length - 1].sub(volumes[volumes.length - 2]).mul(100).div(volumes[volumes.length - 2]).toNumber()
      : 0;

    return {
      poolId,
      timestamp: Date.now(),
      volatility,
      volume24h,
      volumeChange,
      priceChange,
      spread: 0.001, // Mock spread
      trades: 100 // Mock trade count
    };
  };
};

// ============================================================================
// Observable Streams (Reactive)
// ============================================================================

export const createPoolMonitor = (config: PoolMonitorConfig) => {
  const { provider, poolManagerAddress, hookAddress, refreshIntervalMs, logger } = config;

  const reader = createPoolStateReader(provider, poolManagerAddress, hookAddress, logger);
  const marketDataCalc = createMarketDataCalculator(logger);

  return {
    /**
     * Create an observable stream of pool state updates
     */
    observePoolState: (poolId: PoolId): Observable<Result<string, PoolState>> =>
      interval(refreshIntervalMs).pipe(
        switchMap(() => from(reader.getPoolState(poolId)())),
        distinctUntilChanged((a, b) => {
          if (a.tag !== b.tag) return false;
          if (a.tag === 'Left') return true;
          return a.right.lastUpdateBlock.value === b.right.lastUpdateBlock.value;
        }),
        retry(3),
        catchError((error) => {
          logger.error('Error observing pool state', { error, poolId: poolId.value });
          return from([Left(`Error: ${error}`)]);
        }),
        shareReplay(1)
      ),

    /**
     * Create an observable stream of auction state updates
     */
    observeAuctionState: (poolId: PoolId): Observable<Result<string, AuctionState>> =>
      interval(refreshIntervalMs).pipe(
        switchMap(() => from(reader.getAuctionState(poolId)())),
        distinctUntilChanged((a, b) => JSON.stringify(a) === JSON.stringify(b)),
        retry(3),
        catchError((error) => {
          logger.error('Error observing auction state', { error, poolId: poolId.value });
          return from([Left(`Error: ${error}`)]);
        }),
        shareReplay(1)
      ),

    /**
     * Create an observable stream of market data
     */
    observeMarketData: (poolId: PoolId): Observable<Result<string, MarketData>> =>
      interval(refreshIntervalMs).pipe(
        switchMap(() => from(reader.getPoolState(poolId)())),
        map((result) => {
          if (result.tag === 'Left') return result;
          return Right(marketDataCalc(poolId, result.right));
        }),
        retry(3),
        catchError((error) => {
          logger.error('Error observing market data', { error, poolId: poolId.value });
          return from([Left(`Error: ${error}`)]);
        }),
        shareReplay(1)
      ),

    /**
     * Combine all observations into a single stream
     */
    observePool: (poolId: PoolId): Observable<Result<string, {
      poolState: PoolState;
      auctionState: AuctionState;
      marketData: MarketData;
    }>> => {
      const poolState$ = interval(refreshIntervalMs).pipe(
        switchMap(() => from(reader.getPoolState(poolId)()))
      );

      const auctionState$ = interval(refreshIntervalMs).pipe(
        switchMap(() => from(reader.getAuctionState(poolId)()))
      );

      return combineLatest([poolState$, auctionState$]).pipe(
        map(([poolStateResult, auctionStateResult]) => {
          if (poolStateResult.tag === 'Left') return poolStateResult;
          if (auctionStateResult.tag === 'Left') return auctionStateResult;

          const marketData = marketDataCalc(poolId, poolStateResult.right);

          return Right({
            poolState: poolStateResult.right,
            auctionState: auctionStateResult.right,
            marketData
          });
        }),
        retry(3),
        catchError((error) => {
          logger.error('Error observing pool', { error, poolId: poolId.value });
          return from([Left(`Error: ${error}`)]);
        }),
        shareReplay(1)
      );
    }
  };
};

// ============================================================================
// Type Exports
// ============================================================================

export type PoolMonitor = ReturnType<typeof createPoolMonitor>;
