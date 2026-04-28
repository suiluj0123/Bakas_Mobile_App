import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/BakasHeader.dart';
import '../../widgets/WhiteContainer.dart';
import '../../widgets/backgroundRed.dart';
import '../../widgets/BackButton.dart';
import '../app_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../services/formatter.dart';
import '../../services/api_config.dart';


class publicGroupPage extends StatefulWidget {
  final int? playerId;
  final String? firstName;
  final int? drawId;
  final int? lotteryId;

  const publicGroupPage({super.key, this.playerId, this.firstName, this.drawId, this.lotteryId});

  @override
  State<publicGroupPage> createState() => _publicGroupPageState();
}


class _publicGroupPageState extends State<publicGroupPage> {
  List<dynamic> _groups = [];
  bool _isLoading = true;
  Map<String, dynamic>? _drawDetails;
  bool _isLoadingDraw = true;
  Timer? _chatTimer;
  final Map<int, int> _selectedQuantities = {};
  double _playerBalance = 0.0;



  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _fetchPublicGroups();
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
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/draws/$drawId'));
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
      return dateStr;
    }
  }

  Future<void> _fetchPublicGroups() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final drawId = widget.drawId ?? args?['drawId'];
    final lotteryId = widget.lotteryId ?? args?['lotteryId'];
    final playerId = widget.playerId ?? args?['playerId'];
    try {
      String url = '${ApiConfig.baseUrl}/api/groups/public?';
      if (drawId != null) url += 'drawId=$drawId&';
      if (lotteryId != null) url += 'lotteryId=$lotteryId&';
      if (playerId != null) url += 'playerId=$playerId';
      
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          if (mounted) setState(() => _groups = payload['data'] ?? []);
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _getSystemName(dynamic systemId) {
    if (systemId == null) return "Standard";
    final s = int.tryParse(systemId.toString()) ?? 1;
    switch (s) {
      case 1: return "System 7";
      case 2: return "System 8";
      case 3: return "System 9";
      case 4: return "System 10";
      case 5: return "System 11";
      case 6: return "System 12";
      default: return "Standard";
    }
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
            _actionButton(context, "Delete", () => Navigator.pop(context), isDelete: true),


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
          future: http.get(Uri.parse('${ApiConfig.baseUrl}/api/groups/${group['id']}/members')),
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
        final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/groups/${group['id']}/messages'));
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
                                    Uri.parse('${ApiConfig.baseUrl}/api/groups/${group['id']}/messages'),
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
                        final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/players/search?q=${searchController.text}'));
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
                              Uri.parse('${ApiConfig.baseUrl}/api/groups/${group['id']}/invite'),
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

  Widget publicGroupItem(Map<String, dynamic> group) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E9D5),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                group['name'] ?? 'GROUP',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Text(
                '${group['game_name'] ?? 'Draw'} - ${_formatDate(group['draw_date'])}',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'System Games: ${_getSystemName(group['system_id'])}',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statColumn("Group Bets Target", "${group['target_bets'] ?? 0}")),
              Expanded(child: _statColumn("Total Group Bets", "${group['total_bets'] ?? 0}")),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _statColumn("Your Max Bets", "${group['max_per'] ?? 0}")),
              Expanded(child: _statColumn("Price per Bakas", "PHP ${group['price_per_share'] ?? 0}")),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _statColumn("Your Total Bets", "${group['player_total_bets'] ?? 0}")),
              Expanded(child: Container()), 
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            "Group Lotto Numbers:",
            style: TextStyle(fontFamily: 'Montserrat', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (group['gen_numbers'] as String? ?? '').split(',').where((s) => s.trim().isNotEmpty).map((n) => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1)
              ),
              child: Text(
                n.trim(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )).toList(),
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [],
                ),
              ),
              DropdownButton<int>(
                value: _selectedQuantities[group['id']] ?? 1,
                items: List.generate(
                  (() {
                    final target = double.tryParse(group['target_bets']?.toString() ?? '0') ?? 0;
                    final total = double.tryParse(group['total_bets']?.toString() ?? '0') ?? 0;
                    final maxPer = double.tryParse(group['max_per']?.toString() ?? '10') ?? 10;
                    final alreadyBet = double.tryParse(group['player_total_bets']?.toString() ?? '0') ?? 0;
                    
                    final globalLeft = (target - total).clamp(0.0, target);
                    final playerLeft = (maxPer - alreadyBet).clamp(0.0, maxPer);
                    
                    final limit = (globalLeft < playerLeft ? globalLeft : playerLeft).toInt();
                    return limit > 0 ? limit : 1; // Show at least 1 in list if limit is 0 but we want to avoid crash
                  })(),
                  (index) => DropdownMenuItem(value: index + 1, child: Text("${index + 1}", style: const TextStyle(fontSize: 12))),
                ).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedQuantities[group['id']] = val);
                },
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                   final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                   final playerId = widget.playerId ?? args?['playerId'];
                   final quantity = _selectedQuantities[group['id']] ?? 1;
                   
                   final confirm = await showDialog<bool>(
                     context: context,
                     builder: (context) => AlertDialog(
                       title: const Text("Confirm Bakas"),
                       content: Text("Are you sure you want to bet $quantity shares for PHP ${(quantity * (double.tryParse(group['price_per_share']?.toString() ?? '0') ?? 0)).toStringAsFixed(2)}?"),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                         ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Confirm")),
                       ],
                     ),
                   );

                   if (confirm == true) {
                     try {
                       final res = await http.post(
                         Uri.parse('${ApiConfig.baseUrl}/api/bets/bakas-public'),
                         headers: {'Content-Type': 'application/json'},
                         body: jsonEncode({
                           'playerId': playerId,
                           'groupId': group['id'],
                           'requestedShares': quantity,
                         }),
                       );
                        if (res.statusCode == 200) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bakas successful!")));
                          _fetchPublicGroups(); // Refresh group data
                          PlayerBalanceWidget.refresh(); // Automatically update balance in header
                        } else {
                         final payload = jsonDecode(res.body);
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(payload['message'] ?? "Error placing bet")));
                       }
                     } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection error: $e")));
                     }
                   }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B0000),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'BAKAS',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 9, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 11, color: Colors.black, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final numbersController = TextEditingController();
    final targetBetsController = TextEditingController();
    final maxPerController = TextEditingController();
    final priceController = TextEditingController();
    int selectedSystem = 6;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Create Public Group"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Group Code (e.g. LVCP-A)")),
                TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
                TextField(controller: numbersController, decoration: const InputDecoration(labelText: "Lotto Numbers (comma separated)")),
                DropdownButtonFormField<int>(
                  value: selectedSystem,
                  decoration: const InputDecoration(labelText: "System Game"),
                  items: [6, 7, 8, 9, 10, 11, 12].map((s) => DropdownMenuItem(value: s, child: Text("System $s"))).toList(),
                  onChanged: (val) => setDialogState(() => selectedSystem = val!),
                ),
                TextField(controller: targetBetsController, decoration: const InputDecoration(labelText: "Group Bets Target (Total Shares)"), keyboardType: TextInputType.number),
                TextField(controller: maxPerController, decoration: const InputDecoration(labelText: "Player Max Bets"), keyboardType: TextInputType.number),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price per Bakas (PHP)"), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                  final drawId = widget.drawId ?? args?['drawId'];
                  final res = await http.post(
                    Uri.parse('${ApiConfig.baseUrl}/api/groups'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'name': nameController.text,
                      'desc': descController.text,
                      'group_type': 'Public',
                      'status': 'Active',
                      'drawdate_id': drawId,
                      'created_by': widget.playerId ?? (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['playerId'],
                      'gen_numbers': numbersController.text,
                      'system_id': selectedSystem,
                      'target_bets': int.tryParse(targetBetsController.text) ?? 100,
                      'max_per': int.tryParse(maxPerController.text) ?? 10,
                      'price_per_share': double.tryParse(priceController.text) ?? 25.0,
                    }),
                  );

                  if (res.statusCode == 201) {
                    _fetchPublicGroups();
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text("Create"),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PlayerBalanceWidget(playerId: playerId, compact: true),
                  ],
                ),
              ),
              WhiteContainer(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: myBackbutton(),
                      ),
                    ),
                    Text(
                      _drawDetails?['game_name'] ?? 'Loading...',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                        color: Color(0xFF3B1E08),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (!_isLoadingDraw && _drawDetails != null) ...[
                      _drawDetailRow("Draw date", _formatDate(_drawDetails!['draw_date'])),
                      _drawDetailRow("Cut-off date", _formatDate(_drawDetails!['cutoff_date'])),
                      _drawDetailRow("Time left", _calculateTimeLeft(_drawDetails!['cutoff_date'])),
                      _drawDetailRow("Prize", "PHP ${CurrencyFormatter.formatJackpot(_drawDetails!['prize'])} Jackpot Prize"),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
                      child: Divider(color: const Color(0xFF8B0000), thickness: 0.5),
                    ),
                    Expanded(
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator(color: const Color(0xFF8B0000)))
                          : _groups.isEmpty
                              ? const Center(child: Text("No public groups available"))
                              : ListView.builder(
                                  padding: const EdgeInsets.only(top: 10),
                                  itemCount: _groups.length,
                                  itemBuilder: (context, index) => publicGroupItem(_groups[index]),
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

  Widget _drawDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, color: Colors.black),
          children: [
            TextSpan(text: "$label:  ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
