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

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  @override
  void initState() {
    super.initState();
    _fetchUpcomingDraws();
  }

  Future<void> _fetchUpcomingDraws() async {
    try {
      final res = await http.get(Uri.parse('${_apiBaseUrl()}/api/draws/upcoming'));
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          setState(() {
            _availableDraws = payload['data'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching draws: $e');
    }
    setState(() => _isLoading = false);
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toUpperCase()) {
      case 'UPCOMING': return Colors.blue;
      case 'OPEN': return Colors.green;
      case 'CLOSED': return Colors.red;
      case 'COMPLETED': return Colors.purple;
      case 'ONGOING': return Colors.orange;
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
                color: Color(0xFF910D0D)
              ), textAlign: TextAlign.center),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
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

  Widget availableGame(int index) {
    if (index >= _availableDraws.length) return const SizedBox();
    final draw = _availableDraws[index];
    
    String dateStr = _formatDate(draw['draw_date']);
    
    final statusText = _getDisplayStatus(draw['status'], draw['draw_date'], draw['cutoff_date']);

    return GestureDetector(
      onTap: () {
        if (statusText == 'COMPLETED') {
          _showResultsModal(context, draw);
        } else {
          myModalDD(context, draw);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          border: Border.all(
            color: const Color.fromARGB(255, 255, 255, 255),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF910D0D),
                ),
              ),
              Text(
                draw['game_name'] ?? 'Unknown Game',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Prize: PHP ${draw['prize'] ?? 0}',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(statusText).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: _getStatusColor(statusText))
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(statusText)
                      )
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                backgroundColor: Colors.lightBlue,
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
                color: Colors.black
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
          bottom: false,
          child: Column(
            children: [
              //balance 
              PlayerBalanceWidget(playerId: widget.playerId),
              WhiteContainer(
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.fromLTRB(15, 5, 0, 0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: myBackbutton(),
                      ),
                    ),
                    Text(
                      'Choose a draw date',
                      style: TextStyle(
                        fontSize: 25,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w800,
                        wordSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 10),
                    //Calendar i2
                    Container(
                      margin: EdgeInsets.fromLTRB(20, 5, 30, 10),
                      padding: EdgeInsets.fromLTRB(15, 0, 15, 15),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          left: BorderSide.none,
                          right: BorderSide.none,
                        ),
                      ),
                      child: TableCalendar(
                        locale: 'en_US',
                        rowHeight: 45,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                          ),
                          weekendStyle: TextStyle(
                            color: Color(0xFF910D0D),
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          todayDecoration: const BoxDecoration(
                            color:  Color(0xFF910D0D),
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: Color.fromARGB(255, 177, 71, 71),
                          ),
                        ),
                        firstDay: DateTime.utc(2020),
                        lastDay: today,
                        focusedDay: DateTime.now(),
                      ),
                    ),
                    //Expanded list ng available games
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _availableDraws.isEmpty
                              ? const Center(child: Text("No upcoming games found."))
                              : ListView.builder(
                                  itemCount: _availableDraws.length,
                                  itemBuilder: (context, index) {
                                    return availableGame(index);
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
