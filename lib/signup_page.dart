import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void signUp() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("회원가입 성공"),
          content: const Text("처음 화면으로 돌아갑니다."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // dialog
                Navigator.pop(context); // signup page
              },
              child: const Text("확인"),
            )
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("에러 발생"),
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "이메일"),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "비밀번호"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: signUp,
              child: const Text("회원가입"),
            ),
          ],
        ),
      ),
    );
  }
}
