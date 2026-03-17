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
import 'dashboardf/bakasgame/bakas.dart';
import 'dashboardf/bakasgame/choosegame.dart';
import 'dashboardf/settingsBakas/settings.dart';
import 'dashboardf/settingsBakas/wallet.dart';
import 'dashboardf/settingsBakas/security.dart';
import 'dashboardf/tickets.dart';
import 'dashboardf/bakasgame/drawdate.dart';
import 'dashboardf/bakasgame/publicgroup.dart';
import 'dashboardf/bakasgame/privategroup.dart';
import 'dashboardf/bakasgame/startbet.dart';
import 'dashboardf/bakasgame/results.dart';
import 'operator/operator_dashboard.dart';




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
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return DashboardUI(
            firstName: args?['firstName'],
            playerId: args?['playerId'],
          );
        },
        '/cash-inout': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return CashInOutPage(
            firstName: args?['firstName'],
            playerId: args?['playerId'],
          );
        },
        '/history': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return HistoryUI(
            firstName: args?['firstName'],
            playerId: args?['playerId'],
          );
        },
        '/message-center': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return MessageCenterPage(
            playerId: args?['playerId'],
            firstName: args?['firstName'],
          );
        },
        '/groups': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return GroupsPage(
            playerId: args?['playerId'],
            firstName: args?['firstName'],
          );
        },
        '/group-request': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return GroupRequestPage(
            playerId: args?['playerId'],
            firstName: args?['firstName'],
          );
        },
        '/bakas': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return BakasPage(
            firstName: args?['firstName'],
            playerId: args?['playerId'],
          );
        },
        '/choose-game': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return chooseGamePage(
            firstName: args?['firstName'],
            playerId: args?['playerId'],
          );
        },
        '/setting': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return settingPage(
            firstName: args?['firstName'],
            playerId: args?['playerId'],
          );
        },
        '/wallet': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return walletPage(
            firstName: args?['firstName'],
            playerId: args?['playerId'],
          );
        },
        '/security': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return securityPage(
            firstName: args?['firstName'],
            playerId: args?['playerId'],
          );
        },
        '/tickets': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return TicketsUI(
            firstName: args?['firstName'],
            playerId: args?['playerId'],
          );
        },
        '/draw-date': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return DrawdatePage(
            firstName: args?['firstName'],
            playerId: args?['playerId'],
          );
        },
        '/public-group': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return publicGroupPage(
            firstName: args?['firstName'],
            playerId: args?['playerId'],
          );
        },
        '/private-group': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return privateGroupPage(
            firstName: args?['firstName'],
            playerId: args?['playerId'],
          );
        },
        '/start-bet': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return startBetPage(
            firstName: args?['firstName'],
            playerId: args?['playerId'],
          );
        },
        '/operator-login': (context) => const GlassLoginUI(),
        '/operator-dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return OperatorDashboardUI(
            operatorId: args?['operatorId'],
            username: args?['username'],
          );
        },
        '/results': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ResultsUI(
            playerId: args?['playerId'],
          );
        },
      },
    );
  }
}


