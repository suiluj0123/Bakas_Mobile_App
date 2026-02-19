import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ForgetPasswordUI(),
    );
  }
}

class ForgetPasswordUI extends StatelessWidget {
  const ForgetPasswordUI({super.key});

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
                      onTap: () {},
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

                   const Align(
                    
                    alignment: Alignment.center,
                    child: Text(
                    "Forget Password",
                     style: TextStyle(
                     fontSize: 36,
                     fontWeight: FontWeight.bold,
                     color: Color.fromARGB(255, 140, 0, 0),
                     

                         ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    
                    Text(
                      "Please enter your email to reset the password",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 30),

                    const GlassInput(
                      hint: "Email",
                      icon: Icons.mail_outline,
                    ),

                    const SizedBox(height: 30),

                    Center(
                      child: SizedBox(
                        width: 180,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 140, 0, 0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: const Text(
                            "Reset Password",
                            style: TextStyle(
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

class GlassInput extends StatelessWidget {
  final String hint;
  final IconData icon;

  const GlassInput({
    super.key,
    required this.hint,
    required this.icon,
  });

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
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
          ),
          prefixIcon: Icon(icon, color: Colors.grey.shade700),
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
