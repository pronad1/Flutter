import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController mobileController = TextEditingController();

  File? _imageFile;        // For mobile
  Uint8List? _webImage;    // For Web
  bool _isLoading = false;

  // Pick Image
  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      if (kIsWeb) {
        _webImage = await pickedFile.readAsBytes();
        print('Web image picked, length: ${_webImage!.length}');
      } else {
        _imageFile = File(pickedFile.path);
        print('Mobile image picked: ${_imageFile!.path}');
      }
      setState(() {});
    } catch (e) {
      print('Pick image error: $e');
    }
  }

  // Upload Image safely
  Future<String?> uploadProfilePic(String uid) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_pics/$uid.jpg');

      // Skip upload if no image selected
      if (kIsWeb) {
        if (_webImage == null) {
          print('No web image selected, skipping upload');
          return null;
        }
        print('Uploading Web image...');
        await ref.putData(_webImage!);
        print('Web image upload complete');
      } else {
        if (_imageFile == null) {
          print('No mobile image selected, skipping upload');
          return null;
        }
        print('Uploading Mobile image...');
        await ref.putFile(_imageFile!);
        print('Mobile image upload complete');
      }

      final url = await ref.getDownloadURL();
      print('Profile picture URL: $url');
      return url;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null; // Skip profile pic instead of hanging
    }
  }

  // SignUp Function
  Future<void> signUp() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();
    final mobile = mobileController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPass.isEmpty ||
        mobile.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (password != confirmPass) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final uid = userCredential.user!.uid;
      print('User created: $uid');

      // 2️⃣ Upload profile picture (safe)
      final profileUrl = await uploadProfilePic(uid);

      // 3️⃣ Save Firestore document
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'mobile': mobile,
        'profilePicUrl': profileUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('User document created in Firestore');

      // ✅ Registration successful, navigate to login
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful!')));
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} ${e.message}');
      String message = 'Sign up failed';
      if (e.code == 'email-already-in-use') message = 'Email already registered';
      if (e.code == 'weak-password') message = 'Password too weak';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      print('Sign up general error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Sign up failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: kIsWeb
                    ? (_webImage != null ? MemoryImage(_webImage!) : null)
                    : (_imageFile != null ? FileImage(_imageFile!) : null)
                as ImageProvider<Object>?,
                child: ((kIsWeb && _webImage == null) ||
                    (!kIsWeb && _imageFile == null))
                    ? Icon(Icons.add_a_photo, size: 50)
                    : null,
              ),
            ),
            SizedBox(height: 20),
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
            TextField(controller: mobileController, decoration: InputDecoration(labelText: 'Mobile Number'), keyboardType: TextInputType.phone),
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            TextField(controller: confirmPasswordController, decoration: InputDecoration(labelText: 'Confirm Password'), obscureText: true),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: signUp, child: Text('Register')),
          ],
        ),
      ),
    );
  }
}
