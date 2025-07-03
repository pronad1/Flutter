import 'package:flutter/material.dart';

main(){
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});


// ctrl + p for parameter

  @override
  Widget build(BuildContext context) {
    
    return const MaterialApp(home:HomeActivity());
  }

}

class HomeActivity extends StatelessWidget{
  const HomeActivity({super.key});

  // test sms
  MySnackBar(message,context){
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content:Text(message))
    );
  }


//dialog sms
  MyAlertDialog(context){
    return showDialog(
      context: context,
      builder: (BuildContext context){
        return Expanded(
          child: AlertDialog(
            title: Text("Alert"),
            content: Text("Do you want to delete me!!!"),
            actions: [
              TextButton(onPressed: (){
                MySnackBar("Delete Success",context);
                Navigator.pop(context);}, child: Text("Yes")),
              TextButton(onPressed: (){Navigator.pop(context);}, child: Text("No")),
            ],
          )
        );
      }
    );
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Center(
        child: ElevatedButton(child:Text("Click Me"),onPressed: (){MyAlertDialog(context);},),
      ),


    );
  }
}