import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 58, 53, 53),
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
                'assets/loona_eyes_angry.json',
                width: 450,  
                height: 400,  
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
