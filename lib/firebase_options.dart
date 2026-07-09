// GENERATED PLACEHOLDER — replace this entire file by running:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// from the project root, with your own Firebase project selected.
// That command overwrites this file with real, working values for
// every platform you target. The app will not connect to Firebase
// until you do this.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform. '
          'Run `flutterfire configure` to generate real values.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    authDomain: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBgvUAbyKa-jI4YRvTjjKVDxu4pIsuuW-I',
    appId: '1:755819635536:android:92be6a549f6b4f68eb0255',
    messagingSenderId: '755819635536',
    projectId: 'home-service-app-84d19',
    storageBucket: 'home-service-app-84d19.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME',
    iosBundleId: 'REPLACE_ME',
  );
}
