import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Codigos do Firestore que podem ser re-tentados com seguranca (erros de rede/servidor).
const _defaultRetryableCodes = <String>{
  'unavailable',
  'deadline-exceeded',
  'resource-exhausted',
  'aborted',
  'cancelled',
};

/// Politicas de retry pre-construidas para operacoes do Firestore.
class RetryPolicy {
  RetryPolicy({
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 5),
    this.backoffMultiplier = 2.0,
    this.retryableCodes = _defaultRetryableCodes,
    this.attemptTimeout = const Duration(seconds: 8),
    this.maxTotalDuration = const Duration(seconds: 30),
  });

  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final Set<String> retryableCodes;
  final Duration attemptTimeout;
  final Duration maxTotalDuration;

  /// Retry padrao para operacoes de configuracao e leitura.
  static final standard = RetryPolicy();

  /// Retry agressivo para operacoes financeiras criticas.
  static final critical = RetryPolicy(
    maxRetries: 4,
    baseDelay: const Duration(milliseconds: 300),
    maxDelay: const Duration(seconds: 8),
    attemptTimeout: const Duration(seconds: 6),
    maxTotalDuration: const Duration(seconds: 20),
  );

  /// Delay calculado com exponential backoff + jitter.
  Duration _delayForAttempt(int attempt) {
    final backoff = baseDelay * backoffMultiplier.pow(attempt);
    final capped = backoff < maxDelay ? backoff : maxDelay;
    final jitterBase = (capped.inMilliseconds * 0.2).toInt();
    final jitterModulo = jitterBase <= 0 ? 1 : jitterBase;
    final jitter = Duration(
      milliseconds:
          (capped.inMilliseconds * 0.1).toInt() +
          (DateTime.now().millisecondsSinceEpoch % jitterModulo),
    );
    return capped + jitter;
  }

  bool _isRetryable(Object error) {
    if (error is! FirebaseException) return false;
    if (error.code.isEmpty) return false;
    return retryableCodes.contains(error.code);
  }

  FirebaseException _buildTimeoutException() {
    return FirebaseException(
      plugin: 'cloud_firestore',
      code: 'deadline-exceeded',
      message: 'Tempo limite excedido ao sincronizar com o servidor.',
    );
  }

  bool _wouldExceedTotalDuration(DateTime startedAt, Duration nextDelay) {
    final elapsed = DateTime.now().difference(startedAt);
    return elapsed + nextDelay >= maxTotalDuration;
  }

  /// Executa [action] com retry conforme a politica.
  Future<T> execute<T>(Future<T> Function() action) async {
    int attempt = 0;
    final startedAt = DateTime.now();
    while (true) {
      try {
        return await action().timeout(attemptTimeout);
      } on TimeoutException {
        if (attempt >= maxRetries) {
          throw _buildTimeoutException();
        }
      } catch (e) {
        if (attempt >= maxRetries || !_isRetryable(e)) rethrow;
      }

      final delay = _delayForAttempt(attempt);
      if (_wouldExceedTotalDuration(startedAt, delay)) {
        throw _buildTimeoutException();
      }
      await Future.delayed(delay);
      attempt++;
    }
  }
}

extension on double {
  double pow(int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= this;
    }
    return result;
  }
}
