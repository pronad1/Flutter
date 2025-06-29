import 'package:flutter/material.dart';

main(){
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});



  @override
  Widget build(BuildContext context) {
    
    return const MaterialApp(home:HomeActivity());
  }

}

class HomeActivity extends StatelessWidget{
  const HomeActivity({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Project build by Prosenjit Mondol"),
      ),
      body: Text("Prosenjit Mondol is a legendary grandmaster at codeforces"),
    );

  }

}