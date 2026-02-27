import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'LandingPage.dart';
import 'NewUIlogin.dart';
import 'registration.dart';
import 'dashboard.dart';
import 'dashboardf/cash_inout.dart';
import 'dashboardf/messagecenter.dart';
import 'dashboardf/history.dart';
import 'dashboardf/groups.dart';
import 'dashboardf/grouprequest.dart';

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
      theme: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(context).textTheme,
        ),

      ),

      routes: {
        '/': (context) => const LandingPage(),
        '/login': (context) => const GlassLoginUI(),
        '/register': (context) => const GlassRegisterUI(),
        '/dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final firstName = args is String ? args : null;
          return DashboardUI(firstName: firstName);
        },
        '/cash-inout': (context) {
          final firstName = ModalRoute.of(context)?.settings.arguments as String?;
          return CashInOutPage(firstName: firstName);
        },
        '/history': (context) => const HistoryUI(),
        '/message-center': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return MessageCenterPage(
            playerId: args?['playerId'],
            firstName: args?['firstName'],
          );
        },
        '/groups': (context) => const GroupsPage(),
        '/group-request': (context) => const GroupRequestPage(),
      },
    );
  }
}
