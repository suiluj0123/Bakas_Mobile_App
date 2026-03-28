import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

//pref size widget sa appbar not widget ah
PreferredSizeWidget myAppBar(String? title) {
  return AppBar(
    title: Text(
      '$title',
      style: TextStyle(
        fontSize: 30.0,
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w700,
        color: Colors.grey[300],
      ),
    ),
    centerTitle: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white, size: 30),
    actions: [
      IconButton(
        icon: Icon(Icons.circle_notifications_rounded),
        onPressed: () {},
      ),
    ],
  );
}

class myDrawer extends StatelessWidget {
  const myDrawer({super.key});
  //drawer widget hahaha
  @override
  Widget build(BuildContext context) {
    return Drawer(
    backgroundColor: Colors.white,
    child: ListView(
      children: [
        Center(
          child: DrawerHeader(
            child: Text(
              'Bakas',
              style: TextStyle(
                fontSize: 50,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        ListTile(
          onTap: () => Navigator.pushNamed(context, '/') ,
          leading: Icon(Icons.home),
          title: const Text('Home')),
        ListTile(
          onTap: () => Navigator.pushNamed(context, '/draw-date') ,
          leading: Icon(Icons.sports_esports_outlined),
          title: const Text('Bakas')),
        ListTile(
          leading: Icon(Icons.money_rounded),
          title: const Text('Cash In/Cash Out')),
        ListTile(
          leading: Icon(Icons.book),
          title: const Text('Tickets')),
        ListTile(
          leading: Icon(Icons.history),
          title: const Text('History')),
        ListTile(
          leading: Icon(Icons.message),
          title: const Text('Message Center')),
        ListTile(
          leading: Icon(Icons.groups),
          title: const Text('Groups')),
        ListTile(
          leading: Icon(Icons.settings),
          title: const Text('Settings')),
        ListTile(
          leading: Icon(Icons.logout_rounded),
          title: const Text('Sign Out')),
      
      ],
    ),
  );
  }
}

class PlayerBalanceWidget extends StatefulWidget {
  final int? playerId;
  const PlayerBalanceWidget({super.key, this.playerId});

  @override
  State<PlayerBalanceWidget> createState() => _PlayerBalanceWidgetState();
}

class _PlayerBalanceWidgetState extends State<PlayerBalanceWidget> {
  double _balance = 0.0;
  bool _isLoading = true;

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    if (widget.playerId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final res = await http.get(Uri.parse('${_apiBaseUrl()}/api/payments/stats?playerId=${widget.playerId}'));
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          final bal = payload['data']['balance'];
          if (mounted) {
            setState(() {
              _balance = (bal is String) ? (double.tryParse(bal) ?? 0.0) : (bal as num).toDouble();
              _isLoading = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 40),
      child: Column(
        children: [
          const Text(
            'Total Credits:',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _isLoading ? 'Loading...' : '₱ ${_balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Deprecated: kept for compatibility if needed, but it's replaced.
Widget myBalance() {
  return PlayerBalanceWidget(playerId: null);
}
