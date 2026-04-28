import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../app_drawer.dart';
import '../../widgets/BakasHeader.dart';
import '../../widgets/WhiteContainer.dart';
import '../../widgets/backgroundRed.dart';
import '../../widgets/BackButton.dart';
import '../../services/formatter.dart';
import '../../services/api_config.dart';

class chooseGamePage extends StatefulWidget {
  final String? firstName;
  final int? playerId;

  const chooseGamePage({super.key, this.firstName, this.playerId});

  @override
  State<chooseGamePage> createState() => _chooseGameState();
}
Future<void> myModalPublic(BuildContext context, int? playerId, String? firstName, {String? gameName, int? drawId, int? lotteryId}) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          '${gameName ?? 'Lotto'} - Jackpot',
          style: const TextStyle(fontSize: 18, fontFamily: 'Montserrat', fontWeight: FontWeight.w600, color: Colors.black),
        ),
        content: const Text(
          'Are you sure to proceed\nin public group?',
          style: TextStyle(fontSize: 15, fontFamily: 'Montserrat', fontWeight: FontWeight.w500, color: Colors.black),
        ),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[50], fixedSize: Size(130, 50)),
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Disagree",
              style: TextStyle(fontSize: 18, fontFamily: 'Montserrat', fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue, fixedSize: Size(130, 50)),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/public-group',
                arguments: {
                  'playerId': playerId, 
                  'firstName': firstName,
                  'drawId': drawId,
                  'lotteryId': lotteryId,
                },
              );
            },
            child: Text(
              "Agree",
              style: TextStyle(fontSize: 18, fontFamily: 'Montserrat', fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ),
        ],
      );
    },
  );
}

//modal choose game private page🐈‍⬛
Future<void> myModalPrivate(BuildContext context, int? playerId, String? firstName, {String? gameName, int? drawId, int? lotteryId}) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          '${gameName ?? 'Lotto'} - Jackpot',
          style: const TextStyle(fontSize: 18, fontFamily: 'Montserrat', fontWeight: FontWeight.w600, color: Colors.black),
        ),
        content: const Text(
          'Are you sure to proceed\nin private group?',
          style: TextStyle(fontSize: 15, fontFamily: 'Montserrat', fontWeight: FontWeight.w500, color: Colors.black),
        ),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[50], fixedSize: Size(130, 50)),
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Disagree",
              style: TextStyle(fontSize: 18, fontFamily: 'Montserrat', fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue, fixedSize: Size(130, 50)),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/private-group',
                arguments: {
                  'playerId': playerId, 
                  'firstName': firstName,
                  'drawId': drawId,
                  'lotteryId': lotteryId,
                },
              );
            },
            child: Text(
              "Agree",
              style: TextStyle(fontSize: 18, fontFamily: 'Montserrat', fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ),
        ],
      );
    },
  );
}

class _chooseGameState extends State<chooseGamePage> {
  Map<String, dynamic>? _drawDetails;
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _fetchDrawDetails();
    });
  }

  Future<void> _fetchDrawDetails() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final drawId = args?['drawId'];
    if (drawId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/draws/$drawId'));
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          if (mounted) {
            setState(() {
              _drawDetails = payload['data'];
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching draw details: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _getDisplayStatus() {
    if (_drawDetails == null) return 'UPCOMING';
    final status = _drawDetails!['status']?.toString().toUpperCase() ?? 'UPCOMING';
    if (status == 'UPCOMING') {
      try {
        final drawDateStr = _drawDetails!['draw_date'];
        if (drawDateStr != null) {
          final drawDate = DateTime.parse(drawDateStr);
          if (DateTime.now().isAfter(drawDate)) {
            return 'ONGOING';
          }
        }
      } catch (e) {
        debugPrint('Error parsing date for status: $e');
      }
    }
    return status;
  }

  String _calculateTimeLeft(String? cutoffDateStr) {
    if (cutoffDateStr == null) return 'N/A';
    try {
      final cutoffDate = DateTime.parse(cutoffDateStr).toUtc().add(const Duration(hours: 8));
      final now = DateTime.now().toUtc().add(const Duration(hours: 8));
      final diff = cutoffDate.difference(now);
      if (diff.isNegative) return 'Closed';
      if (diff.inDays > 0) return '${diff.inDays}D ${diff.inHours % 24}H';
      if (diff.inHours > 0) return '${diff.inHours}H ${diff.inMinutes % 60}M';
      return '${diff.inMinutes}M';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '...';
    try {
      final dateTime = DateTime.parse(dateStr).toUtc().add(const Duration(hours: 8));
      return DateFormat('MMMM d, yyyy, h:mm a').format(dateTime);
    } catch (e) {
      return dateStr; // fallback to raw string if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    //red background
    return backgroundRed(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        //bakas header (1+1=11????)
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
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                  children: [
                    Container(
                      margin: EdgeInsets.fromLTRB(15, 5, 0, 0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: myBackbutton(),
                      ),
                    ),
                    Text(
                      _drawDetails?['game_name'] ?? 'Loading...',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w800,
                        fontSize: 35,
                        color: const Color(0xFF8B0000),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Draw date: ${_formatDate(_drawDetails?['draw_date'])}',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Cut-off date: ${_formatDate(_drawDetails?['cutoff_date'])}',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Time left: ${_calculateTimeLeft(_drawDetails?['cutoff_date'])}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Prize: ${CurrencyFormatter.formatJackpot(_drawDetails?['prize'])} Jackpot Prize',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                      child: Divider(
                        color: const Color(0xFF8B0000),
                        thickness: 1,
                        height: 20,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            //public group
                            GestureDetector(
                              onTap: () {
                                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                                Navigator.pushNamed(
                                  context,
                                  '/public-group',
                                  arguments: {
                                    'playerId': widget.playerId ?? args?['playerId'],
                                    'firstName': widget.firstName ?? args?['firstName'],
                                    'drawId': args?['drawId'],
                                    'lotteryId': args?['lotteryId'],
                                  },
                                );
                              },
                              child: Container(
                                margin: EdgeInsets.fromLTRB(20, 20, 20, 10),
                                padding: EdgeInsets.all(25),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B0000),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 4))
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/public_group_icon.png',
                                  width: 45,
                                  height: 45,
                                  color: Colors.white,
                                  errorBuilder: (context, error, stackTrace) => Icon(Icons.description, size: 45, color: Colors.white),
                                ),
                              ),
                            ),
                            Text(
                              'Public\nGroup',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 40),
                        //private group
                        Column(
                          children: [
                            GestureDetector( 
                              onTap: () {
                                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                                Navigator.pushNamed(
                                  context,
                                  '/private-group',
                                  arguments: {
                                    'playerId': widget.playerId ?? args?['playerId'],
                                    'firstName': widget.firstName ?? args?['firstName'],
                                    'drawId': args?['drawId'],
                                    'lotteryId': args?['lotteryId'],
                                  },
                                );
                              },
                              child: Container(
                                margin: EdgeInsets.fromLTRB(20, 20, 20, 10),
                                padding: EdgeInsets.all(25),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B0000),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 4))
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/private_group_icon.png', 
                                  width: 45,
                                  height: 45,
                                  color: Colors.white,
                                  errorBuilder: (context, error, stackTrace) => Icon(Icons.description, size: 45, color: Colors.white),
                                ),
                              ),
                            ),
                            Text(
                              'Private\nGroup',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
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
