import 'package:flutter/material.dart';
import 'Fragment/AlarmFragment.dart';
import 'Fragment/BalanceFragment.dart';
import 'Fragment/EmailFragment.dart';
import 'Fragment/HomeFragment.dart';
import 'Fragment/PersonFragment.dart';
import 'Fragment/PhoneFragment.dart';
import 'Fragment/SearchFragment.dart';
import 'Fragment/SettingFragment.dart';


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

    return DefaultTabController(
        length: 9,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Prosen"),
            backgroundColor: Colors.blue,
            bottom: TabBar(
              isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.home),text:'Home'),
                  Tab(icon: Icon(Icons.message),text: 'Message'),
                  Tab(icon: Icon(Icons.person),text: 'Person',),
                  Tab(icon: Icon(Icons.settings),text: 'Settings'),
                  Tab(icon: Icon(Icons.email),text: 'Email'),
                  Tab(icon: Icon(Icons.phone),text: 'Phone'),
                  Tab(icon: Icon(Icons.account_balance),text: 'Balance'),
                  Tab(icon: Icon(Icons.access_alarm),text: 'Alarm'),
                ]
            ),
          ),
          body: TabBarView(
              children: [
                HomeFragment(),
                SearchFragment(),
                SettingFragment(),
                EmailFragment(),
                PhoneFragment(),
                PersonFragment(),
                BalanceFragment(),
                AlarmFragment(),
              ],
          ),
        )
    );

  }
}