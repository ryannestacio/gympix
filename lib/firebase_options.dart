import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      case TargetPlatform.fuchsia:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCx1zkWjUV1U6xJF3wioyRvX0oy1BsqDmQ',
    appId: '1:16853071429:web:a6ce94152d014a5d29d52c',
    messagingSenderId: '16853071429',
    projectId: 'gympixapp',
    authDomain: 'gympixapp.firebaseapp.com',
    storageBucket: 'gympixapp.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCjrU4s_vNYac1hSKb_8t4CBT3vAg6VCjQ',
    appId: '1:16853071429:android:6ab39e5d8ed012de29d52c',
    messagingSenderId: '16853071429',
    projectId: 'gympixapp',
    storageBucket: 'gympixapp.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBJfD0NnHABNKhbKe5CvBb3l1sUei5LaLM',
    appId: '1:16853071429:ios:db8278f94cf0f43029d52c',
    messagingSenderId: '16853071429',
    projectId: 'gympixapp',
    storageBucket: 'gympixapp.firebasestorage.app',
    iosBundleId: 'com.example.gymEasy2',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBJfD0NnHABNKhbKe5CvBb3l1sUei5LaLM',
    appId: '1:16853071429:ios:db8278f94cf0f43029d52c',
    messagingSenderId: '16853071429',
    projectId: 'gympixapp',
    storageBucket: 'gympixapp.firebasestorage.app',
    iosBundleId: 'com.example.gymEasy2',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCx1zkWjUV1U6xJF3wioyRvX0oy1BsqDmQ',
    appId: '1:16853071429:web:18b1cc376c03166729d52c',
    messagingSenderId: '16853071429',
    projectId: 'gympixapp',
    authDomain: 'gympixapp.firebaseapp.com',
    storageBucket: 'gympixapp.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyCx1zkWjUV1U6xJF3wioyRvX0oy1BsqDmQ',
    appId: '1:16853071429:web:18b1cc376c03166729d52c',
    messagingSenderId: '16853071429',
    projectId: 'gympixapp',
    authDomain: 'gympixapp.firebaseapp.com',
    storageBucket: 'gympixapp.firebasestorage.app',
  );
}
