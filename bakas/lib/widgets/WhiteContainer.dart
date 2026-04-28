
import 'package:flutter/material.dart';

class WhiteContainer extends StatelessWidget {

  final Widget child;
  const WhiteContainer({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
   
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 247, 244, 244),
          borderRadius: BorderRadius.only(
            topLeft: Radius.elliptical(60, 70),
            topRight: Radius.elliptical(60, 70),
          ),
        ),
        child: child
      ),
    );
  }
}