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
      home: OtpUIScreen(),
    );
  }
}

class OtpUIScreen extends StatelessWidget {
  const OtpUIScreen({super.key});

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
                  horizontal: 26,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Colors.grey),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Check your email",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color.fromARGB(255, 148, 1, 1),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "We sent a OTP code bakas@gmail.com\nenter 5 digit code that mentioned in the email",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        OtpBox(value: "1", filled: true),
                        OtpBox(),
                        OtpBox(),
                        OtpBox(),
                        OtpBox(),
                      ],
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: 150  ,
                      height: 35,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 140, 0, 0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Verify Code",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    RichText(
                      text: const TextSpan(
                        text: "Haven't got the email yet? ",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: "Resend email",
                            style: TextStyle(
                              color: Color.fromARGB(255, 148, 1, 1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

class OtpBox extends StatelessWidget {
  final bool filled;
  final String value;

  const OtpBox({
    super.key,
    this.filled = false,
    this.value = "",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled
              ? const Color.fromARGB(255, 148, 1, 1)
              : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
