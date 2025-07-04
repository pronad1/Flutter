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
        home: HomeActivity()
    );
  }
}

class HomeActivity extends StatelessWidget{

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(
        title: Text("Prosen"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.green,
          strokeWidth: 5,
          backgroundColor: Colors.black,
        ),
      ),
    );

  }
}
