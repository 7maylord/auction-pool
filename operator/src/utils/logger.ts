/**
 * Logger configuration using Winston
 */

import winston from 'winston';
import { Logger } from '../core/types';

const LOG_LEVEL = process.env.LOG_LEVEL || 'info';
const LOG_FILE = process.env.LOG_FILE || './logs/operator.log';

// ============================================================================
// Winston Logger Configuration
// ============================================================================

const winstonLogger = winston.createLogger({
  level: LOG_LEVEL,
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json()
  ),
  defaultMeta: { service: 'auction-pool-operator' },
  transports: [
    // Console transport with colorized output
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.printf(({ level, message, timestamp, ...meta }) => {
          const metaStr = Object.keys(meta).length > 0
            ? `\n${JSON.stringify(meta, null, 2)}`
            : '';
          return `${timestamp} [${level}]: ${message}${metaStr}`;
        })
      )
    }),
    // File transport for persistent logs
    new winston.transports.File({
      filename: LOG_FILE,
      format: winston.format.json()
    }),
    // Separate error log
    new winston.transports.File({
      filename: './logs/error.log',
      level: 'error',
      format: winston.format.json()
    })
  ]
});

// ============================================================================
// Functional Logger Adapter
// ============================================================================

export const createLogger = (): Logger => ({
  debug: (message: string, meta?: unknown) => {
    winstonLogger.debug(message, meta);
  },

  info: (message: string, meta?: unknown) => {
    winstonLogger.info(message, meta);
  },

  warn: (message: string, meta?: unknown) => {
    winstonLogger.warn(message, meta);
  },

  error: (message: string, meta?: unknown) => {
    winstonLogger.error(message, meta);
  }
});

// ============================================================================
// Logger Utilities
// ============================================================================

/**
 * Create a child logger with additional context
 */
export const createChildLogger = (context: Record<string, unknown>): Logger => {
  const childLogger = winstonLogger.child(context);

  return {
    debug: (message: string, meta?: unknown) => {
      childLogger.debug(message, meta);
    },

    info: (message: string, meta?: unknown) => {
      childLogger.info(message, meta);
    },

    warn: (message: string, meta?: unknown) => {
      childLogger.warn(message, meta);
    },

    error: (message: string, meta?: unknown) => {
      childLogger.error(message, meta);
    }
  };
};

/**
 * Log execution time of a function
 */
export const withTiming = <A>(
  logger: Logger,
  label: string,
  f: () => A
): A => {
  const start = Date.now();
  try {
    const result = f();
    const duration = Date.now() - start;
    logger.debug(`${label} completed in ${duration}ms`);
    return result;
  } catch (error) {
    const duration = Date.now() - start;
    logger.error(`${label} failed after ${duration}ms`, { error });
    throw error;
  }
};

/**
 * Log execution time of an async function
 */
export const withTimingAsync = async <A>(
  logger: Logger,
  label: string,
  f: () => Promise<A>
): Promise<A> => {
  const start = Date.now();
  try {
    const result = await f();
    const duration = Date.now() - start;
    logger.debug(`${label} completed in ${duration}ms`);
    return result;
  } catch (error) {
    const duration = Date.now() - start;
    logger.error(`${label} failed after ${duration}ms`, { error });
    throw error;
  }
};
