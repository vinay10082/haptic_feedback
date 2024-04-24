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

  void playVoice(String s) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(s);
  }

  void startObstacleDetection(ObstacleProvider obstacleProvider) {
    var random = Random();
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
        ResolutionPreset.medium,
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
                Consumer<ObstacleProvider>(
                    builder: (context, obstacleProvider, child) {
                  if (obstacleProvider.obstacleLeft &&
                      !obstacleProvider.obstacleRight) {
                    return Positioned(
                      left: 0,
                      top: size.height / 2 - (size.height / 2.8) / 2,
                      child: Container(
                        height: size.height / 2.8,
                        width: size.width / 2,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.red,
                            width: 2.0,
                          ),
                          color: Colors.transparent,
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'LEFT',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 20.0,
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
                      top: size.height / 2 - (size.height / 2.8) / 2,
                      child: Container(
                        height: size.height / 2.8,
                        width: size.width / 2,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.red,
                            width: 2.0,
                          ),
                          color: Colors.transparent,
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'RIGHT',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 20.0,
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
                      top: size.height / 2 - (size.height / 2.8) / 2,
                      child: Container(
                        height: size.height / 2.8,
                        width: size.width,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.red,
                            width: 2.0,
                          ),
                          color: Colors.transparent,
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'AHEAD',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 20.0,
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
