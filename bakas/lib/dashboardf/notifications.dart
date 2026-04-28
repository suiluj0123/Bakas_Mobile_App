import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  final int playerId;
  final String? firstName;
  const NotificationScreen({super.key, required this.playerId, this.firstName});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _filteredNotifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  final List<String> _dateFilters = ['All', 'Today', 'This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final notifications = await _notificationService.fetchNotifications(widget.playerId);
    if (mounted) {
      setState(() {
        _allNotifications = notifications;
        _applyFilter(_selectedFilter);
        _isLoading = false;
      });
    }
  }

  void _applyFilter(String filter) {
    final now = DateTime.now();
    setState(() {
      _selectedFilter = filter;
      switch (filter) {
        case 'Today':
          _filteredNotifications = _allNotifications.where((n) {
            return n.createdAt.year == now.year &&
                n.createdAt.month == now.month &&
                n.createdAt.day == now.day;
          }).toList();
          break;
        case 'This Week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          _filteredNotifications = _allNotifications
              .where((n) => n.createdAt.isAfter(weekStart.subtract(const Duration(seconds: 1))))
              .toList();
          break;
        case 'This Month':
          _filteredNotifications = _allNotifications
              .where((n) => n.createdAt.year == now.year && n.createdAt.month == now.month)
              .toList();
          break;
        default:
          _filteredNotifications = List.from(_allNotifications);
      }
    });
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
      _loadNotifications();
    }
    // Navigate to Bakas module for game-related notifications
    if (!mounted) return;
    if (notification.type == 'upcoming' ||
        notification.type == 'ongoing' ||
        notification.type == 'result') {
      Navigator.pushNamed(
        context,
        '/draw-date',
        arguments: {
          'firstName': widget.firstName ?? '',
          'playerId': widget.playerId,
        },
      );
    }
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead(widget.playerId);
    _loadNotifications();
  }

  Future<void> _deleteNotification(NotificationModel notif) async {
    await _notificationService.deleteNotification(notif.id);
    _loadNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification deleted', style: TextStyle(fontFamily: 'Montserrat')),
          backgroundColor: const Color(0xFF910D0D),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear All Notifications',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete all notifications? This cannot be undone.',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontFamily: 'Montserrat')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF910D0D)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _notificationService.deleteAll(widget.playerId);
      _loadNotifications();
    }
  }

  Color _getAccentColor(String type) {
    switch (type) {
      case 'upcoming': return const Color(0xFF910D0D);
      case 'result': return const Color(0xFF910D0D);
      case 'ongoing': return const Color(0xFF910D0D);
      default: return const Color(0xFF910D0D);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'upcoming': return Icons.event_rounded;
      case 'result': return Icons.emoji_events_rounded;
      case 'ongoing': return Icons.timer_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFFD32F2F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Bakas',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontFamily: 'Montserrat',
            ),
          ),
          actions: [
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all as read',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: _confirmDeleteAll,
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header row
                      Padding(
                        padding: const EdgeInsets.only(left: 25, right: 16, top: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                            // Date filter dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF910D0D).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF910D0D), width: 1),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedFilter,
                                  isDense: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFF910D0D),
                                    size: 18,
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF910D0D),
                                  ),
                                  dropdownColor: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  items: _dateFilters
                                      .map(
                                        (filter) => DropdownMenuItem<String>(
                                          value: filter,
                                          child: Text(filter),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) => _applyFilter(val ?? 'All'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.fromLTRB(26, 8, 26, 0),
                        child: Divider(
                            thickness: 1, color: Color(0xFF910D0D)),
                      ),

                      const SizedBox(height: 5),

                      // Content
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF910D0D)))
                            : _filteredNotifications.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.notifications_off_outlined,
                                            size: 48,
                                            color: Colors.grey.shade400),
                                        const SizedBox(height: 10),
                                        Text(
                                          'No notifications found',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 14,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadNotifications,
                                    color: const Color(0xFF910D0D),
                                    child: ListView.builder(
                                      itemCount: _filteredNotifications.length,
                                      itemBuilder: (context, index) {
                                        final notif = _filteredNotifications[index];
                                        return Dismissible(
                                          key: Key('notif_${notif.id}'),
                                          direction: DismissDirection.endToStart,
                                          background: Container(
                                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade600,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(right: 20),
                                            child: const Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                                                SizedBox(height: 4),
                                                Text('Delete', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                          onDismissed: (_) => _deleteNotification(notif),
                                          child: _cardNotification(notif),
                                        );
                                      },
                                    ),
                                  ),
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

  Widget _cardNotification(NotificationModel notif) {
    final date = DateFormat('MMM dd, yyyy').format(notif.createdAt);
    final time = DateFormat('hh:mm a').format(notif.createdAt);

    return GestureDetector(
      onTap: () => _markAsRead(notif),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left accent bar
            Container(
              width: 5,
              height: 70,
              decoration: BoxDecoration(
                color: _getAccentColor(notif.type),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (notif.type != 'upcoming' && notif.type != 'result')
                        Icon(
                          _getTypeIcon(notif.type),
                          size: 16,
                          color: const Color(0xFF910D0D),
                        ),
                      if (notif.type != 'upcoming' && notif.type != 'result')
                        const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF910D0D),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color.fromARGB(178, 0, 0, 0),
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'Date:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
