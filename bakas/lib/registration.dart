import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GlassRegisterUI extends StatefulWidget {
  const GlassRegisterUI({super.key});
  @override
  State<GlassRegisterUI> createState() => _GlassRegisterUIState();
}

class _GlassRegisterUIState extends State<GlassRegisterUI> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Future<void> _handleRegister() async {
    setState(() {
      _errorText = null;
      _isLoading = true;
    });
    try {
      final fn = _firstNameController.text.trim();
      final ln = _lastNameController.text.trim();
      final em = _emailController.text.trim();
      final bd = _birthdateController.text.trim();
      final pw = _passwordController.text;
      final cpw = _confirmController.text;

      if (pw != cpw) {
        setState(() {
          _errorText = 'Passwords do not match.';
        });
      } else if (fn.isEmpty || ln.isEmpty || em.isEmpty || bd.isEmpty || pw.isEmpty) {
        setState(() {
          _errorText = 'All fields are required.';
        });
      } else if (!em.contains('@')) {
        setState(() {
          _errorText = 'Please enter a valid email.';
        });
      } else {
        final res = await http.post(
          Uri.parse('${_apiBaseUrl()}/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'first_name': fn,
            'last_name': ln,
            'email': em,
            'birthdate': bd,
            'password': pw
          }),
        );
        final Map<String, dynamic> payload =
            (res.body.isNotEmpty ? (jsonDecode(res.body) as Map<String, dynamic>) : <String, dynamic>{});
        if (res.statusCode == 200 && payload['ok'] == true) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }
        setState(() {
          _errorText = (payload['message'] is String)
              ? payload['message'] as String
              : 'Registration failed.';
        });
      }
    } catch (_) {
      setState(() {
        _errorText = 'Could not connect to server.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _birthdateController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      // keep format as YYYY-MM-DD for backend DATE column
      _birthdateController.text = picked.toIso8601String().split('T').first;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                color: const Color.fromARGB(255, 140, 0, 0),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: width * 0.9,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(color: Colors.grey.withOpacity(0.25)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Let's Get Started",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Color.fromARGB(255, 148, 1, 1),
                          ),
                        ),
                        const SizedBox(height: 22),
                        GlassInput(hint: "First Name", icon: Icons.person_outline, controller: _firstNameController),
                        const SizedBox(height: 14),
                        GlassInput(hint: "Last Name", icon: Icons.person_2_outlined, controller: _lastNameController),
                        const SizedBox(height: 14),
                        GlassInput(hint: "Email", icon: Icons.email_outlined, controller: _emailController, keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 14),
                        GlassInput(
                          hint: "Birthday",
                          icon: Icons.cake,
                          controller: _birthdateController,
                          readOnly: true,
                          onTap: _pickBirthdate,
                        ),
                        const SizedBox(height: 14),
                        GlassInput(hint: "Password", icon: Icons.lock_outline, isPassword: true, controller: _passwordController),
                        const SizedBox(height: 14),
                        GlassInput(hint: "Confirm password", icon: Icons.lock_outline, isPassword: true, controller: _confirmController),
                        const SizedBox(height: 14),
                        if (_errorText != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _errorText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 140, 0, 0),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 150,
                          height: 35,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 140, 0, 0),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    "Sign Up",
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassInput extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;

  const GlassInput({
    super.key,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
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
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: TextField(
        obscureText: widget.isPassword ? _obscureText : false,
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(widget.icon, color: Colors.grey.shade700),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
