import 'package:flutter/material.dart';
import 'package:to_do_app/style.dart';

class ToDoPage extends StatefulWidget{


  @override
  State<StatefulWidget> createState() {
    return ToDoPageView();
  }
}

class ToDoPageView extends State<ToDoPage>{

  List ToDoList=[];
  String item="";

  MyInputOnChange(content){
    setState(() {
      item=content;
    });
  }

  AddItem(){
    setState(() {
      ToDoList.add({'item':item});
    });
  }


  RemoveItem(index){
    setState(() {
      ToDoList.removeAt(index);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ToDo"),
        backgroundColor: Colors.green,
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              flex: 10,
            child: Row(
              children: [
                Expanded(flex: 70,child: TextFormField(onChanged: (content){MyInputOnChange(content);},decoration: AppInputDecoration("List Item"),)),
                Expanded(flex: 20,child: Padding(padding: EdgeInsets.only(left: 5),child: ElevatedButton(onPressed:(){AddItem();}, style: AppButtonStyle(),child: Text('Add'),),)),
              ],
            )
            ),
            Expanded(
                flex:90,
                child: ListView.builder(
                  itemCount:ToDoList.length,
                    itemBuilder: (context,index){
                    return Card(
                      child: SizedBox50(
                        Row(
                          children: [
                            Expanded(flex: 80,child: Text(ToDoList[index]['item'].toString())),
                            Expanded(flex: 250,child: TextButton(onPressed:(){RemoveItem(index);},child: Icon(Icons.delete))),

                          ],
                        )
                      ),
                    );
                    }
                ),
            )
          ],
        ),
      ),
    );
  }


}