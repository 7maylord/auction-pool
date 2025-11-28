/**
 * Main operator orchestration - coordinates all modules
 * Functional reactive approach
 */

import { Wallet, providers, BigNumber } from 'ethers';
import { filter, switchMap, tap } from 'rxjs/operators';
import { combineLatest, interval } from 'rxjs';

import { isRight } from './core/types';
import { createLogger, createChildLogger } from './utils/logger';
import { loadConfig, createOperatorConfig, validateConfig } from './utils/config';
import { createPoolMonitor } from './modules/poolMonitor';
import { createManagerOps, PoolKey } from './modules/managerOps';
import { calculateOptimalFee, selectBestStrategy, runAllStrategies, shouldUpdateFee } from './strategies/feeOptimization';
import { calculateBidDecision, adaptiveBidStrategy } from './strategies/bidStrategy';

// ============================================================================
// Main Operator
// ============================================================================

const main = async () => {
  const logger = createLogger();

  logger.info('='.repeat(80));
  logger.info('AuctionPool AVS Operator Starting');
  logger.info('='.repeat(80));

  // Load and validate configuration
  const configResult = loadConfig();
  if (!isRight(configResult)) {
    logger.error('Failed to load configuration', { error: configResult.left });
    process.exit(1);
  }

  const baseConfig = configResult.right;
  const config = createOperatorConfig(baseConfig);

  const validationResult = validateConfig(config);
  if (!isRight(validationResult)) {
    logger.error('Configuration validation failed', { error: validationResult.left });
    process.exit(1);
  }

  logger.info('Configuration loaded successfully', {
    chainId: config.network.chainId,
    poolManager: config.contracts.poolManager,
    hook: config.contracts.hook
  });

  // Initialize provider and wallet
  const provider = new providers.JsonRpcProvider(config.network.rpcUrl);
  const wallet = new Wallet(config.operator.privateKey, provider);
  const operatorAddress = await wallet.getAddress();

  logger.info('Operator initialized', { address: operatorAddress });

  // Initialize modules
  const poolMonitor = createPoolMonitor({
    provider,
    poolManagerAddress: config.contracts.poolManager,
    hookAddress: config.contracts.hook,
    refreshIntervalMs: config.monitoring.poolRefreshIntervalMs,
    logger: createChildLogger({ module: 'pool-monitor' })
  });

  const managerOps = createManagerOps({
    provider,
    wallet,
    hookAddress: config.contracts.hook,
    poolManagerAddress: config.contracts.poolManager,
    logger: createChildLogger({ module: 'manager-ops' }),
    gasMultiplier: config.gas.priceMultiplier
  });

  logger.info('All modules initialized');

  // ============================================================================
  // Pool Configuration (Mock - in production, fetch from registry)
  // ============================================================================

  const monitoredPools: Array<{ poolId: { value: string }; poolKey: PoolKey }> = [
    {
      poolId: { value: '0x...' }, // Would be actual pool ID
      poolKey: {
        currency0: '0x...', // Token0 address
        currency1: '0x...', // Token1 address
        fee: 3000, // 0.3%
        tickSpacing: 60,
        hooks: config.contracts.hook
      }
    }
  ];

  logger.info(`Monitoring ${monitoredPools.length} pools`);

  // ============================================================================
  // Operator Loop for Each Pool
  // ============================================================================

  for (const { poolId, poolKey } of monitoredPools) {
    const poolLogger = createChildLogger({ poolId: poolId.value });

    poolLogger.info('Starting pool monitoring');

    // Subscribe to pool updates
    const poolObservable = poolMonitor.observePool(poolId);

    poolObservable
      .pipe(
        // Filter out errors
        filter((result) => {
          if (!isRight(result)) {
            poolLogger.error('Pool observation error', { error: result.left });
            return false;
          }
          return true;
        }),

        // Process pool data
        tap((result) => {
          if (!isRight(result)) return;

          const { poolState, auctionState, marketData } = result.right;

          poolLogger.debug('Pool state updated', {
            manager: auctionState.currentManager?.value,
            rent: auctionState.currentRent.value.toString(),
            liquidity: poolState.liquidity.toString(),
            volatility: marketData.volatility.toFixed(4)
          });
        }),

        // Optimize fees (if we're the manager)
        switchMap(async (result) => {
          if (!isRight(result)) return;

          const { poolState, auctionState, marketData } = result.right;

          // Check if we're the current manager
          if (auctionState.currentManager?.value !== operatorAddress) {
            poolLogger.debug('Not the current manager, skipping fee optimization');
            return;
          }

          // Run fee optimization strategies
          const strategies = runAllStrategies({
            poolState,
            marketData,
            auctionState,
            config: config.optimization
          });

          const bestStrategy = selectBestStrategy(strategies);

          if (!isRight(bestStrategy)) {
            poolLogger.warn('Fee optimization failed', { error: bestStrategy.left });
            return;
          }

          const optimalFee = bestStrategy.right;

          poolLogger.info('Fee optimization complete', {
            currentFee: poolState.swapFee,
            optimalFee: optimalFee.fee,
            confidence: (optimalFee.confidence * 100).toFixed(1) + '%',
            reasoning: optimalFee.reasoning
          });

          // Check if fee update is warranted
          const feeData = await provider.getFeeData();
          const gasPrice = feeData.gasPrice || BigNumber.from('20000000000');

          const currentRevenue = poolState.liquidity
            .mul(poolState.swapFee)
            .div(1000000);

          const optimalRevenue = optimalFee.expectedRevenue.value;
          const revenueDelta = optimalRevenue.sub(currentRevenue);

          if (shouldUpdateFee(poolState.swapFee, optimalFee.fee, gasPrice, revenueDelta)) {
            poolLogger.info('Updating swap fee', {
              from: poolState.swapFee,
              to: optimalFee.fee
            });

            const updateResult = await managerOps.setSwapFee(poolKey, optimalFee.fee)();

            if (isRight(updateResult)) {
              poolLogger.info('Fee updated successfully', {
                txHash: updateResult.right.hash,
                gasUsed: updateResult.right.gasUsed.toString()
              });
            } else {
              poolLogger.error('Fee update failed', { error: updateResult.left });
            }
          } else {
            poolLogger.debug('Fee update not warranted', {
              reason: 'Change too small or not cost-effective'
            });
          }
        })
      )
      .subscribe();

    // ============================================================================
    // Bid Strategy Loop (runs independently)
    // ============================================================================

    combineLatest([
      poolObservable,
      interval(config.monitoring.updateFrequencyBlocks * 12000) // Check every N blocks
    ])
      .pipe(
        filter(([result]) => isRight(result)),
        switchMap(async ([result]) => {
          if (!isRight(result)) return;

          const { poolState, auctionState, marketData } = result.right;

          poolLogger.debug('Evaluating bid opportunity');

          // Run fee optimization to get expected revenue
          const feeStrategies = runAllStrategies({
            poolState,
            marketData,
            auctionState,
            config: config.optimization
          });

          const bestFee = selectBestStrategy(feeStrategies);
          if (!isRight(bestFee)) return;

          // Get current block and gas price
          const blockNumber = await provider.getBlockNumber();
          const feeData = await provider.getFeeData();
          const gasPrice = feeData.gasPrice || BigNumber.from('20000000000');

          // Calculate bid decision
          const bidResult = adaptiveBidStrategy({
            poolState,
            marketData,
            auctionState,
            optimalFee: bestFee.right,
            config: {
              operatorAddress: { value: operatorAddress },
              minProfitMargin: config.strategy.minProfitMargin,
              maxBidAmountWei: config.strategy.maxBidAmountWei,
              riskTolerance: config.strategy.riskTolerance,
              minDepositBlocks: 100, // From hook contract
              activationDelay: 5 // From hook contract
            },
            currentBlockNumber: blockNumber,
            gasPrice
          });

          if (!isRight(bidResult)) {
            poolLogger.warn('Bid calculation failed', { error: bidResult.left });
            return;
          }

          const decision = bidResult.right;

          poolLogger.info('Bid decision calculated', {
            shouldBid: decision.shouldBid,
            rent: decision.rentAmount.value.toString(),
            profitMargin: (decision.profitMargin * 100).toFixed(2) + '%',
            riskScore: (decision.riskScore * 100).toFixed(1) + '%',
            reasoning: decision.reasoning
          });

          if (decision.shouldBid) {
            poolLogger.info('Submitting bid', {
              rent: decision.rentAmount.value.toString()
            });

            const bidTxResult = await managerOps.submitBid(
              poolKey,
              decision.rentAmount
            )();

            if (isRight(bidTxResult)) {
              poolLogger.info('Bid submitted successfully', {
                txHash: bidTxResult.right.hash,
                blockNumber: bidTxResult.right.blockNumber,
                gasUsed: bidTxResult.right.gasUsed.toString()
              });
            } else {
              poolLogger.error('Bid submission failed', {
                error: bidTxResult.left
              });
            }
          }
        })
      )
      .subscribe();

    // ============================================================================
    // Fee Withdrawal Loop
    // ============================================================================

    interval(60000).pipe( // Check every minute
      switchMap(async () => {
        const feesResult = await managerOps.checkManagerFees(
          poolId,
          { value: operatorAddress }
        )();

        if (!isRight(feesResult)) return;

        const accumulatedFees = feesResult.right;

        if (accumulatedFees.value.isZero()) return;

        poolLogger.debug('Accumulated fees', {
          amount: accumulatedFees.value.toString()
        });

        // Check if withdrawal is profitable
        const feeData = await provider.getFeeData();
        const gasPrice = feeData.gasPrice || BigNumber.from('20000000000');

        const estimatedGas = BigNumber.from(100000);
        const gasCost = gasPrice.mul(estimatedGas);

        if (accumulatedFees.value.gte(gasCost.mul(2))) {
          poolLogger.info('Withdrawing manager fees', {
            amount: accumulatedFees.value.toString()
          });

          const withdrawResult = await managerOps.withdrawManagerFees(poolKey)();

          if (isRight(withdrawResult)) {
            poolLogger.info('Fees withdrawn successfully', {
              txHash: withdrawResult.right.hash
            });
          } else {
            poolLogger.error('Fee withdrawal failed', {
              error: withdrawResult.left
            });
          }
        }
      })
    ).subscribe();
  }

  // ============================================================================
  // Health Check Loop
  // ============================================================================

  interval(config.monitoring.healthCheckIntervalMs).subscribe(async () => {
    const balanceResult = await managerOps.getBalance()();

    if (isRight(balanceResult)) {
      const balance = balanceResult.right.value;
      const balanceEth = parseFloat(balance.toString()) / 1e18;

      logger.info('Health check', {
        balance: balanceEth.toFixed(4) + ' ETH',
        timestamp: new Date().toISOString()
      });

      if (balanceEth < 0.1) {
        logger.warn('Low balance warning', { balance: balanceEth });
      }
    }
  });

  logger.info('Operator running. Press Ctrl+C to stop.');
};

// ============================================================================
// Entry Point
// ============================================================================

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\nShutting down gracefully...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\nShutting down gracefully...');
  process.exit(0);
});
