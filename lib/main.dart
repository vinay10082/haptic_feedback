import 'package:flutter/material.dart';
import 'package:haptic_feedback/splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App',
      home: SplashScreen(), // Display your splash screen as the home screen
      debugShowCheckedModeBanner: false,
    );
  }
}
