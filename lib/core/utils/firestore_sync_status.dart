import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

enum FirestoreSyncState { synced, pending }

const _pendingSyncErrorCodes = <String>{
  'aborted',
  'cancelled',
  'deadline-exceeded',
  'failed-precondition',
  'unavailable',
};

Future<FirestoreSyncState> waitForFirestoreSync(
  FirebaseFirestore firestore, {
  Duration timeout = const Duration(seconds: 4),
}) {
  return waitForPendingWritesSyncStatus(
    waitForPendingWrites: firestore.waitForPendingWrites,
    timeout: timeout,
  );
}

Future<FirestoreSyncState> waitForPendingWritesSyncStatus({
  required Future<void> Function() waitForPendingWrites,
  Duration timeout = const Duration(seconds: 4),
}) async {
  try {
    await waitForPendingWrites().timeout(timeout);
    return FirestoreSyncState.synced;
  } on TimeoutException {
    return FirestoreSyncState.pending;
  } on FirebaseException catch (e) {
    if (_pendingSyncErrorCodes.contains(e.code)) {
      return FirestoreSyncState.pending;
    }
    rethrow;
  }
}
