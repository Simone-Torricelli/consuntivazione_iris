import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_options.dart';

class FirebaseBootstrapService {
  FirebaseBootstrapService._();

  static final FirebaseBootstrapService instance = FirebaseBootstrapService._();

  bool _isReady = false;

  bool get isReady => _isReady;

  Future<void> initialize() async {
    if (_isReady) {
      return;
    }

    final options = DefaultFirebaseOptions.currentPlatform;
    if (!DefaultFirebaseOptions.isConfigured || options == null) {
      if (kIsWeb) {
        debugPrint(
          'Firebase disabilitato su WEB: configura web con `flutterfire configure --platforms=web` '
          'oppure passa i dart-define FIREBASE_WEB_* in run/build.',
        );
      } else {
        debugPrint(
          'Firebase disabilitato: piattaforma corrente non configurata in lib/firebase/firebase_options.dart',
        );
      }
      return;
    }

    try {
      await Firebase.initializeApp(options: options);
      _isReady = true;
      debugPrint('Firebase inizializzato correttamente.');
    } catch (e) {
      debugPrint('Firebase init fallita, fallback locale: $e');
      _isReady = false;
    }
  }
}
