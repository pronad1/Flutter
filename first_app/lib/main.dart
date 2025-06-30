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

  MySnackBar(message,context){
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content:Text(message))
    );
  }


  @override
  Widget build(BuildContext context) {

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
      body: Center(
      child: Text("Hey Pro da r u choda no matter what are you doing but matter hay if you are not doing anything special!!!"),
      )



    );

  }

}