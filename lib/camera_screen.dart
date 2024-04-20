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

  @override
  void initState() {
    super.initState();
    // Get the list of available cameras
    availableCameras().then((cameras) {
      // Get the first available camera
      final firstCamera = cameras.first;
      // Initialize the camera controller
      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
      );
      // Initialize the camera controller future
      _initializeControllerFuture = _controller.initialize();

      flutterTts = FlutterTts(); // Initialize FlutterTts
      // Set state after initializing the controller
      setState(() {});
    });
  }

  @override
  void dispose() {
        // Dispose of the FlutterTts instance when not needed
    flutterTts.stop(); // Stop speaking
    // Dispose of the camera controller when not needed
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
              // Get the screen size
              final size = MediaQuery.of(context).size;

              return Stack(
                children: [
                  Container(
                    color: Colors.black,
                    // Ensure that the camera preview fills the entire screen
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                // Set width and height to screen dimensions
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
                  //Buttons
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20.0, // Adjust this value for desired bottom margin
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            playVoice('There is Obstacle in yours right, please go left');
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: Text(
                            'LEFT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            playVoice('Please stop, obstacle ahead');
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          child: Text(
                            'AHEAD',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            playVoice('There is Obstacle in yours left, please go right');
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue),
                          child: Text(
                            'RIGHT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
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
