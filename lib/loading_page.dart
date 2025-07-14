import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart';

class LoadingPage extends StatefulWidget {
  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    // 3초 후에 루트 페이지로 이동
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // 1단계에서 추가한 로고 이미지를 표시합니다.
        // 파일명이 다를 경우 'assets/images/your_logo.png' 와 같이 수정해주세요.
        child: Image.asset('assets/images/logo.png'),
      ),
    );
  }
}
