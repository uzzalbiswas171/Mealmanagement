import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA5pHpjKa3WnqjjSUGgxk49BI3-cTbBqkg',
    appId: '1:733191018600:android:6099fd8d59084d4a5ec3dd',
    messagingSenderId: '733191018600',
    projectId: 'mealmanagement-66fe8',
    storageBucket: 'mealmanagement-66fe8.firebasestorage.app',
  );
}
