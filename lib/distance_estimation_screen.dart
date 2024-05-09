import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ObjectDistanceEstimationPage extends StatefulWidget {
  const ObjectDistanceEstimationPage({super.key});

  @override
  State<ObjectDistanceEstimationPage> createState() =>
      _ObjectDistanceEstimationPageState();
}

class _ObjectDistanceEstimationPageState
    extends State<ObjectDistanceEstimationPage> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  late CameraImage cameraImage;
  List<dynamic> recognitionsList = [];
  late Timer _timer;
  double maxHeight = 0.0;
  double leftToMaxHeight = 0.0;
  double widthToMaxHeight = 0.0;
  late FlutterTts flutterTts;

  void playVoice(String s) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(s);
  }
  // playVoice('There is Obstacle in yours left, please go right');
  // playVoice('There is Obstacle in yours right, please go left');
  // playVoice('Please stop, obstacle ahead');

  Future<void> setupCamera() async {
    final cameras = await availableCameras();
    _cameraController =
        CameraController(cameras.first, ResolutionPreset.medium);
    await _cameraController.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _cameraController.startImageStream((CameraImage image) {
        cameraImage = image;
        runModel();
        _cameraController.stopImageStream();
      });
    });
  }

  void runModel() async {
    final List<dynamic>? results = await Tflite.detectObjectOnFrame(
      bytesList: cameraImage.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      imageHeight: cameraImage.height,
      imageWidth: cameraImage.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResultsPerClass: 1,
      threshold: 0.4,
    );

    setState(() {
      recognitionsList = results ?? [];
    });
  }

  Future<void> loadModel() async {
    await Tflite.loadModel(
        model: "assets/ssd_mobilenet_v1_1_metadata_1.tflite",
        labels: "assets/labels.txt");
  }

  @override
  void initState() {
    super.initState();
    setupCamera();
    loadModel();
    flutterTts = FlutterTts();
    setState(() {});
  }

  @override
  void dispose() {
    _timer.cancel();
    _cameraController.stopImageStream();
    flutterTts.stop();
    _cameraController.dispose();
    Tflite.close();

    super.dispose();
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    // Reset maxHeight for each new build
    maxHeight = 0.0;
    leftToMaxHeight = 0.0;
    widthToMaxHeight = 0.0;

    List<Widget> boxes = recognitionsList.map((result) {
      double boxHeight = result["rect"]["h"] * screen.height;
      if (boxHeight > maxHeight) {
        maxHeight =
            boxHeight; // Update maxHeight if current box's height is greater
        leftToMaxHeight = result["rect"]["x"] * screen.width;
        widthToMaxHeight = result["rect"]["w"] * screen.width;
      }

      return Positioned(
        left: result["rect"]["x"] * screen.width,
        top: result["rect"]["y"] * screen.height,
        width: result["rect"]["w"] * screen.width,
        height:
            boxHeight, // Use boxHeight instead of result["rect"]["h"] * screen.height
        child: RecognizedObjectBox(
          result: result,
        ),
      );
    }).toList();

    return boxes;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> list = [];

    list.addAll(displayBoxesAroundRecognizedObjects(size));
    if (maxHeight > 700) {
      if (leftToMaxHeight > 170 && widthToMaxHeight < 170) {
        playVoice('There is Obstacle in yours right, please go left');
      } else if(leftToMaxHeight < 170 && widthToMaxHeight < 170) {
        playVoice('There is Obstacle in yours left, please go right');
      } else {
        playVoice('Please stop, obstacle ahead');
      }
    }
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: _isCameraInitialized
            ? Stack(
                children: [
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
                                child: CameraPreview(_cameraController),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Stack(
                    children: list,
                  )
                ],
              )
            : const Center(
                child: CircularProgressIndicator(),
              ));
  }
}

class RecognizedObjectBox extends StatelessWidget {
  final dynamic result;

  const RecognizedObjectBox({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10.0)),
        border: Border.all(color: Colors.red, width: 2.0),
      ),
      child: Text(
        "${result['detectedClass']} ${(result['confidenceInClass'] * 100).toStringAsFixed(0)}%",
        style: const TextStyle(
          backgroundColor: Colors.red,
          color: Colors.white,
          fontSize: 18.0,
        ),
      ),
    );
  }
}
