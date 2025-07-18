// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDWsX0e6uePla04L_rkUJkcRMOvzKFtBBY',
    appId: '1:412683657587:web:adf9d3d684117a0ed52506',
    messagingSenderId: '412683657587',
    projectId: 'alifsteelapp',
    authDomain: 'alifsteelapp.firebaseapp.com',
    storageBucket: 'alifsteelapp.firebasestorage.app',
    measurementId: 'G-KS2KHJE8KT',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCtSM2de3h6YelW8ohHBMiZHWpIrSAHFek',
    appId: '1:412683657587:android:913eb20632db5ba4d52506',
    messagingSenderId: '412683657587',
    projectId: 'alifsteelapp',
    storageBucket: 'alifsteelapp.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAn8aD7QKwpArpZvekOOEE4lO-b6T3iDeo',
    appId: '1:412683657587:ios:83e2766264123161d52506',
    messagingSenderId: '412683657587',
    projectId: 'alifsteelapp',
    storageBucket: 'alifsteelapp.firebasestorage.app',
    iosBundleId: 'com.example.alifSteelApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAn8aD7QKwpArpZvekOOEE4lO-b6T3iDeo',
    appId: '1:412683657587:ios:83e2766264123161d52506',
    messagingSenderId: '412683657587',
    projectId: 'alifsteelapp',
    storageBucket: 'alifsteelapp.firebasestorage.app',
    iosBundleId: 'com.example.alifSteelApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDWsX0e6uePla04L_rkUJkcRMOvzKFtBBY',
    appId: '1:412683657587:web:70051dfc4980648bd52506',
    messagingSenderId: '412683657587',
    projectId: 'alifsteelapp',
    authDomain: 'alifsteelapp.firebaseapp.com',
    storageBucket: 'alifsteelapp.firebasestorage.app',
    measurementId: 'G-0JDBDEFC0N',
  );
}
