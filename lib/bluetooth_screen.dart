import 'package:flutter/material.dart';

class BluetoothArduinoControlScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Arduino Control'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Control Arduino'),
            ElevatedButton(
              onPressed: () {
                // Add onPressed logic
              },
              child: Text('Toggle LED'),
            ),
          ],
        ),
      ),
    );
  }
}
