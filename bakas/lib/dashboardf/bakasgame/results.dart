import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class ResultsUI extends StatefulWidget {
  final int? playerId;
  const ResultsUI({super.key, this.playerId});

  @override
  State<ResultsUI> createState() => _ResultsUIState();
}

class _ResultsUIState extends State<ResultsUI> {
  List<dynamic> _results = [];
  bool _isLoading = true;

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${_apiBaseUrl()}/api/draws/results'));
      if (response.statusCode == 200) {
        setState(() {
          _results = jsonDecode(response.body)['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching results: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Draw Results"),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchResults,
              child: _results.isEmpty
                  ? const Center(child: Text("No draw results found."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(15),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final r = _results[index];
                        final winningNumbers = (r['winning_numbers'] as String?)?.split(',') ?? [];
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      r['game_name'] ?? "Lotto Game",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    Text(
                                      _formatDate(r['draw_date']),
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                const SizedBox(height: 10),
                                const Text("Winning Numbers:", style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: winningNumbers.map((n) => _numberCircle(n)).toList(),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Jackpot: PHP ${r['prize'] ?? '0.00'}", 
                                      style: const TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text("COMPLETED", style: TextStyle(color: Colors.green, fontSize: 10)),
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
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return "";
    try {
      DateTime dt = DateTime.parse(raw).toLocal();
      return "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
    } catch (e) {
      return raw.split('T')[0];
    }
  }

  Widget _numberCircle(String n) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFF8B0000),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        n,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
