import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_drawer.dart';

class HistoryUI extends StatefulWidget {
  final int? playerId;
  final String? firstName;
  const HistoryUI({super.key, this.playerId, this.firstName});

  @override
  State<HistoryUI> createState() => _HistoryUIState();
}

class _HistoryUIState extends State<HistoryUI> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedTab = 0;
  bool _isLoading = true;
  List<dynamic> _allHistory = [];
  List<dynamic> _filteredHistory = [];

  final List<String> tabs = ["Cash In", "Cash Out", "Details"];

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (widget.playerId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${_apiBaseUrl()}/history?playerId=${widget.playerId}'),
      );

      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          setState(() {
            _allHistory = payload['data'] ?? [];
            _applyFilter();
            _isLoading = false;
          });
          return;
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetching history: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      if (selectedTab == 0) {
        _filteredHistory = _allHistory.where((item) => item['type'] == 'CASH_IN').toList();
      } else if (selectedTab == 1) {
        _filteredHistory = _allHistory.where((item) => item['type'] == 'CASH_OUT').toList();
      } else {
        _filteredHistory = _allHistory;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        playerId: widget.playerId,
        firstName: widget.firstName,
        onRefresh: _fetchHistory,
      ),
      backgroundColor: const Color(0xFF7B2D2D),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Text(
                    "History",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
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
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: List.generate(
                          tabs.length,
                          (index) => Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedTab = index;
                                  _applyFilter();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8),
                                decoration: BoxDecoration(
                                  color: selectedTab == index
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    tabs[index],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: selectedTab == index
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF7B2D2D),
                              ),
                            )
                          : _filteredHistory.isEmpty
                              ? const Center(
                                  child: Text(
                                    "No history found",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  itemCount: _filteredHistory.length,
                                  itemBuilder: (context, index) {
                                    final item = _filteredHistory[index];
                                    final type = item['type'] ?? 'UNKNOWN';
                                    final dynamic rawAmount = item['amount'];
                                    final double amount = (rawAmount is String) 
                                        ? double.tryParse(rawAmount) ?? 0.0 
                                        : (rawAmount as num).toDouble();
                                    final channel = item['channel'] ?? 'N/A';
                                    final createdAt = item['created_at'] != null
                                        ? DateTime.parse(item['created_at'])
                                        : DateTime.now();
                                    final formattedDate =
                                        "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} | ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}";

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          type == 'CASH_IN'
                                              ? "Cash In Successful"
                                              : type == 'CASH_OUT'
                                                  ? "Cash Out Successful"
                                                  : "Transaction",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "Your $channel payment of ₱${amount.toStringAsFixed(2)} was processed.",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            formattedDate,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                        const Divider(
                                          color: Colors.red,
                                          thickness: 0.5,
                                        ),
                                        const SizedBox(height: 10),
                                      ],
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
    );
  }
}
