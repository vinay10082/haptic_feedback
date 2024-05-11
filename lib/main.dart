import 'package:flutter/material.dart';
import 'package:haptic_feedback/bluetooth_screen.dart';
import 'package:provider/provider.dart';
import 'package:haptic_feedback/providers/obstacle_detection_provider.dart';
import 'package:haptic_feedback/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ObstacleDetectionProvider()),
        ],
        child: const MaterialApp(
          title: 'Haptic Feedback',
          home: BluetoothScreen(),
          debugShowCheckedModeBanner: false,
        ));
  }
}
