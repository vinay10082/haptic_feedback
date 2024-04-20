import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'package:flutter_tts/flutter_tts.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  late FlutterTts flutterTts; // Add FlutterTts instance

  playVoice(String s) async {
    await flutterTts.setLanguage('en-US'); // Set language
    await flutterTts.setSpeechRate(0.5); // Set speech rate
    await flutterTts.setVolume(1.0); // Set volume
    await flutterTts.setPitch(1.0); // Set pitch

    // Speak the string
    await flutterTts.speak(s);
  }

  // Add variables to track obstacle positions
  bool obstacleLeft = false;
  bool obstacleRight = false;

// Function to start obstacle detection
  void startObstacleDetection() {
    //For Example
    // Initialize a random number generator
    var random = Random();
    // Simulate obstacle detection with random values
    Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        // Simulate obstacle detection on the left
        obstacleLeft = random.nextBool();
        // Simulate obstacle detection on the right
        obstacleRight = random.nextBool();
        if (obstacleLeft == true && obstacleRight == false) {
          playVoice('There is Obstacle in yours left, please go right');
        } 
        else if (obstacleRight == true && obstacleLeft == false) {
          playVoice('There is Obstacle in yours right, please go left');
        } 
        else if (obstacleLeft == true && obstacleRight == true) {
          playVoice('Please stop, obstacle ahead');
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    availableCameras().then((cameras) {
      final firstCamera = cameras.first;
      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
      );
      _initializeControllerFuture = _controller.initialize();
      _initializeControllerFuture.then((_) {
        // Start obstacle detection once camera is initialized
        startObstacleDetection();
      });

      flutterTts = FlutterTts(); // Initialize FlutterTts
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Dispose of the FlutterTts instance when not needed
    flutterTts.stop(); // Stop speaking
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else {
              final size = MediaQuery.of(context).size;
              return Stack(
                children: [
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: size.width,
                                height: size.height,
                                child: CameraPreview(_controller),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Add obstacle indicators
                  if (obstacleLeft == true && obstacleRight == false)
                    Positioned(
                      left: 0,
                      top: size.height / 2 -
                          (size.height / 2.8) / 2, // Center vertically
                      child: Container(
                          height: size.height / 2.8,
                          width: size.width / 2,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.red, // Border color
                              width: 2.0, // Border width
                            ),
                            color: Colors.transparent, // Transparent background
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'LEFT',
                                style: TextStyle(
                                  color: Colors.red, // White text
                                  fontSize: 20.0, // Text size
                                ),
                              ),
                            ],
                          )),
                    ),
                  if (obstacleRight == true && obstacleLeft == false)
                    Positioned(
                      right: 0,
                      top: size.height / 2 -
                          (size.height / 2.8) / 2, // Center vertically
                      child: Container(
                          height: size.height / 2.8,
                          width: size.width / 2,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.red, // Border color
                              width: 2.0, // Border width
                            ),
                            color: Colors.transparent, // Transparent background
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'RIGHT',
                                style: TextStyle(
                                  color: Colors.red, // White text
                                  fontSize: 20.0, // Text size
                                ),
                              ),
                            ],
                          )),
                    ),
                  if (obstacleRight == true && obstacleLeft == true)
                    Positioned(
                      top: size.height / 2 -
                          (size.height / 2.8) / 2, // Center vertically
                      child: Container(
                          height: size.height / 2.8,
                          width: size.width,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.red, // Border color
                              width: 2.0, // Border width
                            ),
                            color: Colors.transparent, // Transparent background
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'AHEAD',
                                style: TextStyle(
                                  color: Colors.red, // White text
                                  fontSize: 20.0, // Text size
                                ),
                              ),
                            ],
                          )),
                    ),
                ],
              );
            }
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
