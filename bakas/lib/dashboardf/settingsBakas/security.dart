import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../app_drawer.dart';
import '/widgets/BakasHeader.dart';
import '/widgets/WhiteContainer.dart';
import '/widgets/backgroundRed.dart';
import '../../services/api_config.dart';

class securityPage extends StatefulWidget {
  final String? firstName;
  final int? playerId;
  const securityPage({super.key, this.firstName, this.playerId});

  @override
  State<securityPage> createState() => _securityPageState();
}

class _securityPageState extends State<securityPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  Future<void> _changePassword() async {
    if (widget.playerId == null) return;
    
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Check old password
      final checkRes = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/settings/checkPassword'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'playerId': widget.playerId,
          'password': oldPassword,
        }),
      );

      if (checkRes.statusCode != 200) {
        final payload = jsonDecode(checkRes.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(payload['message'] ?? 'Incorrect old password')));
        setState(() => _isLoading = false);
        return;
      }

      // 2. Update password
      final updateRes = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/settings/changePassword'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'playerId': widget.playerId,
          'confirmPassword': confirmPassword,
        }),
      );

      if (updateRes.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully')));
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update password')));
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          child: Column(
            children: [
              WhiteContainer(
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                "Change Password",
                                style: TextStyle(
                                  color: Color(0xFF8B0000),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            securityInput("Old Password", _oldPasswordController),
                            const SizedBox(height: 15),
                            securityInput("New Password", _newPasswordController),
                            const SizedBox(height: 15),
                            securityInput("Confirm Password", _confirmPasswordController),
                            const SizedBox(height: 25),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: SizedBox(
                                width: 120,
                                height: 38,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _changePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00C853),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text(
                                          "Save",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
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

  Widget securityInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
