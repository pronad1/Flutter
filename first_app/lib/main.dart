// import 'package:first_app/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bootstrap/flutter_bootstrap.dart';
//import 'package:responsive_grid/responsive_grid.dart';
import 'package:flutter_bootstrap/flutter_bootstrap.dart';



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

    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        backgroundColor: Colors.green,
      ),

      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: BootstrapContainer(
          fluid: true,
          children: [
            BootstrapRow(
              height: 100,
                children:[
                  BootstrapCol(
                    sizes: 'col-xl-1 col-xg-2 col-md-3 col-sm-4 col-6',
                      child: Container(
                        height: 100,
                        color: Colors.brown,
                      )
                  ),
                  BootstrapCol(
                      sizes: 'col-xl-1 col-xg-2 col-md-3 col-sm-4 col-6',
                      child: Container(
                        height: 100,
                        color: Colors.black,
                      )
                  ),
                  BootstrapCol(
                      sizes: 'col-xl-1 col-xg-2 col-md-3 col-sm-4 col-6',
                      child: Container(
                        height: 100,
                        color: Colors.orange,
                      )
                  ),
                  BootstrapCol(
                      sizes: 'col-xl-1 col-xg-2 col-md-3 col-sm-4 col-6',
                      child: Container(
                        height: 100,
                        color: Colors.blue,
                      )
                  ),
                  BootstrapCol(
                      sizes: 'col-xl-1 col-xg-2 col-md-3 col-sm-4 col-6',
                      child: Container(
                        height: 100,
                        color: Colors.redAccent,
                      )
                  ),
                  BootstrapCol(
                      sizes: 'col-xl-1 col-xg-2 col-md-3 col-sm-4 col-6',
                      child: Container(
                        height: 100,
                        color: Colors.grey,
                      )
                  ),
                ] 
            )
          ],
        )
      )

    );
  }
}