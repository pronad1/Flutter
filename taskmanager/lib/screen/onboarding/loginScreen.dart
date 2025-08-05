import 'package:flutter/material.dart';
import 'package:taskmanager/api/apiClient.dart';
import 'package:taskmanager/style/style.dart';

class loginScreen extends StatefulWidget {
  const loginScreen({Key? key}) : super(key: key);

  @override
  State<loginScreen> createState() => _loginScreenState();
}


class _loginScreenState extends State<loginScreen> {
  Map<String, String> formValues = {"email": "", "password": ""};
  bool loading = false;

  void inputOnChange(String mapKey, String textValue) {
    setState(() {
      formValues[mapKey] = textValue;
    });
  }


  Future<void> formOnSubmit() async {
    if (formValues['email']!.isEmpty) {
      ErrorToast('Email is required!');
    } else if (formValues['password']!.isEmpty) {
      ErrorToast('Password is required!');
    } else {
      setState(() {
        loading = true;
      });

      try {
        bool res = await LoginRequest(formValues);
        if (res == true) {
          Navigator.pushNamedAndRemoveUntil(context, '/newTaskList', (route) => false);
        } else {
          ErrorToast('Login failed. Please check credentials.');
          setState(() {
            loading = false;
          });
        }
      } catch (e) {
        // catch any unexpected errors
        ErrorToast('An error occurred: $e');
        print(e.toString());
        setState(() {
          loading = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ScreenBackground(context),
          Container(
            alignment: Alignment.center,
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Let's Go", style: Head1Text(colorDarkBlue)),
                  const SizedBox(height: 1),
                  Text("Starting with new hopes!!!", style: Head6Text(colorLightGray)),
                  const SizedBox(height: 20),
                  TextFormField(
                    onChanged: (textValue) => inputOnChange("email", textValue),
                    decoration: AppInputDecoration("Email Address"),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    obscureText: true,
                    onChanged: (textValue) => inputOnChange("password", textValue),
                    decoration: AppInputDecoration("Password"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: AppButtonStyle(),
                    onPressed: formOnSubmit,
                    child: SuccessButtonChild('Login'),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
