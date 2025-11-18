import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'src/config/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //Initialize Supabase
  await Supabase.initialize(
    url: 'https://apfcycghfwiupflrpdgn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFwZmN5Y2doZndpdXBmbHJwZGduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgxOTM3ODMsImV4cCI6MjA3Mzc2OTc4M30.-bXtNLIizqYRoKwigPs21uRLcNwSI7Nj9w8ujaah_Gk',
  );

  runApp(const ReuseHubApp());
}

class ReuseHubApp extends StatelessWidget {
  const ReuseHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reuse Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      initialRoute: '/splash',
      onGenerateRoute: Routes.generateRoute,
    );
  }
}
