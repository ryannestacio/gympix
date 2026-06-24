import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

Future<void>? _firebaseInitialization;

Future<void> ensureFirebaseInitialized() {
  return _firebaseInitialization ??= _initializeFirebaseServices();
}

Future<void> _initializeFirebaseServices() async {
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }
  }

  await _configureFirestoreOfflineSafely();
}

Future<void> _configureFirestoreOfflineSafely() async {
  final firestore = FirebaseFirestore.instance;
  try {
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'failed-precondition' || e.code == 'unimplemented') return;
    rethrow;
  }
}
