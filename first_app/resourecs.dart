// ctrl + p for parameter
// just main structure

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
        home:const HomeActivity()
    );
  }
}

class HomeActivity extends StatelessWidget{
  const HomeActivity({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("My App"),
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("data")
        ],
      ),
    );
  }
}

// all effect done around  Scaffold
class HomeActivity extends StatelessWidget{

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
// button style
    ButtonStyle buttonStyle=ElevatedButton.styleFrom(
      padding: EdgeInsets.all(15),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(40)
      )
    );
    //Scaffold
    return Scaffold(
      //AppBar
      appBar: AppBar(
        title: Text("Prosenjit"),
        titleSpacing: 20,
        //centerTitle: true,
        toolbarHeight: 60,
        toolbarOpacity:1,
        elevation: 10,
        backgroundColor: Colors.green,
        //set action
        actions:[
          IconButton(onPressed: (){MySnackBar("I am in Comments",context);}, icon: Icon(Icons.comment)),
          IconButton(onPressed: (){MySnackBar("I am in Search",context);}, icon: Icon(Icons.search)),
          IconButton(onPressed: (){MySnackBar("I am in Email Notifications",context);}, icon: Icon(Icons.email)),
          IconButton(onPressed: (){MySnackBar("I am in  Settings",context);}, icon: Icon(Icons.settings)),
          IconButton(onPressed: (){MySnackBar("I am in more option",context);}, icon: Icon(Icons.more_vert))

        ],
      ),
      //floatingActionButton:()
      floatingActionButton: FloatingActionButton(
        elevation: 10,
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
        onPressed: (){
          MySnackBar("I am in Floating Action Button",context);
        },
      ),
      // bottomNavigationBar:(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        backgroundColor: Colors.green,
        items:[
          BottomNavigationBarItem(icon: Icon(Icons.home),label:"Home"),
          BottomNavigationBarItem(icon: Icon(Icons.message),label:"Contact"),
          BottomNavigationBarItem(icon: Icon(Icons.person),label:"Profile")
        ],

        onTap: (int index){
          if(index==0){
            MySnackBar("I am in Home",context);
          }
          if(index==1){
            MySnackBar("I am in Contact",context);
          }
          if(index==2){
            MySnackBar("I am in Profile",context);
          }
        },
      ),
      // drawer: (),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
                padding: EdgeInsets.all(0),
                child: UserAccountsDrawerHeader(
                    decoration: BoxDecoration(color: Colors.white),
                    accountName: Text("Prosenjit Mondol", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    accountEmail: Text("prosenjit1156@gmail.com",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black)),
                    currentAccountPictureSize: Size.fromRadius(35),
                    currentAccountPicture: Image.network("https://avatars.githubusercontent.com/u/143212336?v=4"),
                    onDetailsPressed: (){MySnackBar("This is my Profile",context);}
                )
            ),

            ListTile(leading: Icon(Icons.home),
                title:Text("Home"),
                onTap: (){
                  MySnackBar("I am in Home",context);
                }),
            ListTile(leading: Icon(Icons.email),
                title: Text("Email"),
                onTap: (){
                  MySnackBar("I am in email", context);
                }),
            ListTile(leading: Icon(Icons.phone),
                title: Text("Phone"),
                onTap: (){
                  MySnackBar("I am in Phone", context);
                }),
            ListTile(leading: Icon(Icons.person),
                title: Text("Profile"),
                onTap: (){
                  MySnackBar("I am in Profile", context);
                })
          ],
        ),
      ),
      // endDrawer:(),
      endDrawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
                padding: EdgeInsets.all(0),
                child: UserAccountsDrawerHeader(
                    decoration: BoxDecoration(color: Colors.white),
                    accountName: Text("Prosenjit Mondol", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    accountEmail: Text("prosenjit1156@gmail.com",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black)),
                    currentAccountPictureSize: Size.fromRadius(35),
                    currentAccountPicture: Image.network("https://avatars.githubusercontent.com/u/143212336?v=4"),
                    onDetailsPressed: (){MySnackBar("This is my Profile",context);}
                )
            ),

            ListTile(leading: Icon(Icons.home),
                title:Text("Home"),
                onTap: (){
                  MySnackBar("I am in Home",context);
                }),
            ListTile(leading: Icon(Icons.email),
                title: Text("Email"),
                onTap: (){
                  MySnackBar("I am in email", context);
                }),
            ListTile(leading: Icon(Icons.phone),
                title: Text("Phone"),
                onTap: (){
                  MySnackBar("I am in Phone", context);
                }),
            ListTile(leading: Icon(Icons.person),
                title: Text("Profile"),
                onTap: (){
                  MySnackBar("I am in Profile", context);
                })
          ],
        ),
      ),
      //body: Text("Prosenjit Mondol is a legendary grandmaster at codeforces"),
      // body: Container(
      //   height: 250,
      //   width: 250,
      //   alignment: Alignment.topCenter,
      //   margin: EdgeInsets.all(60),
      //   padding:EdgeInsets.all(60),
      //
      //   decoration: BoxDecoration(
      //     color: Colors.blue,
      //     border: Border.all(color: Colors.black,width: 2),
      //   ),
      //   child: Image.network("https://avatars.githubusercontent.com/u/143212336?v=4")
      // ),

      // body: Row(
      //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      //   children: [
      //     TextButton(onPressed: (){MySnackBar("I am Text Button",context);}, style: buttonStyle, child: Text("Text Button")),
      //     ElevatedButton(onPressed: (){MySnackBar("I am ElevatedButton",context);}, style: buttonStyle, child: Text("Elevated Button"),),
      //     OutlinedButton(onPressed: (){MySnackBar("I am Outlined Button",context);}, style: buttonStyle, child: Text("Outlined Button")),
      //   ],
      // ),

      // Alert Dialog
      body: Center(
        child: ElevatedButton(child:Text("Click Me"),onPressed: (){MyAlertDialog(context);},),
      ),
    );
  }
}

// for simple form
ButtonStyle buttonStyle=ElevatedButton.styleFrom(
  minimumSize: Size(double.infinity, 40),
  backgroundColor: Colors.blue,
);
body: Column(
mainAxisAlignment: MainAxisAlignment.start,
children: [
Padding(padding: EdgeInsets.all(20),child: TextField(decoration: InputDecoration(border:OutlineInputBorder(),labelText: 'First Name')),),
Padding(padding: EdgeInsets.all(20),child: TextField(decoration: InputDecoration(border:OutlineInputBorder(),labelText: 'Last Name')),),
Padding(padding: EdgeInsets.all(20),child: TextField(decoration: InputDecoration(border:OutlineInputBorder(),labelText: 'Email Address')),),
Padding(padding: EdgeInsets.all(20),child: ElevatedButton(onPressed: (){},style: buttonStyle, child: Text("Submit"),),)
],
),

// Dynamic list view using json array
// for that use GestureDetector , list view builder, JSOn array

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

// For Dynamic list gride view builder
// just change small in dynamic list that
body: GridView.builder(
gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 2,
crossAxisSpacing: 0,
childAspectRatio:1,
),


// For create different  Fragment at first create a fragment folder and there create all fragment files and then call from main file
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

// This is demo of home fragment
import 'package:flutter/cupertino.dart';

class HomeFragment extends StatelessWidget{

@override
Widget build(BuildContext context){
return Container(
child: Center(
child: Text("HomeFragment"),
),
);
}
}

// Simple Navigation go from one page to another
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

