import 'package:flutter/material.dart';
import 'package:taskmanager/screen/onboarding/emailVerificationScreen.dart';
import 'package:taskmanager/screen/onboarding/LoginScreen.dart';
import 'package:taskmanager/screen/onboarding/pinVerificationScreen.dart';
import 'package:taskmanager/screen/onboarding/registrationScreen.dart';
import 'package:taskmanager/screen/onboarding/setPasswordScreen.dart';
import 'package:taskmanager/screen/onboarding/splashScreen.dart';
import 'package:taskmanager/screen/task/newTaskListScreen.dart';

void main(){
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Task Manager",
      initialRoute: '/login',
      routes: {
        '/':(context)=>splashScreen(),
        '/login':(context)=>loginScreen(),
        '/registration':(context)=>registrationScreem(),
        '/emailVerification':(context)=>emailVerificationScreen(),
        '/pinVerification':(context)=>pinVerificationScreen(),
        '/setPassword':(context)=>setPasswordScreen(),
        '/newTaskList':(context)=>newTaskListScreen(),

      },

    );
  }
}