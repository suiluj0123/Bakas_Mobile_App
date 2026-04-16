import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboardf/cash_inout.dart';
import 'dashboardf/messagecenter.dart';
import 'dashboardf/history.dart';
import 'dashboardf/grouprequest.dart';
import 'dashboardf/app_drawer.dart';
import 'services/session_service.dart';
import 'services/formatter.dart';
import 'services/notification_service.dart';
import 'dashboardf/notifications.dart';

// DashboardUI widget definition starts here

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
  bool _hasFetched = false;
  int _unreadCount = 0;

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetched) {
      _fetchBalance();
      _hasFetched = true;
    }
  }

  Future<void> _fetchBalance() async {
    try {

      final route = ModalRoute.of(context);
      final args = route?.settings.arguments as Map<String, dynamic>?;
      final effectivePlayerId = widget.playerId ?? args?['playerId'] ?? SessionService().playerId;

      if (effectivePlayerId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final res = await http.get(
        Uri.parse('${_apiBaseUrl()}/api/payments/stats?playerId=$effectivePlayerId'),
      );

      // Fetch unread notifications
      final count = await NotificationService().fetchUnreadCount(effectivePlayerId);

      if (res.statusCode == 200) {
        final payload = (res.body.isNotEmpty ? (jsonDecode(res.body) as Map<String, dynamic>) : <String, dynamic>{});
        if (payload['ok'] == true && payload['data'] != null) {
          if (mounted) {
            setState(() {
              final bal = payload['data']['balance'];
              _balance = (bal is String) ? (double.tryParse(bal) ?? 0.0) : (bal as num).toDouble();
              _unreadCount = count;
              _isLoading = false;
            });
          }
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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userFirstName = widget.firstName ?? args?['firstName'] ?? SessionService().firstName;
    final userPlayerId = widget.playerId ?? args?['playerId'] ?? SessionService().playerId;
    
    final displayName = (userFirstName != null && userFirstName.isNotEmpty) 
        ? userFirstName 
        : 'User';
    return Scaffold(
      drawer: AppDrawer(
        firstName: displayName, 
        playerId: userPlayerId, 
        onRefresh: _fetchBalance,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8B0000),
              Color.fromARGB(255, 244, 51, 51),
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
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),

                    GestureDetector(
                      onTap: () {
                        if (userPlayerId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationScreen(
                                playerId: userPlayerId,
                                firstName: displayName,
                              ),
                            ),
                          ).then((_) => _fetchBalance());
                        }
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.notifications_none,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          if (_unreadCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$_unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Hello, $displayName!",
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white70,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Balance:",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isLoading ? "Loading..." : CurrencyFormatter.format(_balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                    children: [
                      DashboardButton(
                        icon: Icons.sports_esports_outlined,
                        label: "Bakas",
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/draw-date',
                            arguments: {
                              'firstName': displayName,
                              'playerId': userPlayerId,
                            },
                          ).then((_) => _fetchBalance());
                        },
                      ),
                      DashboardButton(
                        icon: Icons.confirmation_num_outlined,
                        label: "Tickets",
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/tickets',
                            arguments: {
                              'firstName': displayName,
                              'playerId': userPlayerId,
                            },
                          ).then((_) => _fetchBalance());
                        },
                      ),
                      DashboardButton(
                        icon: Icons.access_time_outlined,
                        label: "History",
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/history',
                            arguments: {
                              'firstName': displayName,
                              'playerId': userPlayerId,
                            },
                          ).then((_) => _fetchBalance());
                        },
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
  final VoidCallback onTap;

  const DashboardButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
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

