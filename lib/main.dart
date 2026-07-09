import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using your generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set this to true if you are running the local Firebase Emulator Suite.
  // Set to false to use the live Firebase production project (Blaze plan).
  const bool useFirebaseEmulators = true;

  if (kDebugMode && useFirebaseEmulators) {
    try {
      final host = defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      debugPrint('Successfully connected to Firebase Emulators at $host');
    } catch (e) {
      debugPrint('Error connecting to Firebase Emulators: $e');
    }
  }

  runApp(const HomeServiceApp());
}


class HomeServiceApp extends StatelessWidget {
  const HomeServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Service',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AuthGate(),
    );
  }
}

/// Sends a returning, already-authenticated user straight to Home and
/// everyone else to onboarding — satisfies the PRD's "persistent
/// sessions" requirement without any manual token handling, since
/// FirebaseAuth persists sessions on its own.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != null) {
          return const HomeScreen();
        }
        return const OnboardingScreen();
      },
    );
  }
}
