
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/formatter.dart';
import '../services/session_service.dart';
import '../services/notification_service.dart';
import '../dashboardf/notifications.dart';
import '../services/api_config.dart';

PreferredSizeWidget myAppBar(String? title, {int? playerId, String? firstName}) {
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
    iconTheme: const IconThemeData(color: Colors.white, size: 30),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 15.0),
        child: NotificationBadge(
          playerId: playerId,
          firstName: firstName,
        ),
      ),
    ],
  );
}

class myDrawer extends StatelessWidget {
  const myDrawer({super.key});
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
  final bool compact;
  const PlayerBalanceWidget({super.key, this.playerId, this.compact = false});

  static final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);
  static void refresh() {
    refreshNotifier.value++;
  }

  @override
  State<PlayerBalanceWidget> createState() => _PlayerBalanceWidgetState();
}

class _PlayerBalanceWidgetState extends State<PlayerBalanceWidget> {
  double _balance = 0.0;
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _fetchBalance();
    PlayerBalanceWidget.refreshNotifier.addListener(_fetchBalance);
  }

  @override
  void dispose() {
    PlayerBalanceWidget.refreshNotifier.removeListener(_fetchBalance);
    super.dispose();
  }

  Future<void> _fetchBalance() async {
    final effectivePlayerId = widget.playerId ?? SessionService().playerId;
    if (effectivePlayerId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/payments/stats?playerId=$effectivePlayerId'));
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true && payload['data'] != null) {
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
      debugPrint('Error fetching balance: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Credits: ',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            Text(
              _isLoading ? '...' : CurrencyFormatter.format(_balance),
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

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
            _isLoading ? 'Loading...' : CurrencyFormatter.format(_balance),
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

class NotificationBadge extends StatefulWidget {
  final int? playerId;
  final String? firstName;
  final Color iconColor;
  final Color badgeColor;

  const NotificationBadge({
    super.key,
    this.playerId,
    this.firstName,
    this.iconColor = Colors.white,
    this.badgeColor = Colors.red,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _unreadCount = 0;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    final effectivePlayerId = widget.playerId ?? SessionService().playerId;
    if (effectivePlayerId == null) return;

    final count = await _notificationService.fetchUnreadCount(effectivePlayerId);
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectivePlayerId = widget.playerId ?? SessionService().playerId;
    final effectiveFirstName = widget.firstName ?? SessionService().firstName ?? 'User';

    return GestureDetector(
      onTap: () {
        if (effectivePlayerId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationScreen(
                playerId: effectivePlayerId,
                firstName: effectiveFirstName,
              ),
            ),
          ).then((_) => _fetchUnreadCount());
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
            child: Icon(
              Icons.notifications_none,
              color: widget.iconColor,
              size: 22,
            ),
          ),
          if (_unreadCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.badgeColor,
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
    );
  }
}
