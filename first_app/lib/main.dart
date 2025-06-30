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
        title: Text("Inventory"),
        titleSpacing: 0,
        centerTitle: true,
        toolbarHeight: 60,
        toolbarOpacity:1,
        elevation: 10,
        backgroundColor: Colors.amber,

      )

      //body: Text("Prosenjit Mondol is a legendary grandmaster at codeforces"),
      // drawer: (),
      // endDrawer:(),
      // bottomNavigationBar:(),
      // floatingActionButton:(),
    );

  }

}