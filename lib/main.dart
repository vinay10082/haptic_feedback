import 'package:flutter/material.dart';
import 'package:haptic_feedback/distance_estimation_screen.dart';
import 'package:provider/provider.dart';

import 'package:haptic_feedback/bluetooth_screen.dart';
import 'package:haptic_feedback/home_screen.dart';
import 'package:haptic_feedback/providers/obstacle_provider.dart';
import 'package:haptic_feedback/providers/bluetooth_provider.dart';
import 'package:haptic_feedback/providers/distance_estimation_provider.dart';

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
          ChangeNotifierProvider(create: (_) => BluetoothProvider()),
          ChangeNotifierProvider(create: (_) => ObjectDistanceModel())
        ],
        child: const MaterialApp(
          title: 'Haptic Feedback',
          home: HomeScreen(),
          debugShowCheckedModeBanner: false,
        ));
  }
}
