import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:software/screens/onboarding/splashScreen.dart';
import 'firebase_options.dart';
// This was auto-generated

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reuse Hub',
      initialRoute: '/',
      routes: {
        '/':(context)=>splashScreen(),
      },
    );
  }
}
