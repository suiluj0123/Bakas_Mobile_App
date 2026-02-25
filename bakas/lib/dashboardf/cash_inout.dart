import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../dashboard.dart';
import 'app_drawer.dart';

class CashInOutPage extends StatefulWidget {
  final int? playerId;
  final String? firstName;
  const CashInOutPage({super.key, this.playerId, this.firstName});

  @override
  State<CashInOutPage> createState() => _CashInOutPageState();
}

enum CashState { main, selection, methodSelection, amountInput }

class _CashInOutPageState extends State<CashInOutPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  CashState _currentState = CashState.main;
  bool _isCashIn = true;
  String? _selectedMethod; // 'card', 'wallet'
  String? _selectedProvider; // 'gcash', 'maya'

  final _amountController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  final List<int> _presets = [100, 500, 1000, 5000, 10000, 30000];

  double _balance = 0.0;
  double _cashInLimit = 0.0;
  bool _isStatsLoading = true;
  bool _isActionLoading = false;

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  @override
  void initState() {
    super.initState();
    _fetchWalletStats();
  }

  Future<void> _fetchWalletStats() async {
    if (widget.playerId == null) {
      setState(() => _isStatsLoading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${_apiBaseUrl()}/api/payments/stats?playerId=${widget.playerId}'),
      );

      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          setState(() {
            final dynamic balanceData = payload['data']['balance'];
            final dynamic limitData = payload['data']['cashInLimit'];
            
            _balance = (balanceData is String) 
                ? double.tryParse(balanceData) ?? 0.0 
                : (balanceData as num).toDouble();
                
            _cashInLimit = (limitData is String) 
                ? double.tryParse(limitData) ?? 0.0 
                : (limitData as num).toDouble();
                
            _isStatsLoading = false;
          });
          return;
        } else {
          _showError(payload['message'] ?? 'Failed to fetch wallet stats');
        }
      } else {
        _showError('Server error: ${res.statusCode}');
      }
      setState(() => _isStatsLoading = false);
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      _showError('Connection error: Check your internet or server');
      setState(() => _isStatsLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black,
      ),
    );
  }

  Future<void> _processTransaction() async {
    if (widget.playerId == null) return;

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isActionLoading = true);

    debugPrint('Processing transaction: ${_isCashIn ? 'CASH_IN' : 'CASH_OUT'} of $amount');
    try {
      final res = await http.post(
        Uri.parse('${_apiBaseUrl()}/api/payments/transaction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'playerId': widget.playerId,
          'type': _isCashIn ? 'CASH_IN' : 'CASH_OUT',
          'amount': amount,
          'paymentMethod': _selectedMethod,
          'provider': _selectedProvider ?? (_selectedMethod == 'card' ? 'CARD' : null),
        }),
      );

      debugPrint('Status Code: ${res.statusCode}');
      debugPrint('Response Body: ${res.body}');

      final payload = jsonDecode(res.body);
      if (res.statusCode == 200 && payload['ok'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(payload['message'] ?? 'Transaction successful')),
        );
        _amountController.clear();
        setState(() => _currentState = CashState.main);
        _fetchWalletStats(); // Refresh balance
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(payload['message'] ?? 'Transaction failed')),
        );
      }
    } catch (e) {
      debugPrint('Error in _processTransaction: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  void _onBack() {
    setState(() {
      if (_currentState == CashState.selection) {
        _currentState = CashState.main;
      } else if (_currentState == CashState.methodSelection) {
        _currentState = CashState.selection;
      } else if (_currentState == CashState.amountInput) {
        if (_selectedMethod == 'wallet') {
          _currentState = CashState.methodSelection;
        } else {
          _currentState = CashState.selection;
        }
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
          onRefresh: _fetchWalletStats),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8B0000),
              Color(0xFF4A0000),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE0F2F1),
                      ),
                      child: const Icon(
                        Icons.notifications_none,
                        color: Color(0xFF4DB6AC),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Wallet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Total Balance',
                        value: _isStatsLoading ? 'Loading...' : 'Php ${_balance.toStringAsFixed(2)}',
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white30,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Expanded(
                      child: _SummaryTile(
                        icon: Icons.south_west,
                        label: 'Cash In monthly\nlimit remaining',
                        value: _isStatsLoading ? 'Loading...' : 'Php ${_cashInLimit.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(30),
                      child: _buildCurrentView(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentState) {
      case CashState.main:
        return _buildMainView();
      case CashState.selection:
        return _buildSelectionView();
      case CashState.methodSelection:
        return _buildMethodSelectionView();
      case CashState.amountInput:
        return _buildAmountInputView();
    }
  }

  Widget _buildMainView() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _WalletActionButton(
              icon: Icons.arrow_downward_outlined,
              label: 'Cash In',
              onTap: () {
                setState(() {
                  _isCashIn = true;
                  _currentState = CashState.selection;
                });
              },
            ),
            const SizedBox(width: 40),
            _WalletActionButton(
              icon: Icons.arrow_upward_outlined,
              label: 'Cash Out',
              onTap: () {
                setState(() {
                  _isCashIn = false;
                  _currentState = CashState.selection;
                });
              },
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildHeader(String title, {bool isClose = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            IconButton(
              icon: Icon(isClose ? Icons.close : Icons.arrow_back),
              onPressed: () {
                if (isClose) {
                  setState(() => _currentState = CashState.main);
                } else {
                  _onBack();
                }
              },
            ),
          ],
        ),
        const Divider(color: Color(0xFF8B0000), thickness: 1),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSelectionView() {
    return Column(
      children: [
        _buildHeader(_isCashIn ? 'Cash In' : 'Cash Out'),
        _SelectionCard(
          icon: Icons.credit_card,
          label: 'Debit/Credit Card',
          gradient: const LinearGradient(
            colors: [Color(0xFFE0E0E0), Color(0xFFD0D0FB)],
          ),
          onTap: () {
            setState(() {
              _selectedMethod = 'card';
              _currentState = CashState.amountInput;
            });
          },
        ),
        const SizedBox(height: 20),
        _SelectionCard(
          icon: Icons.account_balance_wallet,
          label: 'E-Wallet',
          gradient: const LinearGradient(
            colors: [Color(0xFFE0E0E0), Color(0xFFC8E6C9)],
          ),
          onTap: () {
            setState(() {
              _selectedMethod = 'wallet';
              _currentState = CashState.methodSelection;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMethodSelectionView() {
    return Column(
      children: [
        _buildHeader(_isCashIn ? 'Cash In' : 'Cash Out'),
        _PaymentMethodCard(
          imagePath: 'assets/gcash.png',
          name: 'GCash',
          subtitle: 'Ju****e C.',
          trailing: '•••• •••• 123',
          color: const Color(0xFF007DFE),
          onTap: () {
            setState(() {
              _selectedProvider = 'gcash';
              _currentState = CashState.amountInput;
            });
          },
        ),
        const SizedBox(height: 20),
        _PaymentMethodCard(
          imagePath: 'assets/maya.jpg',
          name: 'Maya',
          subtitle: 'Ju****e C.',
          trailing: '•••• •••• 456',
          color: const Color(0xFF00C853),
          onTap: () {
            setState(() {
              _selectedProvider = 'maya';
              _currentState = CashState.amountInput;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAmountInputView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(_isCashIn ? 'Cash In' : 'Cash Out', isClose: true),
        const Text(
          'Amount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _presets.length,
          itemBuilder: (context, index) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _amountController.text = _presets[index].toString();
              },
              child: Text('PHP ${_presets[index]}'),
            );
          },
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _isActionLoading
                ? const CircularProgressIndicator(color: Color(0xFF8B0000))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _processTransaction,
                    child: Text(_isCashIn ? 'Cash In' : 'Cash Out'),
                  ),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                setState(() => _currentState = CashState.main);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Colors.black),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String imagePath;
  final String name;
  final String subtitle;
  final String trailing;
  final Color color;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.imagePath,
    required this.name,
    required this.subtitle,
    required this.trailing,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(imagePath, height: 40),
                const SizedBox(width: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  trailing,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _WalletActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}


