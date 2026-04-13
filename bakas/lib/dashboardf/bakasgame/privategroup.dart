import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/BakasHeader.dart';
import '../../widgets/WhiteContainer.dart';
import '../../widgets/backgroundRed.dart';
import '../../widgets/BackButton.dart';
import '../app_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';


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
  Timer? _chatTimer;


  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _fetchPrivateGroups();
      _fetchDrawDetails();
    });
  }


  @override
  void dispose() {
    _chatTimer?.cancel();
    super.dispose();
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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final int? playerId = widget.playerId ?? args?['playerId'];

    if (playerId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final res = await http.get(Uri.parse('${_apiBaseUrl()}/api/groups/private/available/$playerId'));
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
            _actionButton(dialogContext, "Members", () {
              Navigator.pop(dialogContext);
              _showMembersDialog(group);
            }),
            _actionButton(dialogContext, "Invite", () {
              Navigator.pop(dialogContext);
              _showInviteDialog(group);
            }),
            _actionButton(dialogContext, "Chat", () {
              Navigator.pop(dialogContext);
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              final int? playerId = widget.playerId ?? args?['playerId'];
              _showChatDialog(group, playerId);
            }),
            _actionButton(dialogContext, "Delete", () => Navigator.pop(dialogContext), isDelete: true),


          ],
        ),
      ),
    );
  }

  void _showMembersDialog(Map<String, dynamic> group) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Group Members"),
        content: FutureBuilder<http.Response>(
          future: http.get(Uri.parse('${_apiBaseUrl()}/api/groups/${group['id']}/members')),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError || snapshot.data?.statusCode != 200) {
              return Text("Error loading members");
            }
            final payload = jsonDecode(snapshot.data!.body);
            final members = payload['data'] as List<dynamic>;
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final m = members[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(m['player_name'][0])),
                    title: Text(m['player_name'] ?? 'N/A'),
                    subtitle: Text(m['status'] == 1 ? 'Active' : 'Pending'),
                  );
                },
              ),
            );
          },
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Close"))],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return "";
    try {
      DateTime dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return "";
    }
  }

  void _showChatDialog(Map<String, dynamic> group, int? playerId) {

    final TextEditingController messageController = TextEditingController();
    List<dynamic> messages = [];
    bool isSending = false;

    if (playerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: Player ID not found")));
      return;
    }


    void fetchMessages(StateSetter setDialogState) async {
      try {
        final res = await http.get(Uri.parse('${_apiBaseUrl()}/api/groups/${group['id']}/messages'));
        if (res.statusCode == 200) {
          final payload = jsonDecode(res.body);
          if (mounted) {
            setDialogState(() {
              messages = payload['data'];
            });
          }
        } else {
          debugPrint('Error: status ${res.statusCode}');
        }
      } catch (e) {
        debugPrint('Error fetching chat: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection error: Could not load messages")));
        }
      }

    }

    _chatTimer?.cancel();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (_chatTimer == null || !_chatTimer!.isActive) {
              fetchMessages(setDialogState);
              _chatTimer = Timer.periodic(Duration(seconds: 5), (timer) {
                fetchMessages(setDialogState);
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.chat_bubble, color: Color(0xFF8B0000)),
                  SizedBox(width: 10),
                  Expanded(child: Text("Chat: ${group['name']}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 300,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: messages.isEmpty
                        ? Center(child: Text("No messages yet", style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            reverse: false, 
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final bool isMe = msg['sender_id'].toString() == playerId.toString();
                              return Padding(

                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isMe) ...[
                                          Text(
                                            msg['sender_name'] ?? "Unknown",
                                            style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(width: 5),
                                        ],
                                        Text(
                                          _formatTime(msg['created_at']),
                                          style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                                        ),
                                        if (isMe) ...[
                                          SizedBox(width: 5),
                                          Text(
                                            "You",
                                            style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Container(

                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isMe ? Color(0xFF8B0000) : Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                      ),
                                      child: Text(
                                        msg['message'] ?? '',
                                        style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          ),
                        ),
                      ),
                      SizedBox(width: 5),
                      isSending
                          ? CircularProgressIndicator(strokeWidth: 2)
                          : IconButton(
                              icon: Icon(Icons.send, color: Color(0xFF8B0000)),
                              onPressed: () async {
                                if (messageController.text.trim().isEmpty) return;
                                setDialogState(() => isSending = true);
                                try {
                                  final res = await http.post(
                                    Uri.parse('${_apiBaseUrl()}/api/groups/${group['id']}/messages'),
                                    headers: {'Content-Type': 'application/json'},
                                    body: jsonEncode({
                                      'senderId': playerId,
                                      'message': messageController.text.trim(),
                                    }),
                                  );

                                  if (res.statusCode == 201) {
                                    messageController.clear();
                                    fetchMessages(setDialogState);
                                  }
                                } catch (e) {
                                  debugPrint('Send error: $e');
                                } finally {
                                  setDialogState(() => isSending = false);
                                }
                              },
                            ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _chatTimer?.cancel();
                    Navigator.pop(context);
                  },
                  child: Text("Close"),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _chatTimer?.cancel();
    });
  }


  void _showInviteDialog(Map<String, dynamic> group) {
    final searchController = TextEditingController();
    List<dynamic> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Invite Players"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text("Code: ${group['pgroup_code']}", 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: group['pgroup_code']));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Code copied to clipboard"))
                      );
                    },
                  ),
                ],
              ),
              Divider(),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Search player by name",
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () async {
                      if (searchController.text.isEmpty) return;
                      setState(() => isSearching = true);
                      try {
                        final res = await http.get(Uri.parse('${_apiBaseUrl()}/api/players/search?q=${searchController.text}'));
                        if (res.statusCode == 200) {
                          final payload = jsonDecode(res.body);
                          setState(() {
                            searchResults = payload['data'];
                            isSearching = false;
                          });
                        }
                      } catch (e) {
                        setState(() => isSearching = false);
                      }
                    },
                  ),
                ),
              ),
              if (isSearching) Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator()),
              if (!isSearching && searchResults.isNotEmpty)
                SizedBox(
                  height: 200,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final p = searchResults[index];
                      return ListTile(
                        title: Text("${p['first_name']} ${p['last_name']}"),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            final res = await http.post(
                              Uri.parse('${_apiBaseUrl()}/api/groups/${group['id']}/invite'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'player_id': p['id'],
                                'player_name': "${p['first_name']} ${p['last_name']}",
                                'invited_by': widget.playerId ?? (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['playerId'],
                              }),
                            );

                            if (res.statusCode == 200) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Invitation sent to ${p['first_name']}"))
                              );
                            }
                          },
                          child: Text("Invite", style: TextStyle(fontSize: 10)),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Close"))],
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
                    'player_id': widget.playerId ?? (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['playerId'],
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
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                final drawId = widget.drawId ?? args?['drawId'];
                final res = await http.post(
                  Uri.parse('${_apiBaseUrl()}/api/groups'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'name': nameController.text,
                    'desc': descController.text,
                    'group_type': 'Private',
                    'status': 'Active',
                    'drawdate_id': drawId,
                    'created_by': widget.playerId ?? (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['playerId'],
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
                      backgroundColor: Color(0xFF8B0000),
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
                        color: Color(0xFF8B0000),
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
                                backgroundColor: Color(0xFF8B0000),
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
                        color: const Color(0xFF8B0000),
                        thickness: 1,
                        height: 20,
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                        ? Center(child: CircularProgressIndicator(color: Color(0xFF8B0000)))
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
