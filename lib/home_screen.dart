import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:haptic_feedback/camera_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey,
      ),
      body: Center(
        child: GestureDetector(
          onTap: () async {
            // Initialize FlutterBlue instance
            FlutterBlue flutterBlue = FlutterBlue.instance;

            // Check if Bluetooth is available
            var state = await flutterBlue.isOn;

            if (state) {
              // Bluetooth is available, navigate to another screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CameraScreen()),
              );
            } else {
              // Bluetooth is not available, show an error message
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const  Text("Bluetooth Not Available"),
                  content: const Text("Please enable Bluetooth to use this feature."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            }
          },
          child: Container(
            width: 150.0,
            height: 150.0,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'START',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}