import 'package:flutter/material.dart';
import 'package:haptic_feedback/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
          title: 'Haptic Feedback',
          home: HomeScreen(),
          debugShowCheckedModeBanner: false,
        );
  }
}
