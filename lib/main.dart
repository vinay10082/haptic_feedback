import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:haptic_feedback/home_screen.dart';
import 'package:haptic_feedback/providers/obstacle_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ObstacleProvider()),
        ],
        child: MaterialApp(
          title: 'Haptic Feedback',
          home: HomeScreen(),
          debugShowCheckedModeBanner: false,
        ));
  }
}
