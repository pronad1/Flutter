import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'your-android-apiKey',
    appId: 'your-android-appId',
    messagingSenderId: 'your-android-messagingSenderId',
    projectId: 'reuse-hub-4b3f7',
    storageBucket: 'reuse-hub-4b3f7.appspot.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'your-web-apiKey',
    appId: 'your-web-appId',
    messagingSenderId: 'your-web-messagingSenderId',
    projectId: 'reuse-hub-4b3f7',
    authDomain: 'reuse-hub-4b3f7.firebaseapp.com',
    storageBucket: 'reuse-hub-4b3f7.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'your-ios-apiKey',
    appId: 'your-ios-appId',
    messagingSenderId: 'your-ios-messagingSenderId',
    projectId: 'reuse-hub-4b3f7',
    storageBucket: 'reuse-hub-4b3f7.appspot.com',
  );

  static const FirebaseOptions macos = ios; // reuse iOS options

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'your-windows-apiKey',
    appId: 'your-windows-appId',
    messagingSenderId: 'your-windows-messagingSenderId',
    projectId: 'reuse-hub-4b3f7',
    storageBucket: 'reuse-hub-4b3f7.appspot.com',
  );
}
