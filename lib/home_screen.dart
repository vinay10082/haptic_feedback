import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';
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
        backgroundColor: const Color(0xFFD8C465),
        centerTitle: true, // Center the title
      ),
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Image.asset(
              'assets/background.png', // Replace with your image URL
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 0,
            left: 0,
            bottom: 40.0, // Adjust position as needed
            child: Center(
              child: Material(
                elevation: 4.0, // Add elevation for touch effect
                borderRadius: BorderRadius.circular(100),
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () async {
                    // Initialize FlutterBlue instance
                    FlutterBlue flutterBlue = FlutterBlue.instance;

                    // Check if Bluetooth is available
                    var state = await flutterBlue.isOn;

                    if (state) {
                      // Bluetooth is available, now request permissions for camera and microphone
                      Map<Permission, PermissionStatus> statuses = await [
                        Permission.bluetooth,
                        Permission.camera,
                        Permission.microphone,
                      ].request();
                      // print(statuses);
                      // Check if all permissions are granted
                      bool allGranted = statuses.values.every(
                          (status) => status == PermissionStatus.granted);

                      if (allGranted) {
                        // All permissions granted, proceed to open camera screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CameraScreen()),
                        );
                      } else {
                        // Permissions not granted, show an error message
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Permissions Required"),
                            content: const Text(
                                "To use feature, allow Hfeed access to your camera and microphone. Tap Settings > Permissions, and turn camera and microphone on."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Not now"),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Navigate to app settings
                                  openAppSettings();
                                  // then
                                  Navigator.pop(context);
                                },
                                child: const Text("Settings"),
                              )
                            ],
                          ),
                        );
                      }
                    } else {
                      // Bluetooth is not available, show an error message
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Bluetooth Not Available"),
                          content: const Text(
                              "Please go to settings and enable Bluetooth to use this feature."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Okay"),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 200.0,
                    height: 75.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Center(
                      child: Text(
                        'START',
                        style: TextStyle(
                          color: Color(0xFFD8C465),
                          fontSize: 30.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
