import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../firebase_options.dart' as generated_options;

class DefaultFirebaseOptions {
  static bool get isConfigured =>
      _optionsFromDartDefines() != null || _generatedCurrentPlatform() != null;

  static FirebaseOptions? get currentPlatform {
    final fromDefines = _optionsFromDartDefines();
    if (fromDefines != null) {
      return fromDefines;
    }

    final generated = _generatedCurrentPlatform();
    if (generated != null) {
      return generated;
    }

    return null;
  }

  static FirebaseOptions? _generatedCurrentPlatform() {
    try {
      return generated_options.DefaultFirebaseOptions.currentPlatform;
    } catch (_) {
      return null;
    }
  }

  static FirebaseOptions? _optionsFromDartDefines() {
    if (kIsWeb) {
      return _webFromDefines();
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidFromDefines();
      case TargetPlatform.iOS:
        return _iosFromDefines();
      default:
        return null;
    }
  }

  static const String _webApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
  );
  static const String _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const String _webMessagingSenderId = String.fromEnvironment(
    'FIREBASE_WEB_MESSAGING_SENDER_ID',
  );
  static const String _webProjectId = String.fromEnvironment(
    'FIREBASE_WEB_PROJECT_ID',
  );
  static const String _webAuthDomain = String.fromEnvironment(
    'FIREBASE_WEB_AUTH_DOMAIN',
  );
  static const String _webStorageBucket = String.fromEnvironment(
    'FIREBASE_WEB_STORAGE_BUCKET',
  );
  static const String _webMeasurementId = String.fromEnvironment(
    'FIREBASE_WEB_MEASUREMENT_ID',
  );

  static FirebaseOptions? _webFromDefines() {
    if (_webApiKey.isEmpty ||
        _webAppId.isEmpty ||
        _webMessagingSenderId.isEmpty ||
        _webProjectId.isEmpty) {
      return null;
    }

    return const FirebaseOptions(
      apiKey: _webApiKey,
      appId: _webAppId,
      messagingSenderId: _webMessagingSenderId,
      projectId: _webProjectId,
      authDomain: _webAuthDomain,
      storageBucket: _webStorageBucket,
      measurementId: _webMeasurementId,
    );
  }

  static const String _androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const String _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const String _androidMessagingSenderId = String.fromEnvironment(
    'FIREBASE_ANDROID_MESSAGING_SENDER_ID',
  );
  static const String _androidProjectId = String.fromEnvironment(
    'FIREBASE_ANDROID_PROJECT_ID',
  );
  static const String _androidStorageBucket = String.fromEnvironment(
    'FIREBASE_ANDROID_STORAGE_BUCKET',
  );

  static FirebaseOptions? _androidFromDefines() {
    if (_androidApiKey.isEmpty ||
        _androidAppId.isEmpty ||
        _androidMessagingSenderId.isEmpty ||
        _androidProjectId.isEmpty) {
      return null;
    }

    return const FirebaseOptions(
      apiKey: _androidApiKey,
      appId: _androidAppId,
      messagingSenderId: _androidMessagingSenderId,
      projectId: _androidProjectId,
      storageBucket: _androidStorageBucket,
    );
  }

  static const String _iosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
  );
  static const String _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const String _iosMessagingSenderId = String.fromEnvironment(
    'FIREBASE_IOS_MESSAGING_SENDER_ID',
  );
  static const String _iosProjectId = String.fromEnvironment(
    'FIREBASE_IOS_PROJECT_ID',
  );
  static const String _iosStorageBucket = String.fromEnvironment(
    'FIREBASE_IOS_STORAGE_BUCKET',
  );
  static const String _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
  );

  static FirebaseOptions? _iosFromDefines() {
    if (_iosApiKey.isEmpty ||
        _iosAppId.isEmpty ||
        _iosMessagingSenderId.isEmpty ||
        _iosProjectId.isEmpty) {
      return null;
    }

    return const FirebaseOptions(
      apiKey: _iosApiKey,
      appId: _iosAppId,
      messagingSenderId: _iosMessagingSenderId,
      projectId: _iosProjectId,
      storageBucket: _iosStorageBucket,
      iosBundleId: _iosBundleId,
    );
  }
}
