import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

Future<FirebaseApp> initFirebaseOnce() async {
  if (Firebase.apps.isNotEmpty) return Firebase.apps.first;
  try {
    return await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      return Firebase.app();
    }
    rethrow;
  }
}
