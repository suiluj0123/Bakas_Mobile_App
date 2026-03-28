import 'package:flutter/material.dart';

class backgroundRed extends StatelessWidget {

  final Widget child;
  const backgroundRed({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF8B0000),
            Color.fromARGB(255, 244, 51, 51),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child
    );
  }
}

