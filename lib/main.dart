import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:haptic_feedback/bluetooth_screen.dart';
import 'package:haptic_feedback/home_screen.dart';
import 'package:haptic_feedback/providers/bluetooth_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        ],
        child: const MaterialApp(
          title: 'Haptic Feedback',
          home: HomeScreen(),
          debugShowCheckedModeBanner: false,
        ));
  }
}
