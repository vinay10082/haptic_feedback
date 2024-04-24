import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:haptic_feedback/camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Haptic Feedback Controller',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey,
        centerTitle: true, // Center the title
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height / 1.5,
            width: MediaQuery.of(context).size.width,
            child: Image.asset(
              'assets/background.png', // Replace with your image URL
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(
            height: 10, // Height of the SizedBox
          ),
          Center(
            child: Container(
              width: 300.0,
              height: 80.0,
              decoration: BoxDecoration(
                  color: const Color(0xFFD8C465),
                  borderRadius: BorderRadius.circular(50)),
              child: InkWell(
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
                        title: const Text("Bluetooth Not Available"),
                        content: const Text(
                            "Please enable Bluetooth to use this feature."),
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
                highlightColor: Colors.black54,
                splashColor: Colors.black26,
                child: const Center(
                  child: Text(
                    'START',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
