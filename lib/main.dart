import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 190, 139, 139),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(36.0),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(36),
            ),
            width: 500,
            height: 600,
            child: Center(
              child: Lottie.asset(
                'assets/loona_eyes.json',
                width: 450,   // Smaller than container width (500)
                height: 400,  // Smaller than container height (600)
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}