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
  const HomeActivity({super.key});

  @override
  Widget build(BuildContext context) {

    var width=MediaQuery.of(context).size.width;
    var heigh=MediaQuery.of(context).size.height;
    var orientation=MediaQuery.of(context).orientation;
    

    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("Screen Width:- $width"),
        Text("Screen Height:- $heigh"),
          Text("Screen Orientation:- $orientation")
        ],
      ),
    );
  }
}