import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'app_drawer.dart';
import '../services/session_service.dart';
import '../widgets/BakasHeader.dart';
import '../services/api_config.dart';

class TicketsUI extends StatefulWidget {
  final String? firstName;
  final int? playerId;

  const TicketsUI({super.key, this.firstName, this.playerId});

  @override
  State<TicketsUI> createState() => _TicketsUIState();
}

class _TicketsUIState extends State<TicketsUI> {
  List<dynamic> _tickets = [];
  bool _isLoading = true;
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    int? effectiveId = widget.playerId;
    if (effectiveId == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      effectiveId = args?['playerId'] ?? SessionService().playerId;
    }

    if (effectiveId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (mounted && !_isLoading) setState(() => _isLoading = true);

    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/bets/player/$effectiveId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _tickets = data['data'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        firstName: widget.firstName,
        playerId: widget.playerId,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8B0000),
              Color(0xFFF43333),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const Text(
                      "Tickets",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    NotificationBadge(
                      playerId: widget.playerId,
                      firstName: widget.firstName,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _toggleButton("Public", _isPublic, () {
                            setState(() => _isPublic = true);
                          }),
                          const SizedBox(width: 10),
                          _toggleButton("Private", !_isPublic, () {
                            setState(() => _isPublic = false);
                          }),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 38,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.search, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    "Search",
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : (() {
                                final filtered = _tickets.where((t) {
                                  final gId = t['group_id'];
                                  final gType = t['group_type']; // 1 = Public, 2 = Private
                                  
                                  if (_isPublic) {
                                    // Public tab shows groups where group_id exists and type is 1
                                    return gId != null && (gType == 1 || gType == null);
                                  } else {
                                    // Private tab shows solo bets (gId null) or private groups (type 2)
                                    return gId == null || gType == 2;
                                  }
                                }).toList();

                                if (filtered.isEmpty) {
                                  return const Center(child: Text("No tickets found"));
                                }

                                return ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final ticket = filtered[index];
                                      final rawDate = ticket['created_at'] ?? '';
                                      String formattedDate = rawDate;
                                      if (rawDate.isNotEmpty) {
                                        try {
                                          DateTime dt = DateTime.parse(rawDate).toUtc().add(const Duration(hours: 8));
                                          formattedDate = DateFormat('MMMM d, yyyy, h:mm a').format(dt);
                                        } catch (e) {
                                          formattedDate = rawDate;
                                        }
                                      }
                                      return ticketCard(
                                        context,
                                        ticket['lottery_name'] ?? 'Unknown Game',
                                        formattedDate,
                                        ticket,
                                      );
                                  },
                                );
                              })(),
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

  Widget _toggleButton(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.black : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '...';
    try {
      final dateTime = DateTime.parse(dateStr).toUtc().add(const Duration(hours: 8));
      return DateFormat('MMMM d, yyyy, h:mm a').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  Widget ticketCard(BuildContext context, String title, String date, dynamic ticketData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TicketDetailsScreen(ticket: ticketData),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF8B0000)),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Color(0xFF8B0000),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B0000).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    ticketData['status']?.toUpperCase() ?? 'PENDING',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B0000),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (ticketData['group_name'] != null) ...[
              Text(
                "Group: ${ticketData['group_name']}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
              ),
              const SizedBox(height: 5),
            ],
            Text(
              "Bet Date: ${_formatDate(ticketData['created_at'])}",
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Amount: PHP ${ticketData['amount']}",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                (() {
                  final shares = int.tryParse(ticketData['no_of_bets']?.toString() ?? '0') ?? 0;
                  if (shares > 1) {
                    return Text(
                      "$shares Shares",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B0000), fontSize: 13),
                    );
                  }
                  return const SizedBox.shrink();
                })(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TicketDetailsScreen extends StatelessWidget {
  final dynamic ticket;

  const TicketDetailsScreen({super.key, required this.ticket});

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '...';
    try {
      final dateTime = DateTime.parse(dateStr).toUtc().add(const Duration(hours: 8));
      return DateFormat('MMMM d, yyyy, h:mm a').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final winningAmount = double.tryParse(ticket['winning_amount']?.toString() ?? '0') ?? 0.0;
    final dynamic rawSelected = ticket['selected_numbers'];
    List<dynamic> selectedNumbers = [];
    if (rawSelected is List) {
      selectedNumbers = rawSelected;
    } else if (rawSelected is String) {
      try {
        selectedNumbers = jsonDecode(rawSelected);
      } catch (e) {
        selectedNumbers = rawSelected.split(',').map((s) => s.trim()).toList();
      }
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8B0000),
              Color(0xFFF43333),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "Ticket Details",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer for balance
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                 child: Column(
                                  children: [
                                    Text(
                                      ticket['lottery_name'] ?? 'Lotto',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 28,
                                        color: Color(0xFF8B0000),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "Jackpot: PHP ${NumberFormat("#,##0.00", "en_US").format(double.tryParse(ticket['prize']?.toString() ?? '0') ?? 0)}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),
                              const Divider(),
                              const SizedBox(height: 10),
                              _detailRow("Status", ticket['status']?.toUpperCase() ?? 'PENDING'),
                              _detailRow("Amount", "PHP ${(double.tryParse(ticket['amount']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}"),
                              _detailRow("Bet Date", _formatDate(ticket['created_at'])),
                               _detailRow("Draw Date", _formatDate(ticket['draw_date'])),
                              _detailRow("Game", ticket['lottery_name'] ?? 'Lotto'),
                              if (ticket['group_name'] != null)
                                _detailRow("Group Name", ticket['group_name']),
                              (() {
                                final shares = int.tryParse(ticket['no_of_bets']?.toString() ?? '0') ?? 0;
                                if (shares > 0) {
                                  return _detailRow("Bakas Shares", "$shares");
                                }
                                return const SizedBox.shrink();
                              })(),
                              const SizedBox(height: 20),
                              const Text(
                                "Selected Numbers:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: selectedNumbers.map((num) {
                                  return Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B0000),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF8B0000).withOpacity(0.3),
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        num.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 25),
                              if (winningAmount > 0)
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.emoji_events, color: Colors.green),
                                      const SizedBox(width: 10),
                                      Text(
                                        "WON: PHP $winningAmount",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 20),
                              const Center(
                                child: Text(
                                  "Note: Prize processing takes 24 hours.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B0000),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Close",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
