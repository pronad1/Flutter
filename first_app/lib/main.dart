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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [

          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40)
                  )
              ),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>Activity1("This is from Activity 1")));
              }, child: Text("Go Activity 1")),

          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40)
                  )
              ),
              onPressed: (){

                Navigator.push(context, MaterialPageRoute(builder: (context)=>Activity2("This is from Activity 2")));
              }, child: Text("Go Activity 2")),
        ],
      ),
    );

  }
}

class Activity1 extends StatelessWidget{

  String msg;

  Activity1(
      this.msg,
      {super.key}
      );


  @override
  Widget build(BuildContext context){

    return Scaffold(
        appBar: AppBar(
          title: Text(msg),
          backgroundColor: Colors.red,
        ),
        body:Center(
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40)
                  )
              ),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>Activity2("This is from Activity 1 to Activity 2")));
              }, child: Text("Go Activity 2")),
        )
    );
  }
}

class Activity2 extends StatelessWidget{
  String msg;
  Activity2(
      this.msg,
      {super.key});


  @override
  Widget build(BuildContext context){

    return Scaffold(
        appBar: AppBar(
          title: Text(msg),
          backgroundColor: Colors.pinkAccent,
        ),
        body:Center(
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40)
                  )
              ),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>Activity1("This is from Activity 2 to Activity 1")));
              }, child: Text("Go Activity 1")),
        )
    );
  }
}