import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _buttonFadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _buttonFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 101, 0, 0),
              Color.fromARGB(255, 130, 56, 56),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'B  A  K  A  S',
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 68,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3.5,
                    color: Color.fromARGB(255, 164, 8, 0),
                    shadows: [
                      Shadow(
                        offset: Offset(4, 4),
                        blurRadius: 12,
                        color: Colors.black87,
                      ),
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 6,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _buttonFadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    child: SizedBox(
                      width: 260,
                      height: 55,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.85),
                          foregroundColor: const Color.fromARGB(255, 101, 0, 0),
                          side: const BorderSide(color: Colors.white70),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
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
