import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> login() async {
    setState(() => _isLoading = true);

    final error = await _authService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (error == null) {
      // Access granted
      Navigator.pushReplacementNamed(context, '/profile');
    } else {
      // Access denied / error
      final isVerifyMsg = error.toLowerCase().contains('verify your email');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(child: Text(error)),
              if (isVerifyMsg)
                TextButton(
                  onPressed: () async {
                    final resendErr =
                    await _authService.resendVerificationEmail();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          resendErr ?? 'Verification email sent again.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Resend'),
                ),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onSubmitted: (_) => login(),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: login, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}
