import 'package:flutter/material.dart';
import 'LandingPage.dart';
import 'NewUIlogin.dart';
import 'registration.dart';
import 'dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/login': (context) => const GlassLoginUI(),
        '/register': (context) => const GlassRegisterUI(),
        '/dashboard': (context) {
          final firstName = ModalRoute.of(context)?.settings.arguments as String?;
          return DashboardUI(firstName: firstName);
        },
      },
    );
  }
}
