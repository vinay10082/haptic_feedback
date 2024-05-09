import 'dart:async';
import 'package:image/image.dart' as imglib;
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
  List<dynamic> recognitionsList = [];
  late Timer _timer;
  double maxHeight = 0.0;
  double leftToMaxHeight = 0.0;
  double widthToMaxHeight = 0.0;
  late String obstacle = "obstacle";
  late String obstacleProb = "";
  late FlutterTts flutterTts;

  void playVoice(String s) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(s);
  }

  Future<void> setupCamera() async {
    final cameras = await availableCameras();
    _cameraController =
        CameraController(cameras.first, ResolutionPreset.veryHigh);
    await _cameraController.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
    var cameraCount = 0;
    _cameraController.startImageStream((CameraImage image) {
      if (cameraCount % 200 == 0) {
        runModel(image);
      }
      cameraCount++;
    });
  }

  void runModel(CameraImage image) async {
    final List<dynamic>? results = await Tflite.detectObjectOnFrame(
      bytesList: image.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
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
    obstacle = "obstacle";
    obstacleProb = "";
    List<Widget> boxes = recognitionsList.map((result) {
      double boxHeight = result["rect"]["h"] * screen.height;
      if (boxHeight > maxHeight) {
        maxHeight =
            boxHeight; // Update maxHeight if current box's height is greater
        leftToMaxHeight = result["rect"]["x"] * screen.width;
        widthToMaxHeight = result["rect"]["w"] * screen.width;
        obstacle = result['detectedClass'].toString();
        if (obstacle.contains('?')) obstacle = "obstacle";
        obstacleProb =
            ((result['confidenceInClass'] * 100).toStringAsFixed(0)).toString();
      }

      return Positioned(
        left: result["rect"]["x"] * screen.width,
        top: result["rect"]["y"] * screen.height,
        width: result["rect"]["w"] * screen.width,
        height:
            boxHeight, // Use boxHeight instead of result["rect"]["h"] * screen.height
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green, width: 2.0),
          ),
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
    if (maxHeight > 650) {
      if (leftToMaxHeight > 175 && widthToMaxHeight < 175) {
        playVoice('$obstacle in right, please go left');
      } else if (leftToMaxHeight < 175 && widthToMaxHeight < 175) {
        playVoice('$obstacle in left, please go right');
      } else {
        playVoice('Please stop, $obstacle ahead');
      }
    }
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isCameraInitialized
            ? Stack(
                children: [
                  Container(
                    color: Colors.white,
                    child: Center(
                      child: CameraPreview(_cameraController),
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
