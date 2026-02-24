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

    if (!DefaultFirebaseOptions.isConfigured ||
        DefaultFirebaseOptions.currentPlatform == null) {
      debugPrint(
        'Firebase disabilitato: configura lib/firebase/firebase_options.dart',
      );
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isReady = true;
      debugPrint('Firebase inizializzato correttamente.');
    } catch (e) {
      debugPrint('Firebase init fallita, fallback locale: $e');
      _isReady = false;
    }
  }
}
