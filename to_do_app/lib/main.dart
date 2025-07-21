import 'package:flutter/material.dart';
import 'package:to_do_app/ToDoPage.dart';

void main(){
  runApp(MyApp());
}

class MyApp extends StatelessWidget{


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "To Do",
      theme: ThemeData(primaryColor: Colors.green),
      home: ToDoPage(),
    );
  }
}