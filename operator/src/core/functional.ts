/**
 * Core functional utilities and combinators
 */

import { Result, Left, Right, isRight, Option, Some, None, isSome, Task, TaskEither } from './types';

// ============================================================================
// Function Composition
// ============================================================================

export const pipe = <A, B, C>(f: (a: A) => B, g: (b: B) => C) => (a: A): C => g(f(a));

export const compose = <A, B, C>(g: (b: B) => C, f: (a: A) => B) => (a: A): C => g(f(a));

export const identity = <A>(a: A): A => a;

// ============================================================================
// Result (Either) Utilities
// ============================================================================

export const map = <E, A, B>(f: (a: A) => B) => (result: Result<E, A>): Result<E, B> =>
  isRight(result) ? Right(f(result.right)) : result;

export const flatMap = <E, A, B>(f: (a: A) => Result<E, B>) => (result: Result<E, A>): Result<E, B> =>
  isRight(result) ? f(result.right) : result;

export const mapLeft = <E, A, F>(f: (e: E) => F) => (result: Result<E, A>): Result<F, A> =>
  isRight(result) ? result : Left(f(result.left));

export const fold = <E, A, B>(onLeft: (e: E) => B, onRight: (a: A) => B) => (result: Result<E, A>): B =>
  isRight(result) ? onRight(result.right) : onLeft(result.left);

export const getOrElse = <E, A>(defaultValue: A) => (result: Result<E, A>): A =>
  isRight(result) ? result.right : defaultValue;

export const tryCatch = <E, A>(f: () => A, onError: (error: unknown) => E): Result<E, A> => {
  try {
    return Right(f());
  } catch (error) {
    return Left(onError(error));
  }
};

// ============================================================================
// Option (Maybe) Utilities
// ============================================================================

export const mapOption = <A, B>(f: (a: A) => B) => (option: Option<A>): Option<B> =>
  isSome(option) ? Some(f(option.value)) : None();

export const flatMapOption = <A, B>(f: (a: A) => Option<B>) => (option: Option<A>): Option<B> =>
  isSome(option) ? f(option.value) : None();

export const getOrElseOption = <A>(defaultValue: A) => (option: Option<A>): A =>
  isSome(option) ? option.value : defaultValue;

export const fromNullable = <A>(value: A | null | undefined): Option<A> =>
  value != null ? Some(value) : None();

// ============================================================================
// Task Utilities
// ============================================================================

export const taskOf = <A>(value: A): Task<A> => async () => value;

export const taskMap = <A, B>(f: (a: A) => B) => (task: Task<A>): Task<B> =>
  async () => f(await task());

export const taskFlatMap = <A, B>(f: (a: A) => Task<B>) => (task: Task<A>): Task<B> =>
  async () => {
    const a = await task();
    return await f(a)();
  };

// ============================================================================
// TaskEither Utilities
// ============================================================================

export const taskEitherOf = <E, A>(value: A): TaskEither<E, A> =>
  async () => Right(value);

export const taskEitherLeft = <E, A>(error: E): TaskEither<E, A> =>
  async () => Left(error);

export const taskEitherMap = <E, A, B>(f: (a: A) => B) =>
  (task: TaskEither<E, A>): TaskEither<E, B> =>
    async () => {
      const result = await task();
      return map(f)(result);
    };

export const taskEitherFlatMap = <E, A, B>(f: (a: A) => TaskEither<E, B>) =>
  (task: TaskEither<E, A>): TaskEither<E, B> =>
    async () => {
      const result = await task();
      if (isRight(result)) {
        return await f(result.right)();
      }
      return result;
    };

export const taskEitherTryCatch = <E, A>(
  task: Task<A>,
  onError: (error: unknown) => E
): TaskEither<E, A> =>
  async () => {
    try {
      const result = await task();
      return Right(result);
    } catch (error) {
      return Left(onError(error));
    }
  };

// ============================================================================
// Array Utilities (Functional)
// ============================================================================

export const arrayMap = <A, B>(f: (a: A) => B) => (arr: readonly A[]): readonly B[] =>
  arr.map(f);

export const arrayFilter = <A>(predicate: (a: A) => boolean) => (arr: readonly A[]): readonly A[] =>
  arr.filter(predicate);

export const arrayReduce = <A, B>(f: (acc: B, a: A) => B, initial: B) => (arr: readonly A[]): B =>
  arr.reduce(f, initial);

export const arrayFind = <A>(predicate: (a: A) => boolean) => (arr: readonly A[]): Option<A> =>
  fromNullable(arr.find(predicate));

export const arraySequenceResults = <E, A>(
  arr: readonly Result<E, A>[]
): Result<E, readonly A[]> => {
  const results: A[] = [];
  for (const result of arr) {
    if (isRight(result)) {
      results.push(result.right);
    } else {
      return result;
    }
  }
  return Right(results);
};

export const arraySequenceTasks = <A>(tasks: readonly Task<A>[]): Task<readonly A[]> =>
  async () => await Promise.all(tasks.map(task => task()));

// ============================================================================
// Validation Utilities
// ============================================================================

export const validate = <A>(
  predicate: (a: A) => boolean,
  error: string
) => (value: A): Result<string, A> =>
  predicate(value) ? Right(value) : Left(error);

export const validateAll = <A>(
  validators: readonly ((a: A) => Result<string, A>)[]
) => (value: A): Result<string, A> => {
  for (const validator of validators) {
    const result = validator(value);
    if (!isRight(result)) {
      return result;
    }
  }
  return Right(value);
};

// ============================================================================
// Retry Logic
// ============================================================================

export const retry = <E, A>(
  task: TaskEither<E, A>,
  maxAttempts: number,
  delayMs: number
): TaskEither<E, A> =>
  async () => {
    let lastError: E | null = null;

    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      const result = await task();
      if (isRight(result)) {
        return result;
      }

      lastError = result.left;

      if (attempt < maxAttempts - 1) {
        await new Promise(resolve => setTimeout(resolve, delayMs));
      }
    }

    return Left(lastError as E);
  };

// ============================================================================
// Memoization
// ============================================================================

export const memoize = <A, B>(f: (a: A) => B): ((a: A) => B) => {
  const cache = new Map<A, B>();
  return (a: A): B => {
    if (cache.has(a)) {
      return cache.get(a)!;
    }
    const result = f(a);
    cache.set(a, result);
    return result;
  };
};

// ============================================================================
// Debounce/Throttle
// ============================================================================

export const debounce = <A extends unknown[]>(
  f: (...args: A) => void,
  delayMs: number
): ((...args: A) => void) => {
  let timeoutId: NodeJS.Timeout | null = null;

  return (...args: A): void => {
    if (timeoutId) {
      clearTimeout(timeoutId);
    }
    timeoutId = setTimeout(() => f(...args), delayMs);
  };
};

export const throttle = <A extends unknown[]>(
  f: (...args: A) => void,
  intervalMs: number
): ((...args: A) => void) => {
  let lastCall = 0;

  return (...args: A): void => {
    const now = Date.now();
    if (now - lastCall >= intervalMs) {
      lastCall = now;
      f(...args);
    }
  };
};
