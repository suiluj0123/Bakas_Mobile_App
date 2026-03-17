import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'app_drawer.dart';

class GroupsPage extends StatefulWidget {
  final int? playerId;
  final String? firstName;

  const GroupsPage({Key? key, this.playerId, this.firstName}) : super(key: key);

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<dynamic> _myGroups = [];
  List<dynamic> _publicGroups = [];
  bool _isLoading = true;
  int _activeTab = 0; // 0: Public, 1: Private (My Groups)

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  // ─── API Calls ───────────────────────────────────────────────────

  Future<void> _fetchGroups() async {
    if (widget.playerId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      // Fetch My Groups
      final myRes = await http.get(
        Uri.parse('${_apiBaseUrl()}/api/groups/my/${widget.playerId}'),
      );
      
      // Fetch Public Groups
      final pubRes = await http.get(
        Uri.parse('${_apiBaseUrl()}/api/groups/public'),
      );

      if (mounted) {
        setState(() {
          if (myRes.statusCode == 200) {
            _myGroups = jsonDecode(myRes.body)['data'] ?? [];
          }
          if (pubRes.statusCode == 200) {
            _publicGroups = jsonDecode(pubRes.body)['data'] ?? [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching groups: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _createGroup(String name, String desc, String status, String groupType) async {
    try {
      final res = await http.post(
        Uri.parse('${_apiBaseUrl()}/api/groups'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'desc': desc,
          'status': status,
          'group_type': groupType,
          'created_by': widget.playerId,
        }),
      );
      final payload = jsonDecode(res.body);
      if (res.statusCode == 201 && payload['ok'] == true) {
        await _fetchGroups();
        return true;
      }
      // Show server error message
      if (mounted && payload['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${payload['message']}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error creating group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e'), backgroundColor: Colors.red),
        );
      }
    }
    return false;
  }

  Future<bool> _joinByCode(String code) async {
    try {
      final res = await http.post(
        Uri.parse('${_apiBaseUrl()}/api/groups/join-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'player_id': widget.playerId,
        }),
      );
      final payload = jsonDecode(res.body);
      if (res.statusCode == 200 && payload['ok'] == true) {
        await _fetchGroups();
        return true;
      }
      if (payload['message'] != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(payload['message']), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error joining group: $e');
    }
    return false;
  }

  Future<bool> _updateGroup(int id, String name, String desc, String status) async {
    try {
      final res = await http.put(
        Uri.parse('${_apiBaseUrl()}/api/groups/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'desc': desc, 'status': status}),
      );
      if (res.statusCode == 200) {
        await _fetchGroups();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating group: $e');
    }
    return false;
  }

  Future<bool> _deleteGroup(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('${_apiBaseUrl()}/api/groups/$id'),
      );
      if (res.statusCode == 200) {
        await _fetchGroups();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting group: $e');
    }
    return false;
  }

  Future<List<dynamic>> _fetchMembers(int groupId) async {
    try {
      final res = await http.get(
        Uri.parse('${_apiBaseUrl()}/api/groups/$groupId/members'),
      );
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) return payload['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching members: $e');
    }
    return [];
  }

  Future<bool> _invitePlayer(int groupId, int targetPlayerId) async {
    try {
      final res = await http.post(
        Uri.parse('${_apiBaseUrl()}/api/groups/$groupId/invite'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'player_id': targetPlayerId,
          'invited_by': widget.playerId,
        }),
      );
      final payload = jsonDecode(res.body);
      if (res.statusCode == 200 && payload['ok'] == true) return true;
      if (payload['message'] != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(payload['message']), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error inviting player: $e');
    }
    return false;
  }

  // ─── Dialogs ─────────────────────────────────────────────────────

  void showCreateDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String status = "Active";
    String groupType = "Public";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Create Group"),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: groupType,
                  decoration: const InputDecoration(labelText: "Group Type"),
                  items: ["Public", "Private"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setStateDialog(() => groupType = value!),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: "Status"),
                  items: ["Active", "Inactive"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setStateDialog(() => status = value!),
                ),
                if (groupType == "Private")
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "A unique invite code will be generated after creation.",
                              style: TextStyle(fontSize: 12, color: Colors.orange),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF202020))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                final success = await _createGroup(
                  nameController.text,
                  descController.text,
                  status,
                  groupType,
                );
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Group created!"), backgroundColor: Colors.green),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 125, 4),
            ),
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void showJoinDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Join Group"),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(labelText: "Group Code"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF121212))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty) {
                Navigator.pop(context);
                final success = await _joinByCode(codeController.text.trim());
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Joined group!"), backgroundColor: Colors.green),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 122, 4),
            ),
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  void showEditDialog(Map<String, dynamic> group) {
    final nameController = TextEditingController(text: group['name'] ?? '');
    final descController = TextEditingController(text: group['desc'] ?? '');
    String status = group['status'] ?? 'Active';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Group"),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: "Status"),
                  items: ["Active", "Inactive"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setStateDialog(() => status = value!),
                ),
                const SizedBox(height: 15),
                // Show group code for sharing
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.vpn_key, size: 18, color: Color(0xFF8B0000)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Code: ${group['pgroup_code'] ?? 'N/A'}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: group['pgroup_code'] ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Code copied!"), duration: Duration(seconds: 1)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF202020))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateGroup(group['id'], nameController.text, descController.text, status);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 118, 4),
            ),
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void showMembersDialog(Map<String, dynamic> group) async {
    final members = await _fetchMembers(group['id']);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Members — ${group['name']}"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: members.isEmpty
              ? const Center(child: Text("No members found"))
              : ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF8B0000),
                        child: Text(
                          (member['player_name'] == null || member['player_name'].toString().trim().isEmpty) 
                              ? 'U' 
                              : member['player_name'].toString().trim()[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text((member['player_name'] == null || member['player_name'].toString().trim().isEmpty)
                          ? "Player #${member['player_id']}"
                          : member['player_name']),
                      subtitle: Text("Status: ${member['status'] ?? 'active'}"),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void showInviteDialog(Map<String, dynamic> group) {
    final playerIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Invite to ${group['name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show group code to share
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.share, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Share code: ${group['pgroup_code'] ?? 'N/A'}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: group['pgroup_code'] ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Code copied!"), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                ],
              ),
            ),
            TextField(
              controller: playerIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Player ID to invite"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final targetId = int.tryParse(playerIdController.text);
              if (targetId != null) {
                Navigator.pop(context);
                final success = await _invitePlayer(group['id'], targetId);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invitation sent!"), backgroundColor: Colors.green),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 125, 4),
            ),
            child: const Text("Send Invite"),
          ),
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        playerId: widget.playerId,
        firstName: widget.firstName,
        onRefresh: _fetchGroups,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B0000), Color(0xFF6E0000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    const Icon(Icons.notifications_none, color: Colors.white),
                  ],
                ),
              ),
              const Text(
                "Groups",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                    child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _tabButton("Public", 0),
                          const SizedBox(width: 15),
                          _tabButton("Private", 1),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: showCreateDialog,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF8B0000)),
                              foregroundColor: const Color(0xFF8B0000),
                            ),
                            child: const Text("Create Group"),
                          ),
                          if (_activeTab == 1) ...[
                            const SizedBox(width: 15),
                            OutlinedButton(
                              onPressed: showJoinDialog,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF8B0000)),
                                foregroundColor: const Color(0xFF8B0000),
                              ),
                              child: const Text("Join Group"),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : (_activeTab == 0 ? _publicGroups : _myGroups).isEmpty
                                ? Center(
                                    child: Text(_activeTab == 0 
                                      ? "No public groups available." 
                                      : "No private groups yet. Create or join one!",
                                        style: const TextStyle(color: Colors.grey)))
                                : ListView.builder(
                                    itemCount: (_activeTab == 0 ? _publicGroups : _myGroups).length,
                                    itemBuilder: (context, index) {
                                      final group = (_activeTab == 0 ? _publicGroups : _myGroups)[index];
                                      return Center(
                                        child: Container(
                                          width: MediaQuery.of(context).size.width * 0.9,
                                          margin: const EdgeInsets.only(bottom: 20),
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(25),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.2),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      group['name'] ?? '',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    ),
                                                  ),
                                                  Container(
                                                    margin: const EdgeInsets.only(right: 5),
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: group['lotterytype_id'] == 2 ? Colors.blue.shade50 : Colors.orange.shade50,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      group['lotterytype_id'] == 2 ? 'Private' : 'Public',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: group['lotterytype_id'] == 2 ? Colors.blue : Colors.orange,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: (group['status'] == 'Active' || group['status'] == 0)
                                                          ? Colors.green.shade50
                                                          : Colors.grey.shade200,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      (group['status'] == 0 || group['status'] == 'Active') ? 'Active' : 'Inactive',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: (group['status'] == 'Active' || group['status'] == 0)
                                                            ? Colors.green
                                                            : Colors.grey,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                group['desc'] ?? '',
                                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                                              ),
                                              const SizedBox(height: 8),
                                              // Group code chip
                                              GestureDetector(
                                                onTap: () {
                                                  Clipboard.setData(ClipboardData(text: group['pgroup_code'] ?? ''));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text("Code copied!"),
                                                      duration: Duration(seconds: 1),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFFF3E0),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.vpn_key, size: 14, color: Colors.orange),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        group['pgroup_code'] ?? '',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.orange,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      const Icon(Icons.copy, size: 12, color: Colors.orange),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 15),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  _smallButton("Open", () => showEditDialog(group)),
                                                  _smallButton("Invite", () => showInviteDialog(group)),
                                                  _smallButton("Members", () => showMembersDialog(group)),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      final confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          title: const Text("Delete Group"),
                                                          content: Text("Delete \"${group['name']}\"?"),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(ctx, false),
                                                              child: const Text("Cancel"),
                                                            ),
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(ctx, true),
                                                              child: const Text("Delete",
                                                                  style: TextStyle(color: Colors.red)),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (confirm == true) {
                                                        await _deleteGroup(group['id']);
                                                      }
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF8B0000),
                                                    ),
                                                    child: const Text("Delete", style: TextStyle(fontSize: 12)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
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

  Widget _tabButton(String text, int index) {
    bool active = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF8B0000) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF8B0000)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF8B0000),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _smallButton(String text, VoidCallback onTap) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(60, 30),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      );
}
