import 'package:flutter/material.dart';

ThemeData appTheme() {
  return ThemeData(
    primarySwatch: Colors.green,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
  );
}

Widget screenBackground(BuildContext context) {
  return Container(
    color: Colors.white,
  );
}