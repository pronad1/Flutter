
import 'package:flutter/material.dart';

TextStyle HeadLine(context){


  var width=MediaQuery.of(context).size.width;
  if(width<700){
    // Mobile or tab
    return TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );
  }
  else{
// Desktop
    return TextStyle(
      color: Colors.amber,
      fontSize: 40,
      fontWeight: FontWeight.bold,
    );
  }

}
