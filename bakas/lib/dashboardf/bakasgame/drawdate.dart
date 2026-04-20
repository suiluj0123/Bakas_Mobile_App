import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../app_drawer.dart';
import '../../widgets/BakasHeader.dart';
import '../../widgets/WhiteContainer.dart';
import '../../widgets/backgroundRed.dart';
import '../../widgets/BackButton.dart';
import '../../services/formatter.dart';

class DrawdatePage extends StatefulWidget {
  final String? firstName;
  final int? playerId;

  const DrawdatePage({super.key, this.firstName, this.playerId});

  @override
  State<DrawdatePage> createState() => _DrawdatePageState();
}

class _DrawdatePageState extends State<DrawdatePage> {
  DateTime today = DateTime.now();
  List<dynamic> _availableDraws = [];
  bool _isLoading = true;
  bool _isCalendarView = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = today;
    _fetchUpcomingDraws();
  }

  Future<void> _fetchUpcomingDraws() async {
    try {
      // 1. Fetch Draws
      final res = await http.get(Uri.parse('${_apiBaseUrl()}/api/draws/upcoming'));
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          final draws = payload['data'] ?? [];

          // 2. Sort Draws: Upcoming/Ongoing first, Completed last
          draws.sort((a, b) {
            String statusA = _getDisplayStatus(a['status'], a['draw_date'], a['cutoff_date']);
            String statusB = _getDisplayStatus(b['status'], b['draw_date'], b['cutoff_date']);
            bool isCompA = statusA == 'COMPLETED';
            bool isCompB = statusB == 'COMPLETED';
            if (isCompA && !isCompB) return 1;
            if (!isCompA && isCompB) return -1;
            return 0;
          });

          setState(() {
            _availableDraws = draws;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching draws or groups: $e');
    }
    setState(() => _isLoading = false);
  }

  List<dynamic> _getDrawsForDay(DateTime day) {
    return _availableDraws.where((draw) {
      if (draw['draw_date'] == null) return false;
      try {
        final statusText = _getDisplayStatus(draw['status'], draw['draw_date'], draw['cutoff_date']);
        if (statusText == 'COMPLETED') return false; // Filter out completed games

        final drawDate = DateTime.parse(draw['draw_date']).toUtc().add(const Duration(hours: 8));
        return isSameDay(drawDate, day);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Widget _buildCell(DateTime day, Color color, {bool isSelected = false, bool isToday = false}) {
    return Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B0000) : Colors.transparent,
          shape: BoxShape.circle,
          border: isToday && !isSelected ? Border.all(color: const Color(0xFF8B0000), width: 1.5) : null,
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF8B0000).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: isSelected ? Colors.white : (isToday ? const Color(0xFF8B0000) : color),
            fontWeight: (isSelected || isToday) ? FontWeight.w900 : FontWeight.w700,
            fontSize: 15,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toUpperCase()) {
      case 'UPCOMING': return Colors.blue;
      case 'OPEN': return Colors.green;
      case 'CLOSED': return Colors.red;
      case 'COMPLETED': return Colors.purple;
      case 'ONGOING': return Colors.orange;
      case 'PUBLIC': return Colors.green;
      case 'PRIVATE': return Colors.blueGrey;
      default: return Colors.orange;
    }
  }

  String _getDisplayStatus(String? status, String? drawDateStr, String? cutoffDateStr) {
    if (cutoffDateStr != null && drawDateStr != null) {
      try {
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
      } catch (e) {
        debugPrint('Error parsing dates for _getDisplayStatus: $e');
      }
    }
    return (status ?? 'UPCOMING').toUpperCase();
  }

  Future<void> _showResultsModal(BuildContext context, dynamic draw) {
    final winningNumbers = draw['winning_numbers'];
    String displayNumbers = 'Pending...';
    if (winningNumbers != null) {
      if (winningNumbers is String) {
        try {
          List<dynamic> parsed = jsonDecode(winningNumbers);
          displayNumbers = parsed.join(', ');
        } catch (e) {
          displayNumbers = winningNumbers;
        }
      } else if (winningNumbers is List) {
        displayNumbers = winningNumbers.join(', ');
      } else {
        displayNumbers = winningNumbers.toString();
      }
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('${draw['game_name']} Results', style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                color: Colors.black
              ),),
          content: Text('Winning Numbers:\n$displayNumbers', style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B0000)
              ), textAlign: TextAlign.center),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                fixedSize: const Size(130, 50)
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(
                fontSize: 18,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
                color: Colors.white
              ),),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateStr).toUtc().add(const Duration(hours: 8));
      return DateFormat('yyyy-MM-dd hh:mm a').format(dateTime);
    } catch (e) {
      if (dateStr.contains('T')) {
        return dateStr.split('T')[0];
      }
      return dateStr;
    }
  }

  String _calculateTimeLeft(String? cutoffDateStr) {
    if (cutoffDateStr == null) return 'N/A';
    try {
      final cutoffDate = DateTime.parse(cutoffDateStr).toUtc().add(const Duration(hours: 8));
      final now = DateTime.now().toUtc().add(const Duration(hours: 8));
      final diff = cutoffDate.difference(now);
      if (diff.isNegative) return 'Closed';
      if (diff.inDays > 0) return '${diff.inDays} days';
      if (diff.inHours > 0) return '${diff.inHours} hours';
      return '${diff.inMinutes} minutes';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _viewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _toggleButton("Draw List View", !_isCalendarView, () => setState(() => _isCalendarView = false)),
          const SizedBox(width: 20),
          _toggleButton("Calendar View", _isCalendarView, () => setState(() => _isCalendarView = true)),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFCDFF00) : Colors.white,
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
              color: isSelected ? Colors.black : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawCard(dynamic draw) {
    final String gameName = draw['game_name'] ?? 'Game';
    final String prize = draw['prize']?.toString() ?? '0.00';
    final String drawDate = _formatDate(draw['draw_date']);
    final String cutoffDate = _formatDate(draw['cutoff_date']);
    final String timeLeft = _calculateTimeLeft(draw['cutoff_date']);
    final statusText = _getDisplayStatus(draw['status'], draw['draw_date'], draw['cutoff_date']);
    final bool isCompleted = statusText == 'COMPLETED';
    
    // Check if game name contains 6/ for color coding or just use white/yellow
    final bool isSpecial = gameName.contains('6/45'); 

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSpecial ? const Color(0xFFFFF14D) : Colors.white,
        borderRadius: BorderRadius.circular(10), // Add rounded corners for shadow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Text(
                        gameName.replaceAll(' ', '\n'),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF333333),
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardDetail("Draw date", drawDate, isBold: true),
                      _cardDetail("Cutoff date", cutoffDate, isBold: true),
                      _cardDetail("Time left", timeLeft, color: Colors.blue),
                      _cardDetail("Prize", "${CurrencyFormatter.formatJackpot(prize)} Jackpot Prize", color: Colors.grey[700]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isCompleted)
                  _actionButton("View Result", const Color(0xFF8B0000), () {
                    _showResultsModal(context, draw);
                  })
                else ...[
                  _actionButton("Bet", const Color(0xFF4A90E2), () {
                    Navigator.pushNamed(context, '/public-group', arguments: {
                      'playerId': widget.playerId,
                      'firstName': widget.firstName,
                      'drawId': draw['id'],
                      'lotteryId': draw['lottery_id'],
                    }).then((_) => _fetchUpcomingDraws());
                  }),
                  const SizedBox(width: 8),
                  _actionButton("Private", const Color(0xFF1E3A5F), () {
                    Navigator.pushNamed(context, '/private-group', arguments: {
                      'playerId': widget.playerId,
                      'firstName': widget.firstName,
                      'drawId': draw['id'],
                      'lotteryId': draw['lottery_id'],
                    }).then((_) => _fetchUpcomingDraws());
                  }),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _cardDetail(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black, fontFamily: 'Montserrat'),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        minimumSize: const Size(80, 30),
        shape: const RoundedRectangleBorder(),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }



  //modal i2 🙈
  Future<void> myModalDD(BuildContext context, dynamic draw) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(draw['game_name'] ?? 'Game', style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                color: Colors.black
              ),),
          content: const Text('Are you sure to bet in this?', style: TextStyle(
                fontSize: 15,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
                color: Colors.black
              ),),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[50],
                fixedSize: Size(130, 50)
              ),
              onPressed: () => Navigator.pop(context),
              child: Text("Disagree", style: TextStyle(
                fontSize: 18,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
                color: Colors.black
              ),),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                fixedSize: Size(130, 50)
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/choose-game',
                  arguments: {
                    'firstName': widget.firstName,
                    'playerId': widget.playerId,
                    'drawId': draw['id'],
                    'lotteryId': draw['lottery_id'],
                  },
                );
              } ,
              child: Text("Agree", style: TextStyle(
                fontSize: 18,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
                color: Colors.white
              ),),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    //red background 
    return backgroundRed(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        //bakas header widget ulit same lang sa iba to 
        appBar: myAppBar('Bakas'),
        drawer: AppDrawer(
          firstName: widget.firstName,
          playerId: widget.playerId,
        ),
        body: SafeArea(
          child: Column(
            children: [
              PlayerBalanceWidget(playerId: widget.playerId),
              _viewToggle(),
              Expanded(
                child: WhiteContainer(
                  child: _isCalendarView ? _buildCalendarView() : _buildDrawListView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawListView() {
    return Column(
      children: [
        const SizedBox(height: 15),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _availableDraws.isEmpty
                  ? const Center(child: Text("No upcoming games found."))
                  : ListView.builder(
                      itemCount: _availableDraws.length,
                      itemBuilder: (context, index) {
                        return _buildDrawCard(_availableDraws[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCalendarView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(15, 5, 0, 0),
            child: Align(
              alignment: Alignment.topLeft,
              child: myBackbutton(),
            ),
          ),
          const Text(
            'Choose a draw date',
            style: TextStyle(
              fontSize: 25,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w800,
              wordSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.fromLTRB(10, 5, 10, 10),
            padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: TableCalendar(
              locale: 'en_US',
              rowHeight: 90, 
              daysOfWeekHeight: 30,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                weekendStyle: TextStyle(
                  color: Color(0xFF8B0000),
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(color: Colors.transparent),
                selectedDecoration: BoxDecoration(color: Colors.transparent),
                markerDecoration: BoxDecoration(color: Colors.transparent),
                markersAlignment: Alignment.bottomCenter,
                outsideDaysVisible: false,
              ),
              calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildCell(day, Colors.black);
              },
              selectedBuilder: (context, day, focusedDay) {
                return _buildCell(day, Colors.white, isSelected: true);
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildCell(day, Colors.white, isToday: true);
              },
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return const SizedBox();
                return Positioned(
                  bottom: 6,
                  left: 2,
                  right: 2,
                  child: Column(
                    children: events.take(2).map((event) {
                      final draw = event as dynamic;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFF8B0000).withOpacity(0.15), width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (draw['game_name'] ?? 'Game').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF8B0000),
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 1),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatter.formatJackpot(draw['prize']),
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[600],
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
              firstDay: DateTime.utc(2020),
              lastDay: today.add(const Duration(days: 365)), 
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                final events = _getDrawsForDay(selectedDay);
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                
                // If there's exactly one game, show the modal directly
                if (events.length == 1) {
                  final draw = events.first;
                  final statusText = _getDisplayStatus(draw['status'], draw['draw_date'], draw['cutoff_date']);
                  if (statusText != 'COMPLETED') {
                    myModalDD(context, draw);
                  }
                }
              },
              eventLoader: _getDrawsForDay,
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Builder(
                  builder: (context) {
                    final filteredDraws = _selectedDay == null ? [] : _getDrawsForDay(_selectedDay!);
                    if (filteredDraws.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            "No games scheduled for this date.",
                            style: TextStyle(fontFamily: 'Montserrat', color: Colors.grey),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: filteredDraws.map((draw) => _buildDrawCard(draw)).toList(),
                    );
                  },
                ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
