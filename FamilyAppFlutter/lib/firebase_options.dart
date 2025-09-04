import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCq2p7JIGIY5yV4J-nFixPW0obNDxbME',
    appId: '1:308896699883:android:f02227fe07d50fbcb275ae',
    messagingSenderId: '308896699883',
    projectId: 'familyandfriends-space',
    storageBucket: 'familyandfriends-space.firebasestorage.app',
  );
}
