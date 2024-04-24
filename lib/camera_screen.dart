import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:haptic_feedback/providers/obstacle_provider.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  late FlutterTts flutterTts;
  late Timer _obstacleDetectionTimer;

  void playVoice(String s) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(s);
  }

  void startObstacleDetection(ObstacleProvider obstacleProvider) {
    var random = Random();
    _obstacleDetectionTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) {
      final bool obstacleLeft = random.nextBool();
      final bool obstacleRight = random.nextBool();
      obstacleProvider.updateObstacles(obstacleLeft, obstacleRight);
      if (obstacleLeft && !obstacleRight) {
        playVoice('There is Obstacle in yours left, please go right');
      } else if (obstacleRight && !obstacleLeft) {
        playVoice('There is Obstacle in yours right, please go left');
      } else if (obstacleLeft && obstacleRight) {
        playVoice('Please stop, obstacle ahead');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    availableCameras().then((cameras) {
      final firstCamera = cameras.first;
      _controller = CameraController(
        firstCamera,
        ResolutionPreset.veryHigh,
      );
      _initializeControllerFuture = _controller.initialize();
      _initializeControllerFuture.then((_) {
        final obstacleProvider =
            Provider.of<ObstacleProvider>(context, listen: false);
        startObstacleDetection(obstacleProvider);
      });

      flutterTts = FlutterTts();
      setState(() {});
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    _controller.dispose();
    _obstacleDetectionTimer.cancel(); // Cancel the obstacle detection timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("build");
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
              return Stack(children: [
                Container(
                  color: Colors.black,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: size.width / size.height,
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
                Consumer<ObstacleProvider>(
                    builder: (context, obstacleProvider, child) {
                  if (obstacleProvider.obstacleLeft &&
                      !obstacleProvider.obstacleRight) {
                    return Positioned(
                      left: 0,
                      top: 50,
                      child: Container(
                        height: size.height - 50,
                        width: size.width / 2,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.red,
                            width: 2.0,
                          ),
                          color: Colors.transparent,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              width: size.width / 2,
                              color: Colors
                                  .red, // Set the background color of the container to red
                              child: const Center(
                                child: Text(
                                  'LEFT',
                                  style: TextStyle(
                                    color: Colors
                                        .white, // Set the text color to white
                                    fontSize: 20.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (obstacleProvider.obstacleRight &&
                      !obstacleProvider.obstacleLeft) {
                    return Positioned(
                      right: 0,
                      top: 50,
                      child: Container(
                        height: size.height - 50,
                        width: size.width / 2,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.red,
                            width: 2.0,
                          ),
                          color: Colors.transparent,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              width: size.width / 2,
                              color: Colors
                                  .red, // Set the background color of the container to red
                              child: const Center(
                                child: Text(
                                  'RIGHT',
                                  style: TextStyle(
                                    color: Colors
                                        .white, // Set the text color to white
                                    fontSize: 20.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (obstacleProvider.obstacleLeft &&
                      obstacleProvider.obstacleRight) {
                    return Positioned(
                      top: 50,
                      child: Container(
                        height: size.height - 50,
                        width: size.width,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.red,
                            width: 2.0,
                          ),
                          color: Colors.transparent,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              width: size.width,
                              color: Colors
                                  .red, // Set the background color of the container to red
                              child: const Center(
                                child: Text(
                                  'AHEAD',
                                  style: TextStyle(
                                    color: Colors
                                        .white, // Set the text color to white
                                    fontSize: 20.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink(); // Return null widget
                  }
                })
              ]);
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
