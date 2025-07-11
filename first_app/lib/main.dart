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
      title: 'Flutter Demo',
        theme: ThemeData(
          primaryColor: Colors.blue,
        ),
        home: HomeActivity()
    );
  }
}



class MyHomePage extends StatefulWidget{
  int countNumber=0;


  // Number 01
  @override
  State<StatefulWidget> createState(){
    return MyHomePageUi();
  }
}




class MyHomePageUi extends State<MyHomePage>{

  // Number 02
  @override
  void initState(){
    print("initstate called");
    super.initState();
  }


  // Number 03
  @override
  void didChangeDependencies(){
    print("didChangeDependencies called");
    super.didChangeDependencies();
  }

  // Number 04

@override
  widget build(BuildContext context){
  print("build called");
  return Scaffold(
    appBar: AppBar(
  ),
}






}

