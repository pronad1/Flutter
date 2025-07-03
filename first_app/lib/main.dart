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
  HomeActivity({super.key});

var MyItems=[
  {"img":"https://pronad1.github.io/Personal-Portfolio/small-black.jpg","title":"Prosenjit"},
  {"img":"https://pronad1.github.io/Personal-Portfolio/small-black.jpg","title":"Prosenjit"},
  {"img":"https://pronad1.github.io/Personal-Portfolio/small-black.jpg","title":"Prosenjit"},
  {"img":"https://pronad1.github.io/Personal-Portfolio/small-black.jpg","title":"Prosenjit"},
  {"img":"https://pronad1.github.io/Personal-Portfolio/small-black.jpg","title":"Prosenjit"},
  {"img":"https://pronad1.github.io/Personal-Portfolio/small-black.jpg","title":"Prosenjit"}


];

mySnackBar(context,msg){
  return ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}


  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: Text("My App"),
        backgroundColor: Colors.green,
      ),

      body: ListView.builder(
        itemCount: MyItems.length,
          itemBuilder: (context,index){
          return GestureDetector(
            onDoubleTap: (){mySnackBar(context, MyItems[index]['title']);},
            child: Container(
              margin: EdgeInsets.all(10),
              height: 350,
              child: Image.network(MyItems[index]['img']!, fit: BoxFit.fill,),
            ),
          );
          },
      )
    );
  }
}