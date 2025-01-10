import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
      home: Scaffold(
        appBar: AppBar(title: Text('Reuse Hub')),
        body: Center(child: Text('Welcome to Reuse Hub')),
      ),
    );
  }
}
