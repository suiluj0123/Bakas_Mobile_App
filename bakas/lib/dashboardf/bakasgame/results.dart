import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../services/formatter.dart';
import '../../widgets/BakasHeader.dart';
import '../../services/api_config.dart';
import '../../widgets/WhiteContainer.dart';
import '../../widgets/backgroundRed.dart';

class ResultsUI extends StatefulWidget {
  final int? playerId;
  const ResultsUI({super.key, this.playerId});

  @override
  State<ResultsUI> createState() => _ResultsUIState();
}

class _ResultsUIState extends State<ResultsUI> {
  List<dynamic> _results = [];
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/draws/results'));
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
    return backgroundRed(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: myAppBar("Draw Results", playerId: widget.playerId),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              WhiteContainer(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _fetchResults,
                        child: _results.isEmpty
                            ? const Center(child: Text("No draw results found."))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
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
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          const Divider(),
                                          const SizedBox(height: 10),
                                          const Text("Winning Numbers:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 10,
                                            alignment: WrapAlignment.center,
                                            children: winningNumbers.map((n) => _numberCircle(n)).toList(),
                                          ),
                                          const SizedBox(height: 15),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text("Jackpot: ${CurrencyFormatter.formatJackpot(r['prize'])}", 
                                                style: const TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold, fontSize: 13)),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade100,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Text("COMPLETED", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return "";
    try {
      DateTime dt = DateTime.parse(raw).toUtc().add(const Duration(hours: 8));
      return DateFormat('MMMM d, yyyy, h:mm a').format(dt);
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
