import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/formatter.dart';

class OperatorDashboardUI extends StatefulWidget {
  final int? operatorId;
  final String? username;

  const OperatorDashboardUI({super.key, this.operatorId, this.username});

  @override
  State<OperatorDashboardUI> createState() => _OperatorDashboardUIState();
}

class _OperatorDashboardUIState extends State<OperatorDashboardUI> {
  List<dynamic> _lotteries = [];
  List<dynamic> _draws = [];
  bool _isLoading = true;

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'upcoming': return Colors.blue;
      case 'open': return Colors.green;
      case 'closed': return Colors.red;
      case 'completed': return Colors.purple;
      case 'ongoing': return Colors.orange;
      default: return Colors.orange;
    }
  }

  String _getDisplayStatus(String? status, String? drawDateStr, String? cutoffDateStr) {
    if (cutoffDateStr != null && drawDateStr != null) {
      try {
        final cutoffDate = DateTime.parse(cutoffDateStr).toUtc().add(const Duration(hours: 8));
        final drawDate = DateTime.parse(drawDateStr).toUtc().add(const Duration(hours: 8));
        final now = DateTime.now().toUtc().add(const Duration(hours: 8));

        if (now.isBefore(cutoffDate)) {
          return 'UPCOMING';
        } else if (now.isAfter(drawDate)) {
          return 'COMPLETED';
        } else {
          return 'ONGOING';
        }
      } catch (e) {
        debugPrint('Error parsing dates for _getDisplayStatus: $e');
      }
    }
    return (status ?? 'UPCOMING').toUpperCase();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '...';
    try {
      final dateTime = DateTime.parse(dateStr).toUtc().add(const Duration(hours: 8));
      return DateFormat('yyyy-MM-dd hh:mm a').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final lotResponse = await http.get(Uri.parse('${_apiBaseUrl()}/api/lotteries'));
      final drawResponse = await http.get(Uri.parse('${_apiBaseUrl()}/api/draws/upcoming'));

      if (lotResponse.statusCode == 200 && drawResponse.statusCode == 200) {
        setState(() {
          _lotteries = jsonDecode(lotResponse.body)['data'];
          _draws = jsonDecode(drawResponse.body)['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching operator data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateLotteryDialog() {
    final nameController = TextEditingController();
    final prizeController = TextEditingController();
    final rangeController = TextEditingController(text: "42");
    final selectionController = TextEditingController(text: "6");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create New Lottery"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Game Name (e.g. Lotto 6/42)")),
              TextField(controller: prizeController, decoration: const InputDecoration(labelText: "Jackpot Prize")),
              TextField(controller: rangeController, decoration: const InputDecoration(labelText: "Number Range (e.g. 42)")),
              TextField(controller: selectionController, decoration: const InputDecoration(labelText: "Balls to Select (e.g. 6)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                final response = await http.post(
                  Uri.parse('${_apiBaseUrl()}/api/operators/lotteries'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'name': nameController.text,
                    'prize': double.tryParse(prizeController.text.replaceAll(',', '')) ?? 0,
                    'start_range': 1,
                    'end_range': int.tryParse(rangeController.text) ?? 42,
                    'number_of_selection': int.tryParse(selectionController.text) ?? 6,
                    'type_of_game': 1, // Defaulting to 1 for standard lotto
                    'initial': 0, // Sending an integer since the column expects an integer
                    'remarks': 'Created via dashboard',
                    'created_by': widget.operatorId,
                  }),
                );
                if (response.statusCode == 201) {
                  Navigator.pop(ctx);
                  _fetchData();
                } else {
                  debugPrint("Failed to create lottery: ${response.body}");
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create: ${response.body}')),
                    );
                  }
                }
              } catch (e) {
                debugPrint("Exception creating lottery: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showEditLotteryDialog(dynamic lottery) {
    final nameController = TextEditingController(text: lottery['name']);
    final prizeController = TextEditingController(text: lottery['prize'].toString());
    final rangeController = TextEditingController(text: lottery['end_range'].toString());
    final selectionController = TextEditingController(text: lottery['number_of_selection'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Lottery"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Game Name")),
              TextField(controller: prizeController, decoration: const InputDecoration(labelText: "Jackpot Prize")),
              TextField(controller: rangeController, decoration: const InputDecoration(labelText: "Number Range")),
              TextField(controller: selectionController, decoration: const InputDecoration(labelText: "Balls to Select")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                final response = await http.put(
                  Uri.parse('${_apiBaseUrl()}/api/operators/lotteries/${lottery['id']}'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'name': nameController.text,
                    'prize': double.tryParse(prizeController.text.replaceAll(',', '')) ?? 0,
                    'start_range': 1,
                    'end_range': int.tryParse(rangeController.text) ?? 42,
                    'number_of_selection': int.tryParse(selectionController.text) ?? 6,
                    'type_of_game': 1, 
                    'initial': 0, 
                    'remarks': 'Updated via dashboard',
                    'updated_by': widget.operatorId,
                  }),
                );
                if (response.statusCode == 200) {
                  Navigator.pop(ctx);
                  _fetchData();
                } else {
                  debugPrint("Failed to update lottery: ${response.body}");
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update: ${response.body}')),
                    );
                  }
                }
              } catch (e) {
                debugPrint("Exception updating lottery: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _showCreateDrawDialog() {
    if (_lotteries.isEmpty) return;
    
    int? selectedLotteryId = _lotteries[0]['id'];
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Schedule New Draw (Game)"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: selectedLotteryId,
                isExpanded: true,
                items: _lotteries.map<DropdownMenuItem<int>>((l) {
                  return DropdownMenuItem<int>(value: l['id'], child: Text(l['name']));
                }).toList(),
                onChanged: (val) => setDialogState(() => selectedLotteryId = val),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: startDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Start Date (YYYY-MM-DD HH:MM:SS)",
                  hintText: "Tap to select date & time",
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      DateTime finalDateTime = DateTime(
                        pickedDate.year, pickedDate.month, pickedDate.day,
                        pickedTime.hour, pickedTime.minute,
                      );
                      startDateController.text = "${finalDateTime.year.toString().padLeft(4, '0')}-${finalDateTime.month.toString().padLeft(2, '0')}-${finalDateTime.day.toString().padLeft(2, '0')} ${finalDateTime.hour.toString().padLeft(2, '0')}:${finalDateTime.minute.toString().padLeft(2, '0')}:00";
                    }
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: endDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "End / Draw Date (YYYY-MM-DD HH:MM:SS)",
                  hintText: "Tap to select date & time",
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      DateTime finalDateTime = DateTime(
                        pickedDate.year, pickedDate.month, pickedDate.day,
                        pickedTime.hour, pickedTime.minute,
                      );
                      endDateController.text = "${finalDateTime.year.toString().padLeft(4, '0')}-${finalDateTime.month.toString().padLeft(2, '0')}-${finalDateTime.day.toString().padLeft(2, '0')} ${finalDateTime.hour.toString().padLeft(2, '0')}:${finalDateTime.minute.toString().padLeft(2, '0')}:00";
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                try {
                  final response = await http.post(
                    Uri.parse('${_apiBaseUrl()}/api/operators/draws'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'name': 'Draw for ' + selectedLotteryId.toString(),
                      'lottery_id': selectedLotteryId,
                      'draw_date': endDateController.text, // This is the end date/draw date
                      'cutoff_date': startDateController.text, // Using cutoff_date as start date based on DB schema constraints
                      'created_by': widget.operatorId,
                      'status': 'upcoming' // Ensure it's marked as upcoming so players can see it
                    }),
                  );
                  if (response.statusCode == 201) {
                    Navigator.pop(ctx);
                    _fetchData();
                  } else {
                     debugPrint('Failed to create game: ${response.body}');
                     if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to Schedule: ${response.body}')),
                        );
                     }
                  }
                } catch (e) {
                  debugPrint("Exception creating draw: $e");
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text("Schedule"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDrawDialog(dynamic draw) {
    if (_lotteries.isEmpty) return;
    
    int? selectedLotteryId = draw['lottery_id'];
    String rawDrawDate = draw['draw_date'] ?? '';
    String rawCutoffDate = draw['cutoff_date'] ?? '';
    
    final drawDateController = TextEditingController(text: rawDrawDate.contains('T') ? rawDrawDate.split('T')[0] + ' ' + rawDrawDate.split('T')[1].split('.')[0] : rawDrawDate);
    final cutoffDateController = TextEditingController(text: rawCutoffDate.contains('T') ? rawCutoffDate.split('T')[0] + ' ' + rawCutoffDate.split('T')[1].split('.')[0] : rawCutoffDate);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Edit Draw"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: selectedLotteryId,
                  isExpanded: true,
                  items: _lotteries.map<DropdownMenuItem<int>>((l) {
                    return DropdownMenuItem<int>(value: l['id'], child: Text(l['name']));
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedLotteryId = val),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cutoffDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Start / Cutoff Date (Start of Betting)",
                    hintText: "Tap to select date & time",
                  ),
                  onTap: () async {
                    DateTime initial = DateTime.now();
                    try { if (cutoffDateController.text.isNotEmpty) initial = DateTime.parse(cutoffDateController.text); } catch (_) {}
                    DateTime? pickedDate = await showDatePicker(
                      context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
                      if (pickedTime != null) {
                        DateTime finalDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                        cutoffDateController.text = "${finalDateTime.year.toString().padLeft(4, '0')}-${finalDateTime.month.toString().padLeft(2, '0')}-${finalDateTime.day.toString().padLeft(2, '0')} ${finalDateTime.hour.toString().padLeft(2, '0')}:${finalDateTime.minute.toString().padLeft(2, '0')}:00";
                      }
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: drawDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "End / Draw Date (Draw Result)",
                    hintText: "Tap to select date & time",
                  ),
                  onTap: () async {
                    DateTime initial = DateTime.now();
                    try { if (drawDateController.text.isNotEmpty) initial = DateTime.parse(drawDateController.text); } catch (_) {}
                    DateTime? pickedDate = await showDatePicker(
                      context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
                      if (pickedTime != null) {
                        DateTime finalDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                        drawDateController.text = "${finalDateTime.year.toString().padLeft(4, '0')}-${finalDateTime.month.toString().padLeft(2, '0')}-${finalDateTime.day.toString().padLeft(2, '0')} ${finalDateTime.hour.toString().padLeft(2, '0')}:${finalDateTime.minute.toString().padLeft(2, '0')}:00";
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                try {
                  final response = await http.put(
                    Uri.parse('${_apiBaseUrl()}/api/draws/${draw['id']}'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'name': 'Draw for ' + selectedLotteryId.toString(),
                      'draw_date': drawDateController.text,
                      'cutoff_date': cutoffDateController.text,
                      'lottery_id': selectedLotteryId,
                      'updated_by': widget.operatorId,
                    }),
                  );
                  if (response.statusCode == 200) {
                    Navigator.pop(ctx);
                    _fetchData();
                  } else {
                    debugPrint('Failed to update draw: ${response.body}');
                    if (mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('Failed to Update: ${response.body}')),
                       );
                    }
                  }
                } catch (e) {
                  debugPrint("Exception updating draw: $e");
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteDraw(dynamic draw) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Game"),
        content: Text("Are you sure you want to delete Draw #${draw['id']} (${draw['game_name']})?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                final response = await http.delete(Uri.parse('${_apiBaseUrl()}/api/draws/${draw['id']}'));
                if (response.statusCode == 200) {
                  Navigator.pop(ctx);
                  _fetchData();
                } else {
                  debugPrint("Failed to delete draw: ${response.body}");
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${response.body}')));
                }
              } catch (e) {
                debugPrint("Exception deleting draw: $e");
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Operator Dashboard"),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _fetchData, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), icon: const Icon(Icons.logout)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Active Lotteries", style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: _showCreateLotteryDialog,
                        icon: const Icon(Icons.add),
                        label: const Text("New Game"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _lotteries.length,
                    itemBuilder: (context, index) {
                      final l = _lotteries[index];
                      return Card(
                        child: ListTile(
                          title: Text(l['name']),
                          subtitle: Text("Jackpot: ${CurrencyFormatter.formatJackpot(l['prize'])}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditLotteryDialog(l),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Upcoming Draws", style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: _showCreateDrawDialog,
                        icon: const Icon(Icons.calendar_month),
                        label: const Text("Schedule Draw"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _draws.length,
                    itemBuilder: (context, index) {
                      final d = _draws[index];
                      return Card(
                        child: ListTile(
                          title: Text("Draw #${d['id']}"),
                          subtitle: Text("Scheduled: ${_formatDate(d['draw_date'])}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(_getDisplayStatus(d['status'], d['draw_date'], d['cutoff_date'])).withOpacity(0.1), 
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: _getStatusColor(_getDisplayStatus(d['status'], d['draw_date'], d['cutoff_date'])))
                                ),
                                child: Text(
                                  _getDisplayStatus(d['status'], d['draw_date'], d['cutoff_date']), 
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(_getDisplayStatus(d['status'], d['draw_date'], d['cutoff_date'])))
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showEditDrawDialog(d),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => _deleteDraw(d),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
