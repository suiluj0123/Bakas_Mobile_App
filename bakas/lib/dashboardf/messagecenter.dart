import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_drawer.dart';

class MessageCenterPage extends StatefulWidget {
  final int? playerId;
  final String? firstName;

  const MessageCenterPage({Key? key, this.playerId, this.firstName}) : super(key: key);

  @override
  State<MessageCenterPage> createState() => _MessageCenterPageState();
}

class _MessageCenterPageState extends State<MessageCenterPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<dynamic> _messages = [];
  List<bool> _selected = [];
  bool _isLoading = true;
  String _searchQuery = "";

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    if (widget.playerId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${_apiBaseUrl()}/api/messages/${widget.playerId}'),
      );

      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          final List<dynamic> fetchedMessages = payload['data'] ?? [];
          if (mounted) {
            setState(() {
              _messages = fetchedMessages;
              _selected = List.generate(_messages.length, (index) => false);
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead() async {
    for (int i = 0; i < _selected.length; i++) {
      if (_selected[i]) {
        final messageId = _messages[i]['id'];
        try {
          await http.put(Uri.parse('${_apiBaseUrl()}/api/messages/$messageId/read'));
        } catch (e) {
          debugPrint('Error marking as read: $e');
        }
      }
    }
    _fetchMessages();
  }

  Future<void> _deleteMessages() async {
    for (int i = 0; i < _selected.length; i++) {
      if (_selected[i]) {
        final messageId = _messages[i]['id'];
        try {
          await http.delete(Uri.parse('${_apiBaseUrl()}/api/messages/$messageId'));
        } catch (e) {
          debugPrint('Error deleting message: $e');
        }
      }
    }
    _fetchMessages();
  }

  List<dynamic> get _filteredMessages {
    if (_searchQuery.isEmpty) return _messages;
    return _messages.where((m) => 
      (m['message'] ?? "").toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        playerId: widget.playerId,
        firstName: widget.firstName,
        onRefresh: _fetchMessages,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B0000), Color.fromARGB(255, 235, 112, 112)],
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 238, 244, 192).withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color.fromARGB(255, 242, 245, 157).withOpacity(0.3),
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
              const Text(
                "Message Center",
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
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 45,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: "Search",
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: _selected.contains(true) ? _markAsRead : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 143, 143, 143),
                            ),
                            child: const Text("Mark as Read"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _selected.contains(true) ? _deleteMessages : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 153, 11, 1),
                            ),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _filteredMessages.isEmpty
                                ? const Center(child: Text("No messages found"))
                                : ListView.builder(
                                    itemCount: _filteredMessages.length,
                                    itemBuilder: (context, index) {
                                      final msg = _filteredMessages[index];
                                      final originalIndex = _messages.indexOf(msg);
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 15),
                                        child: _buildMessageCard(
                                          index: originalIndex,
                                          title: msg['message'] ?? "",
                                          date: msg['created_at'] != null 
                                            ? msg['created_at'].toString().split('T')[0]
                                            : "",
                                          isRead: msg['read'] == 1,
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

  Widget _buildMessageCard({
    required int index,
    required String title,
    required String date,
    required bool isRead,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color.fromARGB(255, 255, 245, 245),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _selected[index],
            activeColor: Colors.red,
            onChanged: (value) {
              setState(() {
                _selected[index] = value!;
              });
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    date,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

