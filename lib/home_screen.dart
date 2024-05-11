import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:haptic_feedback/distance_estimation_screen.dart';
import 'package:permission_handler/permission_handler.dart';

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
                    FlutterBluetoothSerial bluetooth =
                        FlutterBluetoothSerial.instance;
                    BluetoothState bluetoothState = await bluetooth.state;
                    // Bluetooth is available, now request permissions for camera and microphone
                    Map<Permission, PermissionStatus> statuses = await [
                      Permission.bluetooth,
                      Permission.bluetoothAdvertise,
                      Permission.bluetoothConnect,
                      Permission.bluetoothScan,
                      Permission.camera,
                      Permission.microphone,
                    ].request();
                    // print(statuses);
                    // Check if all permissions are granted
                    bool allGranted = statuses.values
                        .every((status) => status == PermissionStatus.granted);

                    if (allGranted) {
                      // All permissions granted,
                      await bluetooth.requestEnable();
                      if (bluetoothState == BluetoothState.STATE_ON) {
                        //open Detection screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const detectNearObjScreen()),
                        );
                      } else {
                        await bluetooth.requestEnable();
                      }
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
