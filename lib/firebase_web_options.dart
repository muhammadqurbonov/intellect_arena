import 'package:firebase_core/firebase_core.dart';

/// Танзимоти Firebase барои версияи веб.
///
/// Ин қиматҳоро аз Firebase Console гиред:
/// Project settings → General → Your apps → Web app (</>) → SDK setup and configuration.
/// Ё: `flutterfire configure --platforms=web`
const FirebaseOptions webFirebaseOptions = FirebaseOptions(
  apiKey: 'PASTE_API_KEY',
  appId: 'PASTE_APP_ID',
  messagingSenderId: 'PASTE_SENDER_ID',
  projectId: 'PASTE_PROJECT_ID',
  authDomain: 'PASTE_PROJECT_ID.firebaseapp.com',
  storageBucket: 'PASTE_PROJECT_ID.appspot.com',
);
