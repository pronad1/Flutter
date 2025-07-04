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
            Navigator.push(context, MaterialPageRoute(builder: (context)=>Activity1()));
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

            Navigator.push(context, MaterialPageRoute(builder: (context)=>Activity2()));
            }, child: Text("Go Activity 2")),
        ],
      ),
    );

  }
}

class Activity1 extends StatelessWidget{

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(
        title: Text("Activity1"),
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
              Navigator.push(context, MaterialPageRoute(builder: (context)=>Activity2()));
            }, child: Text("Go Activity 2")),
      )
    );
  }
}

class Activity2 extends StatelessWidget{

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(
        title: Text("Activity2"),
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
              Navigator.push(context, MaterialPageRoute(builder: (context)=>Activity1()));
            }, child: Text("Go Activity 1")),
      )
    );
  }
}