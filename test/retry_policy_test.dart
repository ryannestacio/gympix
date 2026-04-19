import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/core/utils/firestore_retry_policy.dart';

FirebaseException _makeException(String code) {
  return FirebaseException(plugin: 'cloud_firestore', code: code);
}

void main() {
  group('RetryPolicy - construtores estaticos', () {
    test('standard tem valores padrao corretos', () {
      expect(RetryPolicy.standard.maxRetries, 3);
      expect(RetryPolicy.standard.baseDelay, const Duration(milliseconds: 500));
      expect(RetryPolicy.standard.backoffMultiplier, 2.0);
    });

    test('critical tem valores mais agressivos', () {
      expect(RetryPolicy.critical.maxRetries, 4);
      expect(RetryPolicy.critical.baseDelay, const Duration(milliseconds: 300));
    });
  });

  group('RetryPolicy.execute', () {
    test('retorna com sucesso na primeira tentativa', () async {
      final policy = RetryPolicy(maxRetries: 3);
      int callCount = 0;
      final result = await policy.execute(() async {
        callCount++;
        return 'OK';
      });

      expect(result, 'OK');
      expect(callCount, 1);
    });

    test('rethrow para erro nao-retryable sem delay', () async {
      final policy = RetryPolicy(maxRetries: 3);

      expect(
        () async => policy.execute(() async {
          throw _makeException('invalid-argument');
        }),
        throwsA(isA<FirebaseException>()),
      );
    });

    test('rethrow erro nao-FirebaseException sem retry', () async {
      final policy = RetryPolicy(maxRetries: 3);

      expect(
        () async => policy.execute(() async {
          throw Exception('Generic error');
        }),
        throwsA(isA<Exception>()),
      );
    });

    test('retorna com sucesso apos falhas intermediarias retryable', () async {
      int attempt = 0;
      final policy = RetryPolicy(
        maxRetries: 3,
        baseDelay: const Duration(milliseconds: 50),
        backoffMultiplier: 1.0,
        maxDelay: const Duration(seconds: 1),
      );

      final result = await policy.execute<String>(() async {
        attempt++;
        if (attempt < 3) {
          throw _makeException('unavailable');
        }
        return 'success';
      });

      expect(result, 'success');
    });

    test('rethrow apos esgotar maxRetries para erro retryable', () async {
      int attempt = 0;
      final policy = RetryPolicy(
        maxRetries: 2,
        baseDelay: const Duration(milliseconds: 50),
        backoffMultiplier: 1.0,
        maxDelay: const Duration(seconds: 1),
      );

      await expectLater(
        () async => policy.execute<String>(() async {
          attempt++;
          throw _makeException('unavailable');
        }),
        throwsA(isA<FirebaseException>()),
      );
      expect(attempt, 3);
    });

    test('nao retenta se o codigo estiver vazio', () async {
      final policy = RetryPolicy(maxRetries: 3);

      expect(
        () async => policy.execute(() async {
          throw _makeException('');
        }),
        throwsA(isA<FirebaseException>()),
      );
    });
  });
}
