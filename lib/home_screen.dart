import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart'; // Ensure this import is correct
import 'package:haptic_feedback/camera_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
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
                  title: Text("Bluetooth Not Available"),
                  content: Text("Please enable Bluetooth to use this feature."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("OK"),
                    ),
                  ],
                ),
              );
            }
          },
          child: Container(
            width: 150.0,
            height: 150.0,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
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
