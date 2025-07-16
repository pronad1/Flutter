import 'package:flutter/material.dart';

InputDecoration AppInputStyle(label){
  return InputDecoration(
    contentPadding: EdgeInsets.fromLTRB(20,10,10,20),
    fillColor: Colors.white,
    filled: true,
    border: OutlineInputBorder(),
    labelText: label,
  );
}

TextStyle HeadTextStyle(){
  return TextStyle(

    fontSize: 49,
    fontWeight: FontWeight.w500
  );
}

ButtonStyle AppButtonStyle(){
  return ElevatedButton.styleFrom(
    padding: EdgeInsets.all(25),
  backgroundColor: Colors.green,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4))
    )
    
  );
}