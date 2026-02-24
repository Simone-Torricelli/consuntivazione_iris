import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static bool get isConfigured => true;

  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) {
      return null;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return null;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD4AY1N9v9W9coCmnN7jBTbY3bXqMzG2Sw',
    appId: '1:381827995098:android:6ad747c6de5910677b1ce3',
    messagingSenderId: '381827995098',
    projectId: 'irisconsuntivazione',
    storageBucket: 'irisconsuntivazione.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCiRrLJdoLsM6J7P2Znwi_B1ej85N6pSGs',
    appId: '1:381827995098:ios:320a001e5eb2f3f17b1ce3',
    messagingSenderId: '381827995098',
    projectId: 'irisconsuntivazione',
    storageBucket: 'irisconsuntivazione.firebasestorage.app',
    iosBundleId: 'com.example.consuntivazioneIris',
  );
}
