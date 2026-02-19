import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboardf/cash_inout.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardUI(),
    );
  }
}

class DashboardUI extends StatefulWidget {
  final String? firstName;
  final int? playerId;
  
  const DashboardUI({super.key, this.firstName, this.playerId});

  @override
  State<DashboardUI> createState() => _DashboardUIState();
}

class _DashboardUIState extends State<DashboardUI> {
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
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${_apiBaseUrl()}/api/payments/stats?playerId=${widget.playerId}'),
      );

      if (res.statusCode == 200) {
        final payload = (res.body.isNotEmpty ? (jsonDecode(res.body) as Map<String, dynamic>) : <String, dynamic>{});
        if (payload['ok'] == true) {
          setState(() {
            _balance = (payload['data']['balance'] as num).toDouble();
            _isLoading = false;
          });
          return;
        } else {
          _showError(payload['message'] ?? 'Failed to fetch balance');
        }
      } else {
        _showError('Server error: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching balance: $e');
      _showError('Connection error: Dashboard balance fetch failed');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userFirstName = widget.firstName ?? 
        (ModalRoute.of(context)?.settings.arguments as String?);
    final displayName = (userFirstName != null && userFirstName.isNotEmpty) 
        ? userFirstName 
        : 'User';
    return Scaffold(
      drawer: AppDrawer(
        firstName: displayName, 
        playerId: widget.playerId, 
        onRefresh: _fetchBalance,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8B0000),
              Color(0xFF6E0000),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Builder(
                  builder: (context) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () async {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                      // Notifications + credits chip
                      Row(
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                      
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Hi, $displayName",
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SummaryTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Total Balance',
                  value: _isLoading ? 'Loading...' : 'Php ${_balance.toStringAsFixed(2)}',
                ),
              ),

              const SizedBox(height: 30),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 30),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      DashboardButton(
                        icon: Icons.sports_esports_outlined,
                        label: "Bakas",
                      ),
                      DashboardButton(
                        icon: Icons.confirmation_num_outlined,
                        label: "Tickets",
                      ),
                      DashboardButton(
                        icon: Icons.access_time_outlined,
                        label: "History",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const DashboardButton({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 85,
          height: 85,
          decoration: BoxDecoration(
            color: const Color(0xFF8B0000),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(icon, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class AppDrawer extends StatelessWidget {
  final String? firstName;
  final int? playerId;
  final VoidCallback? onRefresh;
  
  const AppDrawer({super.key, this.firstName, this.playerId, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    // Get firstName from route arguments if not provided directly
    final userFirstName = firstName ?? 
        (ModalRoute.of(context)?.settings.arguments as String?);
    final displayName = userFirstName ?? 'User';
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF8B0000),
            ),
            child: Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),

          drawerItem(context, Icons.home, "Home", DashboardUI(firstName: displayName, playerId: playerId), isHome: true),
          drawerItem(context, Icons.sports_esports, "Bakas", const SimplePage("Bakas")),
          drawerItem(context, Icons.account_balance_wallet,
              "Cash In / Cash Out", CashInOutPage(playerId: playerId, firstName: displayName)),
          drawerItem(context, Icons.confirmation_num, "Tickets",
              const SimplePage("Tickets")),
          drawerItem(context, Icons.history, "History",
              const SimplePage("History")),
          drawerItem(context, Icons.message, "Message Center",
              const SimplePage("Message Center")),
          drawerItem(context, Icons.group, "Groups",
              const SimplePage("Groups")),
          drawerItem(context, Icons.settings, "Settings",
              const SimplePage("Settings")),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Sign Out"),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget drawerItem(
      BuildContext context, IconData icon, String title, Widget page, {bool isHome = false}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () async {
        Navigator.pop(context); // Close drawer
        
        if (isHome) {
          // If we are already on Dashboard, just close drawer.
          // Otherwise, go back to dashboard.
          if (ModalRoute.of(context)?.settings.name == '/dashboard') {
            return;
          }
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => page,
              settings: const RouteSettings(name: '/dashboard'),
            ),
            (route) => false,
          );
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
          // When returning from any page (like Cash In/Out), refresh the balance if we are on Dashboard
          if (onRefresh != null) {
            onRefresh!();
          }
        }
      },
    );
  }
}

class SimplePage extends StatelessWidget {
  final String title;

  const SimplePage(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        title: Text(title),
      ),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
