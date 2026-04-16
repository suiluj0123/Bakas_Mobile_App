import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../app_drawer.dart';
import '../../services/session_service.dart';
import '/widgets/BakasHeader.dart';
import '/widgets/WhiteContainer.dart';
import '/widgets/backgroundRed.dart';

class walletPage extends StatefulWidget {
  final String? firstName;
  final int? playerId;
  const walletPage({super.key, this.firstName, this.playerId});

  @override
  State<walletPage> createState() => _walletPageState();
}

class _walletPageState extends State<walletPage> {
  List<dynamic> _wallets = [];
  bool _isLoading = true;

  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  String _selectedWalletType = "GCash";
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchWallets();
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Future<void> _fetchWallets() async {
    final effectivePlayerId = widget.playerId ?? SessionService().playerId;
    if (effectivePlayerId == null) {
      debugPrint('Error: fetchWallets failed because playerId is null');
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final res = await http.get(Uri.parse('${_apiBaseUrl()}/api/settings/wallet/$effectivePlayerId'));
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          setState(() {
            _wallets = payload['data'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching wallets: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addWallet() async {
    if (_accountNumberController.text.isEmpty || _accountNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final effectivePlayerId = widget.playerId ?? SessionService().playerId;
    if (effectivePlayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No active session found. Please re-login.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    debugPrint('Linking wallet for playerId: $effectivePlayerId');
    
    try {
      final res = await http.post(
        Uri.parse('${_apiBaseUrl()}/api/settings/addWallet'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'playerId': effectivePlayerId,
          'wallet_name': _accountNameController.text,
          'wallet_type': _selectedWalletType,
          'wallet_number': _accountNumberController.text,
          'balance': 0.0,
        }),
      );

      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          _fetchWallets();
          _accountNumberController.clear();
          _accountNameController.clear();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wallet linked successfully'), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
        } else {
          throw payload['message'] ?? 'Failed to link wallet';
        }
      } else {
        throw 'Server error: ${res.statusCode}';
      }
    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
       }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _editWallet(int walletId) async {
    if (_accountNumberController.text.isEmpty) return;
    try {
      final res = await http.put(
        Uri.parse('${_apiBaseUrl()}/api/settings/editWallet'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'playerId': widget.playerId,
          'walletId': walletId,
          'wallet_number': _accountNumberController.text,
        }),
      );

      if (res.statusCode == 200) {
        _fetchWallets();
        _accountNumberController.clear();
      }
    } catch (e) {
      debugPrint('Error editing wallet: $e');
    }
  }

  void EditWalletModal(BuildContext context, dynamic wallet) {
    _accountNumberController.text = wallet['wallet_number'] ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Edit Wallet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.black),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Account Number*", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _accountNumberController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _editWallet(wallet['walletId']);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000)),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void LinkWalletModal(BuildContext context) {
    _accountNumberController.clear();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Link Wallet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.black),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Account Name*", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _accountNameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      hintText: "As it appears on your E-Wallet",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Account Number*", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                        const SizedBox(height: 5),
                        TextField(
                          controller: _accountNumberController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Wallet Type*", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: _selectedWalletType,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: ["GCash", "Maya", "Bank"].map((type) {
                            return DropdownMenuItem(value: type, child: Text(type));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => _selectedWalletType = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _isSaving ? null : () => _addWallet(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Save", style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000)),
                    child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return backgroundRed(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: myAppBar('Setting'),
        drawer: AppDrawer(
          firstName: widget.firstName,
          playerId: widget.playerId,
        ),
        body: SafeArea(
          bottom: false,
          child: WhiteContainer(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _navButton('Profile', '/setting'),
                      _navButton('Wallet', '/wallet'),
                      _navButton('Security', '/security'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                if (_wallets.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Text("No wallet linked yet."),
                                  ),
                                ..._wallets.map((wallet) => _walletCard(wallet)).toList(),
                                const SizedBox(height: 40),
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: () => LinkWalletModal(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B0000),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    ),
                                    child: const Text("Link Wallet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        ),
      ),
    );
  }

  Widget _navButton(String label, String route) {
    final bool isCurrent = ModalRoute.of(context)?.settings.name == route;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: OutlinedButton(
        onPressed: isCurrent
            ? null
            : () {
                Navigator.pop(context);
                Navigator.pushNamed(context, route, arguments: {
                  'firstName': widget.firstName,
                  'playerId': widget.playerId,
                });
              },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          foregroundColor: isCurrent ? Colors.red : Colors.black87,
          side: isCurrent ? const BorderSide(color: Colors.red) : null,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _walletCard(dynamic wallet) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF007DFE),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Text(wallet['wallet_type'] ?? "Wallet",
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              InkWell(
                onTap: () => EditWalletModal(context, wallet),
                child: const Icon(Icons.edit_document, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(wallet['wallet_name'] ?? widget.firstName ?? SessionService().firstName ?? "User",
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
              Text(wallet['wallet_number'] ?? "*******", style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}