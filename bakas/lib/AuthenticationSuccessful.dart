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
      home: AuthConfirmationScreen(),
    );
  }
}

class AuthConfirmationScreen extends StatelessWidget {
  const AuthConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 240, 243, 240),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 255, 255, 255),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 150,
                  color: Color.fromARGB(255, 0, 103, 27),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Authentication Successful!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 7, 7, 7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Your account has been verified successfully. \n You can now continue using our App.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(179, 60, 60, 60),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 50),

              SizedBox(
                width: 220,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
  
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 218, 217, 217),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      color: Color.fromARGB(255, 47, 47, 47),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
}
