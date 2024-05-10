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
  late bool _cameraControllerInitialise = false;
  List<dynamic> recognitionsList = [];
  double maxObstacleProb = 0.0;
  double maxObstacleProbHeight = 0.0;
  double maxObstacleProbWidth = 0.0;
  double maxObstacleProbTop = 0.0;
  double maxObstacleProbLeft = 0.0;
  late String obstacle = "obstacle";
  late Size size;
  late FlutterTts flutterTts;

  void playVoice(String s) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.75);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(s);
  }

  Future<void> setupCamera() async {
    final cameras = await availableCameras();
    _cameraController =
        CameraController(cameras.first, ResolutionPreset.medium);
    await _cameraController.initialize();
    setState(() {
      _cameraControllerInitialise = true;
    });
    var cameraCount = 0;
    _cameraController.startImageStream((CameraImage image) {
      if (cameraCount % 50 == 0) {
        runModel(image);
      }
      cameraCount++;
    });
  }

  void runModel(CameraImage cameraImage) async {
    final List<dynamic>? results = await Tflite.detectObjectOnFrame(
        bytesList: cameraImage.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        imageMean: 127.5,
        imageStd: 127.5,
        numResultsPerClass: 1,
        threshold: 0.4);

    setState(() {
      recognitionsList = results ?? [];
    });
    maxObstacleProb = 0.0;
    maxObstacleProbHeight = 0.0;
    maxObstacleProbWidth = 0.0;
    maxObstacleProbTop = 0.0;
    maxObstacleProbLeft = 0.0;
    obstacle = "obstacle";
    for (dynamic result in recognitionsList) {
      if (maxObstacleProb < result['confidenceInClass']) {
        maxObstacleProb = result['confidenceInClass'];
        maxObstacleProbHeight = result["rect"]["h"] * size.height;
        maxObstacleProbWidth = result["rect"]["w"] * size.width;
        maxObstacleProbTop = result["rect"]["y"] * size.height;
        maxObstacleProbLeft = result["rect"]["x"] * size.width;
        obstacle = result['detectedClass'].toString();
        if(obstacle.contains('?')) obstacle = 'obstacle';
      }
    }
  }

  Future<void> loadModel() async {
    Tflite.close();
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
    _cameraController.stopImageStream();
    flutterTts.stop();
    _cameraController.dispose();
    Tflite.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraControllerInitialise == false) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      size = MediaQuery.of(context).size;
      Color colorPick = Colors.green;
      //tan(theta) = obstaclelength / 2 * focal length(measured by scale) ---eq.1
      //tan(theta) = 4 * size.width / 2 * distance ---eq.2
      double distance = (4 * size.width * (7.25)) / (maxObstacleProbWidth);

      if (distance < 50 || maxObstacleProbHeight >= size.height - 100) {
        colorPick = Colors.red;

        if (maxObstacleProbLeft >= (size.width/2) && maxObstacleProbWidth <= (size.width/2)) {
          playVoice('$obstacle in right, please go left');
        } else if (maxObstacleProbLeft <= 10 && maxObstacleProbWidth <= (size.width/2)) {
          playVoice('$obstacle in left, please go right');
        } else {
          playVoice('Please stop, $obstacle ahead');
        }
      }

      return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white)),
        backgroundColor: Colors.black,
        body: Container(
          color: Colors.black,
          child: Stack(
            children: [
              SizedBox(
                width: size.width,
                height: size.height,
                child: AspectRatio(
                  aspectRatio: _cameraController.value.aspectRatio,
                  child: CameraPreview(_cameraController),
                ),
              ),
              Positioned(
                left: maxObstacleProbLeft,
                top: maxObstacleProbTop,
                width: maxObstacleProbWidth,
                height: maxObstacleProbHeight - 100,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: colorPick, width: 3.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$obstacle ${(maxObstacleProb*100).toStringAsFixed(0)}%",
                        style: TextStyle(
                          background: Paint()..color = colorPick,
                          color: Colors.white,
                          fontSize: maxObstacleProbWidth / 35,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Distance: ${distance.toStringAsFixed(0)} cm",
                        style: TextStyle(
                          background: Paint()..color = colorPick,
                          color: Colors.white,
                          fontSize: maxObstacleProbWidth / 35,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
