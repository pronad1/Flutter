import 'package:shared_preferences/shared_preferences.dart';

Future<void> StoreUserData(UserData) async{
  final prefs =await SharedPreferences.getInstance();
  await prefs.setString('token', UserData['token']);
  await prefs.setString('email', UserData['token']['email']);
  await prefs.setString('firstName', UserData['token']['firstName']);
  await prefs.setString('lastName', UserData['token']['lastName']);
  await prefs.setString('mobile', UserData['token']['mobile']);
  await prefs.setString('photo', UserData['token']['photo']);
}