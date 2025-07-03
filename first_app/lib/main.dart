import 'package:flutter/material.dart';

main(){
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

// ctrl + p for parameter
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home:const HomeActivity()
    );
  }
}

class HomeActivity extends StatelessWidget{
  const HomeActivity({super.key});

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: Text("My App"),
        backgroundColor: Colors.green,
      ),


    );
  }
}