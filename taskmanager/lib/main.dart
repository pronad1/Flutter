import 'package:flutter/material.dart';
import 'package:taskmanager/screen/onboarding/emailVerificationScreen.dart';
import 'package:taskmanager/screen/onboarding/loginScreen.dart';
import 'package:taskmanager/screen/onboarding/pinVerificationScreen.dart';
import 'package:taskmanager/screen/onboarding/registrationScreen.dart';
import 'package:taskmanager/screen/onboarding/setPasswordScreen.dart';
import 'package:taskmanager/screen/onboarding/splashScreen.dart';

void main(){
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Task Manager",
      initialRoute: '/setPassword',
      routes: {
        '/':(context)=>splashScreen(),
        '/login':(context)=>loginScreen(),
        '/registration':(context)=>registrationScreem(),
        '/emailVerification':(context)=>emailVerificationScreen(),
        '/pinVerification':(context)=>pinVerificationScreen(),
        '/setPassword':(context)=>setPasswordScreen(),
      },

    );
  }
}