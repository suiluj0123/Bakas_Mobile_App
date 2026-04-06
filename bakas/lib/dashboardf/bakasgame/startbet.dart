import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../app_drawer.dart';
import '../../services/formatter.dart';

import '../../widgets/BakasHeader.dart';
import '../../widgets/WhiteContainer.dart';
import '../../widgets/backgroundRed.dart';
import '../../widgets/BackButton.dart';
import '../../services/session_service.dart';

class startBetPage extends StatefulWidget {
  final String? firstName;
  final int? playerId;

  const startBetPage({super.key, this.firstName, this.playerId});

  @override
  State<startBetPage> createState() => _startBetPageState();
}

class Ticket {
  int id;
  List<int> selectedNumbers;
  Ticket({required this.id, required this.selectedNumbers});
}

class _startBetPageState extends State<startBetPage> {
  List<Ticket> _tickets = [Ticket(id: 1, selectedNumbers: [])];
  int _nextTicketId = 2;
  Map<String, dynamic>? _drawDetails;
  bool _isLoadingDraw = true;
  double _balance = 0.0;
  bool _isSubmitting = false;
  final TextEditingController _betAmountController = TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    _fetchBalance();
    Future.delayed(Duration.zero, () {
      _fetchDrawDetails();
    });
  }

  @override
  void dispose() {
    _betAmountController.dispose();
    super.dispose();
  }

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Future<void> _fetchBalance() async {
    final effectivePlayerId = widget.playerId ?? SessionService().playerId;
    if (effectivePlayerId == null) return;
    try {
      final res = await http.get(Uri.parse('${_apiBaseUrl()}/api/payments/stats?playerId=$effectivePlayerId'));
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true && payload['data'] != null) {
          final bal = payload['data']['balance'];
          if (mounted) {
            setState(() {
              _balance = (bal is String) ? (double.tryParse(bal) ?? 0.0) : (bal as num).toDouble();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching balance: $e');
    }
  }

  Future<void> _fetchDrawDetails() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final drawId = args?['drawId'];
    debugPrint('startbet.dart: args=$args');
    if (drawId == null) {
      debugPrint('startbet.dart: drawId is null!');
      if (mounted) setState(() => _isLoadingDraw = false);
      return;
    }

    try {
      final url = '${_apiBaseUrl()}/api/draws/$drawId';
      debugPrint('startbet.dart: Fetching from $url');
      final res = await http.get(Uri.parse(url));
      debugPrint('startbet.dart: statusCode=${res.statusCode}');
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          if (mounted) {
            setState(() {
              _drawDetails = payload['data'];
              _isLoadingDraw = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching draw details in startbet: $e');
    }
    if (mounted) setState(() => _isLoadingDraw = false);
  }

  String _getDisplayStatus() {
    if (_drawDetails == null) return 'UPCOMING';
    final status = _drawDetails!['status']?.toString().toUpperCase() ?? 'UPCOMING';

    try {
      final cutoffDateStr = _drawDetails!['cutoff_date'];
      final drawDateStr = _drawDetails!['draw_date'];
      if (cutoffDateStr != null && drawDateStr != null) {
        final cutoffDate = DateTime.parse(cutoffDateStr).toUtc().add(const Duration(hours: 8));
        final drawDate = DateTime.parse(drawDateStr).toUtc().add(const Duration(hours: 8));
        final now = DateTime.now().toUtc().add(const Duration(hours: 8));

        if (now.isBefore(cutoffDate)) {
          return 'UPCOMING';
        } else if (now.isAfter(drawDate)) {
          return 'COMPLETED';
        } else {
          return 'ONGOING';
        }
      }
    } catch (e) {
      debugPrint('Error parsing date for status: $e');
    }
    return status;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '...';
    try {
      final dateTime = DateTime.parse(dateStr).toUtc().add(const Duration(hours: 8));
      return DateFormat('MMM dd, yyyy  hh:mm a').format(dateTime); // e.g., "Mar 17, 2026  04:00 PM"
    } catch (e) {
      if (dateStr.contains('T')) {
        return dateStr.split('T')[0];
      }
      return dateStr;
    }
  }

  Widget betTemplate(Ticket ticket, int index) {
    return Container(
      width: 320,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF8B0000), width: 2),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF8B0000),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  'Ticket ${ticket.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Icon(Icons.border_all_rounded, color: Colors.white, size: 24),
                IconButton(
                  onPressed: () {
                    if (_tickets.length > 1) {
                      setState(() => _tickets.removeAt(index));
                    }
                  },
                  icon: const Icon(Icons.delete, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(_drawDetails?['number_of_selection'] ?? 6, (i) {
                final hasValue = i < ticket.selectedNumbers.length;
                return Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF8B0000)),
                    color: hasValue ? Colors.white : Colors.transparent,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hasValue ? '${ticket.selectedNumbers[i]}' : '?',
                    style: TextStyle(
                      color: const Color(0xFF8B0000),
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Divider(color: Color(0xFF8B0000), thickness: 1, height: 25),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (_drawDetails?['end_range'] is String) ? int.tryParse(_drawDetails!['end_range']) ?? 42 : (_drawDetails?['end_range'] ?? 42),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: (((_drawDetails?['end_range'] is String) ? int.tryParse(_drawDetails!['end_range']) ?? 42 : (_drawDetails?['end_range'] ?? 42)) > 50) ? 7 : 6,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
              ),
              itemBuilder: (context, i) {
                final num = i + 1;
                final isSelected = ticket.selectedNumbers.contains(num);
                final maxSelections = _drawDetails?['number_of_selection'] ?? 6;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        ticket.selectedNumbers.remove(num);
                      } else if (ticket.selectedNumbers.length < maxSelections) {
                        ticket.selectedNumbers.add(num);
                        ticket.selectedNumbers.sort();
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF8B0000) : Colors.transparent,
                      border: Border.all(color: const Color(0xFF8B0000)),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$num',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontFamily: 'Montserrat',
                        fontSize: (((_drawDetails?['end_range'] is String) ? int.tryParse(_drawDetails!['end_range']) ?? 42 : (_drawDetails?['end_range'] ?? 42)) > 50) ? 9 : 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: OutlinedButton(
              onPressed: () => setState(() => ticket.selectedNumbers.clear()),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF8B0000)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                minimumSize: const Size(80, 30),
              ),
              child: const Text(
                'Clear',
                style: TextStyle(color: Color(0xFF8B0000), fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _submitTickets() async {
    if (widget.playerId == null) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final res = await http.post(
        Uri.parse('${_apiBaseUrl()}/api/bets/create-tickets'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'playerId': widget.playerId,
          'amountPerTicket': double.tryParse(_betAmountController.text) ?? 100, // Dynamic price
          'tickets': _tickets.map((t) => {
            'groupId': args?['groupId'] ?? 0, // Should be passed from previous screen
            'lotteryId': _drawDetails?['lottery_id'],
            'drawId': _drawDetails?['id'],
            'numbers': t.selectedNumbers
          }).toList(),
        }),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['ok']) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: Text('Tickets created! New balance: ${CurrencyFormatter.format(double.tryParse(data['newBalance'].toString()) ?? 0.0)}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(
                      context, 
                      '/tickets',
                      arguments: {
                        'playerId': widget.playerId ?? args?['playerId'],
                        'firstName': widget.firstName ?? args?['firstName'],
                      }
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to create tickets')),
          );
        }
      }
    } catch (e) {
       debugPrint('Error submitting tickets: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return backgroundRed(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: myAppBar('Bakas'),
        drawer: AppDrawer(
          firstName: widget.firstName,
          playerId: widget.playerId,
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Balance:',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      CurrencyFormatter.format(_balance),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
               WhiteContainer(
                child: _isLoadingDraw
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(15, 5, 0, 0),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: myBackbutton(),
                        ),
                      ),
                      Text(
                        _drawDetails?['game_name'] ?? 'Loading...',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w800,
                          fontSize: 35,
                          color: Color(0xFF8B0000),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Draw date: ${_formatDate(_drawDetails?['draw_date'])}',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Cut-off date: ${_formatDate(_drawDetails?['cutoff_date'])}',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Status: ${_getDisplayStatus()}',
                        style: const TextStyle( 
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Prize: ${CurrencyFormatter.formatJackpot(_drawDetails?['prize'])} Jackpot Prize',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 5),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                        child: Divider(
                          color: Color(0xFF8B0000),
                          thickness: 1,
                          height: 20,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            const Text(
                              'Bet Amount:',
                              style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            const SizedBox(width: 15),
                            const Text(
                              'PHP ',
                              style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.green),
                            ),
                            SizedBox(
                              width: 80,
                              height: 30,
                              child: TextField(
                                controller: _betAmountController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.green),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: const BorderSide(color: Colors.green),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: const BorderSide(color: Colors.green),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20, top: 10),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _tickets.add(Ticket(id: _nextTicketId++, selectedNumbers: []));
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF8B0000)),
                            label: const Text(
                              'Add Another Ticket',
                              style: TextStyle(color: Colors.black, fontFamily: 'Montserrat', fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF8B0000)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 700,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: _tickets.length,
                          itemBuilder: (context, index) => betTemplate(_tickets[index], index),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitTickets,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B0000),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 5,
                          ),
                          child: _isSubmitting 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                            'Create Tickets',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
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
