import 'package:flutter/material.dart';

class WhiteContainer extends StatelessWidget {
  /*
  dito gumawa ako widget child para pag tinawag ko si white container
  pwede ako gumawa ng widget inside of white container
  */
  final Widget child;
  const WhiteContainer({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    /*
    white container expanded para sagad sa screen
    reusable para di na mag gawa ulit per page hahaha
    */
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 247, 244, 244),
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