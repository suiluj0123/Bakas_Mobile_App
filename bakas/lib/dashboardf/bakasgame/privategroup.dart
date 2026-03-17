import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../widgets/BakasHeader.dart';
import '../../widgets/WhiteContainer.dart';
import '../../widgets/backgroundRed.dart';
import '../../widgets/BackButton.dart';
import '../app_drawer.dart';
import 'package:http/http.dart' as http;

class privateGroupPage extends StatefulWidget {
  final int? playerId;
  final String? firstName;
  final int? drawId;
  final int? lotteryId;

  const privateGroupPage({super.key, this.playerId, this.firstName, this.drawId, this.lotteryId});

  @override
  State<privateGroupPage> createState() => _privateGroupPageState();
}

class _privateGroupPageState extends State<privateGroupPage> {
  List<dynamic> _groups = [];
  bool _isLoading = true;
  Map<String, dynamic>? _drawDetails;
  bool _isLoadingDraw = true;

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  @override
  void initState() {
    super.initState();
    _fetchPrivateGroups();
    Future.delayed(Duration.zero, () {
      _fetchDrawDetails();
    });
  }

  Future<void> _fetchDrawDetails() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final drawId = widget.drawId ?? args?['drawId'];
    if (drawId == null) {
      if (mounted) setState(() => _isLoadingDraw = false);
      return;
    }

    try {
      final res = await http.get(Uri.parse('${_apiBaseUrl()}/api/draws/$drawId'));
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
      debugPrint('Error fetching draw details: $e');
    }
    if (mounted) setState(() => _isLoadingDraw = false);
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

  Future<void> _fetchPrivateGroups() async {
    if (widget.playerId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final res = await http.get(Uri.parse('${_apiBaseUrl()}/api/groups/private/available/${widget.playerId}'));
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          final allGroups = payload['data'] ?? [];
          if (mounted) {
            setState(() {
              _groups = allGroups;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Widget _actionButton(BuildContext context, String text, VoidCallback onTap, {bool isDelete = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: onTap,
          child: Text(
            text,
            style: TextStyle(
              color: isDelete ? Colors.red : Colors.black,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  void _showGroupActions(BuildContext context, Map<String, dynamic> group) {
    final pageArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Text(
              '${_drawDetails?['game_name'] ?? 'Lotto'} - Jackpot',
              style: const TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              group['name'] ?? '',
              style: const TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionButton(dialogContext, "Start Bet", () {
              Navigator.pop(dialogContext);
              Navigator.pushNamed(
                dialogContext, 
                '/start-bet', 
                arguments: {
                  'groupId': group['id'],
                  'playerId': widget.playerId ?? pageArgs?['playerId'],
                  'firstName': widget.firstName ?? pageArgs?['firstName'],
                  'drawId': widget.drawId ?? pageArgs?['drawId'],
                  'lotteryId': widget.lotteryId ?? pageArgs?['lotteryId'],
                }
              );
            }),
            _actionButton(dialogContext, "Members", () => Navigator.pop(dialogContext)),
            _actionButton(dialogContext, "Invite", () => Navigator.pop(dialogContext)),
            _actionButton(dialogContext, "Chat", () => Navigator.pop(dialogContext)),
            _actionButton(dialogContext, "Delete", () => Navigator.pop(dialogContext), isDelete: true),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Join Private Group"),
        content: TextField(
          controller: codeController,
          decoration: InputDecoration(labelText: "Enter Group Code"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty) {
                final res = await http.post(
                  Uri.parse('${_apiBaseUrl()}/api/groups/join-code'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'code': codeController.text.trim(),
                    'player_id': widget.playerId,
                  }),
                );
                if (res.statusCode == 200) {
                  _fetchPrivateGroups();
                  Navigator.pop(context);
                }
              }
            },
            child: Text("Join"),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Create Private Group"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: descController, decoration: InputDecoration(labelText: "Description")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final res = await http.post(
                  Uri.parse('${_apiBaseUrl()}/api/groups'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'name': nameController.text,
                    'desc': descController.text,
                    'group_type': 'Private',
                    'status': 'Active',
                    'created_by': widget.playerId,
                  }),
                );
                if (res.statusCode == 201) {
                  _fetchPrivateGroups();
                  Navigator.pop(context);
                }
              }
            },
            child: Text("Create"),
          ),
        ],
      ),
    );
  }

  Widget groupItem(Map<String, dynamic> group) {
    return Container(
      margin: EdgeInsets.fromLTRB(30, 10, 30, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    group['name'] ?? 'N/A',
                    style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                Text(
                  group['pgroup_code'] ?? '',
                  style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              group['desc'] ?? '',
              style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created by: ${group['created_by'] == widget.playerId.toString() ? 'You' : 'Admin'}',
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 11, fontWeight: FontWeight.w500),
                ),
                if (group['is_member'] > 0)
                  ElevatedButton(
                    onPressed: () => _showGroupActions(context, group),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF910D0D),
                      minimumSize: Size(70, 25),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text('Actions', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                else
                  ElevatedButton(
                    onPressed: () async {
                      if (group['pgroup_code'] != null) {
                         final res = await http.post(
                          Uri.parse('${_apiBaseUrl()}/api/groups/join-code'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'code': group['pgroup_code'],
                            'player_id': widget.playerId,
                          }),
                        );
                        if (res.statusCode == 200) {
                          _fetchPrivateGroups();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: Size(70, 25),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text('Join', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final int? playerId = widget.playerId ?? args?['playerId'];
    final String? firstName = widget.firstName ?? args?['firstName'];

    return backgroundRed(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: myAppBar('Bakas'),
        drawer: AppDrawer(playerId: playerId, firstName: firstName),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              PlayerBalanceWidget(playerId: playerId),
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
                      _drawDetails?['game_name'] ?? 'Loading...',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w800,
                        fontSize: 35,
                        color: Color(0xFF910D0D),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Private Groups',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showCreateDialog,
                              icon: Icon(Icons.add, size: 18),
                              label: Text("Create", style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF910D0D),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showJoinDialog,
                              icon: Icon(Icons.vpn_key, size: 18),
                              label: Text("Join Code", style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                      child: Divider(
                        color: const Color(0xFF910D0D),
                        thickness: 1,
                        height: 20,
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                        ? Center(child: CircularProgressIndicator(color: Color(0xFF910D0D)))
                        : _groups.isEmpty
                          ? Center(child: Text("No private groups yet"))
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: _groups.length,
                              itemBuilder: (context, index) => groupItem(_groups[index]),
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
