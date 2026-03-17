import 'package:flutter/material.dart';

class backgroundRed extends StatelessWidget {

  final Widget child;
  const backgroundRed({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/red.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: child
    );
  }
}

