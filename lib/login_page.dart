import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isEmailValid = false;
  bool isPasswordValid = false;
  bool get isFormValid => isEmailValid && isPasswordValid;

  @override
  void initState() {
    super.initState();
    emailController.addListener(() {
      setState(() {
        isEmailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text);
      });
    });
    passwordController.addListener(() {
      setState(() {
        isPasswordValid = passwordController.text.length >= 6;
      });
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() async {
    if (!isFormValid) return;

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/audits');
    } on FirebaseAuthException catch (e) {
      String message = '로그인 실패';
      if (e.code == 'user-not-found') {
        message = '등록되지 않은 이메일입니다.';
      } else if (e.code == 'wrong-password') {
        message = '비밀번호가 틀렸습니다.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: constraints.maxHeight * 0.08),
                        Text(
                          '로그인',
                          style: TextStyle(
                            fontSize: constraints.maxWidth * 0.07,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF212121),
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.05),
                        Focus(
                          child: Builder(builder: (context) {
                            final FocusNode focusNode = Focus.of(context);
                            return TextField(
                              controller: emailController,
                              decoration: InputDecoration(
                                labelText: '이메일',
                                labelStyle: const TextStyle(
                                    color: Color(0xFF212121),
                                    fontWeight: FontWeight.w400),
                                filled: focusNode.hasFocus,
                                fillColor: const Color(0xFFF9F9F9),
                                suffixIcon: isEmailValid
                                    ? const Icon(Icons.check, color: Colors.green)
                                    : null,
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFFE0E0E0), width: 1),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFF212121), width: 2),
                                ),
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.03),
                        Focus(
                          child: Builder(builder: (context) {
                            final FocusNode focusNode = Focus.of(context);
                            return TextField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: '비밀번호',
                                labelStyle: const TextStyle(
                                    color: Color(0xFF212121),
                                    fontWeight: FontWeight.w400),
                                filled: focusNode.hasFocus,
                                fillColor: const Color(0xFFF9F9F9),
                                suffixIcon: isPasswordValid
                                    ? const Icon(Icons.check, color: Colors.green)
                                    : null,
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFFE0E0E0), width: 1),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFF212121), width: 2),
                                ),
                              ),
                            );
                          }),
                        ),
                        const Spacer(),
                        AnimatedOpacity(
                          opacity: isFormValid ? 1.0 : 0.5,
                          duration: const Duration(milliseconds: 150),
                          child: TextButton(
                            onPressed: login,
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF007BFF),
                              minimumSize: Size(double.infinity, constraints.maxHeight * 0.07),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              '로그인',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                                fontSize: constraints.maxWidth * 0.04,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.02),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/signup');
                            },
                            child: Text(
                              '계정이 없으세요? 회원가입',
                              style: TextStyle(
                                color: const Color(0xFF007BFF),
                                fontSize: constraints.maxWidth * 0.035,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.03),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
