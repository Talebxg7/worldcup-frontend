// Default Firebase options (FlutterFire public E2E test project).
// Replace with your app by running: flutterfire configure
//
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        // FlutterFire historically maps Windows to the same options shape as Android.
        return android;
      case TargetPlatform.linux:
        return android;
      default:
        return windows;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBia7At7SDuQTbpJIZudljdUqrrftwLLls',
    appId: '1:1083510169013:web:fdb926ef81d1aac1828dfc',
    messagingSenderId: '1083510169013',
    projectId: 'fantacy-game-4e7ba',
    authDomain: 'fantacy-game-4e7ba.firebaseapp.com',
    storageBucket: 'fantacy-game-4e7ba.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDvzcjyW5bSJA4PiqGyqNFCNN3xqv4A2xQ',
    appId: '1:1083510169013:android:9fbbf59ab9b580d6828dfc',
    messagingSenderId: '1083510169013',
    projectId: 'fantacy-game-4e7ba',
    storageBucket: 'fantacy-game-4e7ba.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDooSUGSf63Ghq02_iIhtnmwMDs4HlWS6c',
    appId: '1:406099696497:ios:acd9c8e17b5e620e3574d0',
    messagingSenderId: '406099696497',
    projectId: 'flutterfire-e2e-tests',
    databaseURL:
        'https://flutterfire-e2e-tests-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'flutterfire-e2e-tests.appspot.com',
    iosClientId:
        '406099696497-taeapvle10rf355ljcvq5dt134mkghmp.apps.googleusercontent.com',
    iosBundleId: 'io.flutter.plugins.firebase.tests',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDooSUGSf63Ghq02_iIhtnmwMDs4HlWS6c',
    appId: '1:406099696497:ios:acd9c8e17b5e620e3574d0',
    messagingSenderId: '406099696497',
    projectId: 'flutterfire-e2e-tests',
    databaseURL:
        'https://flutterfire-e2e-tests-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'flutterfire-e2e-tests.appspot.com',
    androidClientId:
        '406099696497-tvtvuiqogct1gs1s6lh114jeps7hpjm5.apps.googleusercontent.com',
    iosClientId:
        '406099696497-taeapvle10rf355ljcvq5dt134mkghmp.apps.googleusercontent.com',
    iosBundleId: 'io.flutter.plugins.firebase.tests',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBia7At7SDuQTbpJIZudljdUqrrftwLLls',
    appId: '1:1083510169013:web:fdb926ef81d1aac1828dfc',
    messagingSenderId: '1083510169013',
    projectId: 'fantacy-game-4e7ba',
    authDomain: 'fantacy-game-4e7ba.firebaseapp.com',
    storageBucket: 'fantacy-game-4e7ba.firebasestorage.app',
  );

}