import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/core/utils/firestore_sync_status.dart';

FirebaseException _makeException(String code) {
  return FirebaseException(plugin: 'cloud_firestore', code: code);
}

void main() {
  group('waitForPendingWritesSyncStatus', () {
    test('retorna synced quando pendencias sao confirmadas', () async {
      final result = await waitForPendingWritesSyncStatus(
        waitForPendingWrites: () async {},
      );

      expect(result, FirestoreSyncState.synced);
    });

    test('retorna pending quando estoura timeout', () async {
      final result = await waitForPendingWritesSyncStatus(
        waitForPendingWrites: () async {
          await Future<void>.delayed(const Duration(milliseconds: 40));
        },
        timeout: const Duration(milliseconds: 5),
      );

      expect(result, FirestoreSyncState.pending);
    });

    test('retorna pending para erro de rede/sincronizacao', () async {
      final result = await waitForPendingWritesSyncStatus(
        waitForPendingWrites: () async {
          throw _makeException('unavailable');
        },
      );

      expect(result, FirestoreSyncState.pending);
    });

    test('rethrow para erro nao mapeado', () async {
      await expectLater(
        () => waitForPendingWritesSyncStatus(
          waitForPendingWrites: () async {
            throw _makeException('permission-denied');
          },
        ),
        throwsA(isA<FirebaseException>()),
      );
    });
  });
}
