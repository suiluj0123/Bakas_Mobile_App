import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_drawer.dart';
import '../services/api_config.dart';

class GroupRequestPage extends StatefulWidget {
  final int? playerId;
  final String? firstName;

  const GroupRequestPage({Key? key, this.playerId, this.firstName}) : super(key: key);

  @override
  State<GroupRequestPage> createState() => _GroupRequestPageState();
}

class _GroupRequestPageState extends State<GroupRequestPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<dynamic> _invitations = [];
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _fetchInvitations();
  }

  Future<void> _fetchInvitations() async {
    if (widget.playerId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/groups/invitations/${widget.playerId}'),
      );
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          if (mounted) {
            setState(() {
              _invitations = payload['data'] ?? [];
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching invitations: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _respondToInvitation(int id, String status) async {
    try {
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/groups/invitations/$id/respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status == 'active' ? 'Invitation accepted!' : 'Invitation declined'),
              backgroundColor: status == 'active' ? Colors.green : Colors.grey,
            ),
          );
        }
        await _fetchInvitations();
      }
    } catch (e) {
      debugPrint('Error responding to invitation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        playerId: widget.playerId,
        firstName: widget.firstName,
        onRefresh: _fetchInvitations,
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Group Request",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _invitations.isEmpty
                          ? const Center(
                              child: Text("No pending invitations",
                                  style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: _invitations.length,
                              itemBuilder: (context, index) {
                                final inv = _invitations[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: _buildRequestCard(inv),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> inv) {
    final groupName = inv['group_name'] ?? inv['name'] ?? 'Unknown Group';
    final dateStr = inv['created_at'] != null
        ? inv['created_at'].toString().split('T')[0]
        : '';
    final invitedBy = inv['created_by']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
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
              Expanded(
                child: Text(
                  groupName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: inv['lotterytype_id'] == 2 ? Colors.blue.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  inv['lotterytype_id'] == 2 ? 'Private' : 'Public',
                  style: TextStyle(
                    fontSize: 11,
                    color: inv['lotterytype_id'] == 2 ? Colors.blue : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Date Request: $dateStr",
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 3),
          Text(
            "Invited by: ${inv['invited_by_name'] ?? 'Player #${inv['created_by']}'}",
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 3),
          Text(
            "Group Code: ${inv['pgroup_code'] ?? ''}",
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () => _respondToInvitation(inv['id'], 'active'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 1, 128, 5),
                  minimumSize: const Size(70, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("Accept", style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _respondToInvitation(inv['id'], 'declined'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 219, 39, 26),
                  minimumSize: const Size(70, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("Decline", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
