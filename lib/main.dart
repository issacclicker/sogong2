import 'loading_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AuditListPage.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'firebase_options.dart'; // firebase_options.dart 임포트
import 'package:intl/date_symbol_data_local.dart';
import 'theme.dart'; // Import the theme file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ko_KR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Memo App',
      theme: appTheme(), // Use the custom theme
      initialRoute: '/loading',
      routes: {
        '/loading': (context) => LoadingPage(),
        '/': (context) => const RootPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/audits': (context) => const AuditListPage(),
      },
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return const AuditListPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
