import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/BakasHeader.dart';
import '../../widgets/WhiteContainer.dart';
import '../../widgets/backgroundRed.dart';
import '../../widgets/BackButton.dart';
import '../app_drawer.dart';
import 'package:http/http.dart' as http;

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

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _fetchPublicGroups();
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

  Future<void> _fetchPublicGroups() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final drawId = widget.drawId ?? args?['drawId'];
    try {
      final url = drawId != null 
          ? '${_apiBaseUrl()}/api/groups/public?drawId=$drawId' 
          : '${_apiBaseUrl()}/api/groups/public';
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
            _actionButton(context, "Chat", () => Navigator.pop(context)),
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
                                'invited_by': widget.playerId,
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
        color: const Color.fromARGB(255, 239, 239, 239),
        border: Border.all(
          color: const Color.fromARGB(255, 255, 255, 255),
          width: 0.5,
        ),
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                group['name'] ?? 'N/A',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Open',
                   style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Text(
            group['desc'] ?? '',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Operator: ${group['created_by_name'] ?? 'Admin'}',
                    style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Code: ${group['pgroup_code'] ?? 'N/A'}',
                    style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _showGroupActions(context, group),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B0000),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  minimumSize: Size(80, 30),
                ),
                child: Text(
                  'Actions',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
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
        title: Text("Create Public Group"),
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
                    'group_type': 'Public',
                    'status': 'Active',
                    'drawdate_id': drawId,
                    'created_by': widget.playerId,
                  }),
                );
                if (res.statusCode == 201) {
                  _fetchPublicGroups();
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
                      'Public Groups',
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
                              label: Text("Create Group", style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF8B0000),
                                foregroundColor: Colors.white,
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
                              ? Center(child: Text("No public groups available"))
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
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
}
