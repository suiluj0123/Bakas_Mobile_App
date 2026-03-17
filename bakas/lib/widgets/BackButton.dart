import 'package:flutter/material.dart';

class myBackbutton extends StatelessWidget {
  const myBackbutton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Icon(
        Icons.arrow_back_rounded,
        color: Colors.black,
        size: 25,
      ),
    );
  }
}
