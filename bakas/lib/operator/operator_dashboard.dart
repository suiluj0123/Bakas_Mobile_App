import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/formatter.dart';
import '../services/api_config.dart';

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
      return DateFormat('MMMM d, yyyy, h:mm a').format(dateTime);
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
      final lotResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/lotteries'));
      final drawResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/draws/upcoming'));

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
                  Uri.parse('${ApiConfig.baseUrl}/api/operators/lotteries'),
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
                  Uri.parse('${ApiConfig.baseUrl}/api/operators/lotteries/${lottery['id']}'),
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
                  final selectedLottery = _lotteries.firstWhere((l) => l['id'] == selectedLotteryId);
                  final response = await http.post(
                    Uri.parse('${ApiConfig.baseUrl}/api/operators/draws'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'name': selectedLottery['name'], // Using actual lottery name
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
                  final selectedLottery = _lotteries.firstWhere((l) => l['id'] == selectedLotteryId);
                  final response = await http.put(
                    Uri.parse('${ApiConfig.baseUrl}/api/draws/${draw['id']}'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'name': selectedLottery['name'], // Using actual lottery name
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
                final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/api/draws/${draw['id']}'));
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

  void _deleteLottery(dynamic lottery) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Active Game"),
        content: Text("Are you sure you want to delete '${lottery['name']}'? This will hide it from the dashboard."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/api/operators/lotteries/${lottery['id']}'));
                if (response.statusCode == 200) {
                  Navigator.pop(ctx);
                  _fetchData();
                } else {
                  debugPrint("Failed to delete lottery: ${response.body}");
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${response.body}')));
                }
              } catch (e) {
                debugPrint("Exception deleting lottery: $e");
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showEditLotteryDialog(l),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => _deleteLottery(l),
                              ),
                            ],
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
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showManageGroupsDialog(null),
                            icon: const Icon(Icons.group_work, size: 18),
                            label: const Text("Manage All Groups"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _showCreateDrawDialog,
                            icon: const Icon(Icons.calendar_month),
                            label: const Text("Schedule Draw"),
                          ),
                        ],
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
                          title: Text(d['game_name'] ?? "Draw #${d['id']}"),
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
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(_getDisplayStatus(d['status'], d['draw_date'], d['cutoff_date']))),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 22, color: Colors.green),
                                    onPressed: () => _showUpsertGroupDialog(d),
                                    tooltip: 'Add Public Group',
                                  ),
                                  Text("${d['public_group_count'] ?? 0} Bakas", 
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.group, size: 20, color: Colors.blue),
                                onPressed: () => _showManageGroupsDialog(d),
                                tooltip: 'Manage Public Groups',
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

  void _showManageGroupsDialog(dynamic draw) async {
    List<dynamic> groups = [];
    bool loading = true;

    Future<void> fetchGroups() async {
      try {
        final url = draw == null 
          ? '${ApiConfig.baseUrl}/api/groups/public' 
          : '${ApiConfig.baseUrl}/api/groups/public?drawId=${draw['id']}';
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          final payload = jsonDecode(res.body);
          groups = payload['data'] ?? [];
        }
      } catch (e) {
        debugPrint('Error fetching groups: $e');
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (loading) {
            fetchGroups().then((_) => setDialogState(() => loading = false));
            return const AlertDialog(content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())));
          }

          return AlertDialog(
            title: Text(draw == null ? "Manage All Public Groups" : "Groups for ${draw['game_name'] ?? 'Draw'}"),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (draw != null) 
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _showUpsertGroupDialog(draw);
                        setDialogState(() => loading = true);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("New Public Group"),
                    ),
                  const Divider(),
                  if (groups.isEmpty)
                    const Padding(padding: EdgeInsets.all(20), child: Text("No public groups found."))
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: groups.length,
                        itemBuilder: (context, i) {
                          final g = groups[i];
                          return ListTile(
                            title: Text("${g['name'] ?? 'GROUP'}"),
                            subtitle: Text("Game: ${g['game_name'] ?? '...'} | Draw: ${g['drawdate_id']}\nPrice: PHP ${(double.tryParse(g['price_per_share']?.toString() ?? '0') ?? 0).toStringAsFixed(2)} | Target: ${g['target_bets'] ?? 0}"),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () async {
                                    // If draw is null (Global view), we need to pass a mock draw object or fetch it
                                    // For simplicity in edit mode, we use the draw ID from the group
                                    await _showUpsertGroupDialog(draw ?? {'id': g['drawdate_id'], 'lottery_id': g['lotterytype_id']}, group: g);
                                    setDialogState(() => loading = true);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text("Delete Group"),
                                        content: const Text("Are you sure?"),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("No")),
                                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Yes")),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await http.delete(Uri.parse('${ApiConfig.baseUrl}/api/groups/${g['id']}'));
                                      setDialogState(() => loading = true);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
          );
        },
      ),
    );
  }

  Future<void> _showUpsertGroupDialog(dynamic draw, {dynamic group}) async {
    final isEdit = group != null;
    final nameController = TextEditingController(text: isEdit ? group['name'] : '');
    final descController = TextEditingController(text: isEdit ? group['desc'] : '');
    final numbersController = TextEditingController(text: isEdit ? group['gen_numbers'] : '');
    final targetController = TextEditingController(text: isEdit ? (group['target_bets']?.toString() ?? '100') : '100');
    final maxPerController = TextEditingController(text: isEdit ? (group['max_per']?.toString() ?? '10') : '10');
    final priceController = TextEditingController(text: isEdit ? (group['price_per_share']?.toString() ?? '25.0') : '25.0');
    int selectedSystem = isEdit ? (group['system_id'] ?? 6) : 6;
    bool generating = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? "Edit Public Group" : "Create Public Group"),
              if (draw != null) 
                Text(
                  "For: ${draw['game_name'] ?? 'Game'}",
                  style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.normal),
                ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Group Code")),
                TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
                Row(
                  children: [
                    Expanded(child: TextField(controller: numbersController, decoration: const InputDecoration(labelText: "Lotto Numbers"))),
                    IconButton(
                      icon: generating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome, color: Colors.orange),
                      onPressed: generating ? null : () async {
                        setDialogState(() => generating = true);
                        try {
                          final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/operators/lucky-pick/${draw['lottery_id']}'));
                          if (res.statusCode == 200) {
                            final payload = jsonDecode(res.body);
                            setDialogState(() => numbersController.text = payload['data']);
                          }
                        } catch (e) {
                          debugPrint('Lucky pick failed: $e');
                        } finally {
                          setDialogState(() => generating = false);
                        }
                      },
                      tooltip: 'Lucky Pick (Auto Generate)',
                    ),
                  ],
                ),
                DropdownButtonFormField<int>(
                  value: selectedSystem,
                  decoration: const InputDecoration(labelText: "System Game"),
                  items: const [
                    DropdownMenuItem(value: 6, child: Text("System 12")),
                    DropdownMenuItem(value: 5, child: Text("System 11")),
                    DropdownMenuItem(value: 4, child: Text("System 10")),
                    DropdownMenuItem(value: 3, child: Text("System 9")),
                    DropdownMenuItem(value: 2, child: Text("System 8")),
                    DropdownMenuItem(value: 1, child: Text("System 7")),
                  ],
                  onChanged: (val) => setDialogState(() => selectedSystem = val!),
                ),
                TextField(controller: targetController, decoration: const InputDecoration(labelText: "Target Bets"), keyboardType: TextInputType.number),
                TextField(controller: maxPerController, decoration: const InputDecoration(labelText: "Max per Player"), keyboardType: TextInputType.number),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price per Bakas"), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                try {
                  final url = isEdit ? '${ApiConfig.baseUrl}/api/groups/${group['id']}' : '${ApiConfig.baseUrl}/api/groups';
                  final body = {
                    'name': nameController.text,
                    'desc': descController.text,
                    'gen_numbers': numbersController.text,
                    'system_id': selectedSystem,
                    'target_bets': int.tryParse(targetController.text) ?? 100,
                    'max_per': int.tryParse(maxPerController.text) ?? 10,
                    'price_per_share': double.tryParse(priceController.text) ?? 25.0,
                    'status': isEdit ? (group['status'] ?? 'Active') : 'Active',
                    'drawdate_id': draw['id'],
                    'lottery_id': draw['lottery_id'],
                    if (!isEdit) ...{
                      'group_type': 'Public',
                      'lotterytype_id': 1,
                      'created_by': widget.operatorId,
                    }
                  };

                  final res = await (isEdit ? http.put : http.post)(
                    Uri.parse(url),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode(body),
                  );

                  if (res.statusCode == 200 || res.statusCode == 201) {
                    _fetchData(); 
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Group updated successfully!"), backgroundColor: Colors.green),
                      );
                    }
                  } else {
                    final err = jsonDecode(res.body);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: ${err['message'] ?? 'Failed to save'}")),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Network Error: $e")),
                    );
                  }
                }
              },
              child: Text(isEdit ? "Update" : "Create"),
            ),
          ],
        ),
      ),
    );
  }
}
