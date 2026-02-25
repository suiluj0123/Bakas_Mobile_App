import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgetPasswordUI extends StatefulWidget {
  const ForgetPasswordUI({super.key});

  @override
  State<ForgetPasswordUI> createState() => _ForgetPasswordUIState();
}

class _ForgetPasswordUIState extends State<ForgetPasswordUI> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isTokenSent = false;
  String? _errorText;
  String? _successMessage;

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Future<void> _handleRequestToken() async {
    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        setState(() {
          _errorText = "Please enter your email.";
          _isLoading = false;
        });
        return;
      }

      final res = await http.post(
        Uri.parse('${_apiBaseUrl()}/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final payload = jsonDecode(res.body);

      if (res.statusCode == 200 && payload['ok'] == true) {
        setState(() {
          _isTokenSent = true;
          _successMessage = "Reset token has been sent to your email (Check console for dev).";
          // For development convenience, pre-fill token if backend returns it
          if (payload['token'] != null) {
            _tokenController.text = payload['token'].toString();
          }
        });
      } else {
        setState(() {
          _errorText = payload['message'] ?? "Failed to request reset token.";
        });
      }
    } catch (e) {
      setState(() {
        _errorText = "Could not connect to server.";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final token = _tokenController.text.trim();
      final newPassword = _newPasswordController.text;

      if (token.isEmpty || newPassword.isEmpty) {
        setState(() {
          _errorText = "Token and new password are required.";
          _isLoading = false;
        });
        return;
      }

      final res = await http.post(
        Uri.parse('${_apiBaseUrl()}/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
          'newPassword': newPassword,
        }),
      );

      final payload = jsonDecode(res.body);

      if (res.statusCode == 200 && payload['ok'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset successful! Please login.")),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _errorText = payload['message'] ?? "Failed to reset password.";
        });
      }
    } catch (e) {
      setState(() {
        _errorText = "Could not connect to server.";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: width * 0.9,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.25),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFF2F2F2),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        _isTokenSent ? "Reset Password" : "Forget Password",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 140, 0, 0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isTokenSent 
                          ? "Enter the 6-digit token and your new password."
                          : "Please enter your email to reset the password",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (!_isTokenSent) ...[
                      GlassInput(
                        hint: "Email",
                        icon: Icons.mail_outline,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ] else ...[
                      GlassInput(
                        hint: "Reset Token",
                        icon: Icons.vpn_key_outlined,
                        controller: _tokenController,
                      ),
                      const SizedBox(height: 16),
                      GlassInput(
                        hint: "New Password",
                        icon: Icons.lock_outline,
                        controller: _newPasswordController,
                        isPassword: true,
                      ),
                    ],

                    if (_errorText != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _errorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                    if (_successMessage != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],

                    const SizedBox(height: 30),
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : (_isTokenSent ? _handleResetPassword : _handleRequestToken),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 140, 0, 0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: _isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                _isTokenSent ? "Reset My Password" : "Get Reset Token",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassInput extends StatefulWidget {
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType? keyboardType;

  const GlassInput({
    super.key,
    required this.hint,
    required this.icon,
    this.controller,
    this.isPassword = false,
    this.keyboardType,
  });

  @override
  State<GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<GlassInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.isPassword ? _obscureText : false,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
          ),
          prefixIcon: Icon(widget.icon, color: Colors.grey.shade700),
          suffixIcon: widget.isPassword 
            ? IconButton(
                icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

