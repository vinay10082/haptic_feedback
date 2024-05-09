import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  double maxHeight = 0.0;
  double leftToMaxHeight = 0.0;
  double widthToMaxHeight = 0.0;
  late String obstacle = "obstacle";
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
      _cameraControllerInitialise = true;
    });
    var cameraCount = 0;
    _cameraController.startImageStream((CameraImage image) {
      if (cameraCount % 100 == 0) {
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
        numResultsPerClass: 2,
        threshold: 0.4);

    setState(() {
      recognitionsList = results ?? [];
    });
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

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (recognitionsList == null) return [];

    double factorX = screen.width;
    double factorY = screen.height;

    Color colorPick = Colors.red;

    // Reset for each new build
    maxHeight = 0.0;
    leftToMaxHeight = 0.0;
    widthToMaxHeight = 0.0;
    obstacle = "obstacle";

    return recognitionsList.map((result) {
      double boxHeight = result["rect"]["h"] * factorY;
      if (boxHeight > maxHeight) {
        maxHeight =
            boxHeight; // Update maxHeight if current box's height is greater
        leftToMaxHeight = result["rect"]["x"] * factorX;
        widthToMaxHeight = result["rect"]["w"] * factorX;
        obstacle = result['detectedClass'].toString();
        if (obstacle.contains('?')) obstacle = "obstacle";
      }

      return Positioned(
        left: result["rect"]["x"] * factorX,
        top: result["rect"]["y"] * factorY,
        width: result["rect"]["w"] * factorX,
        height: result["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 1.0),
          ),
          child: Text(
            "${result['detectedClass']} ${(result['confidenceInClass'] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.black,
              fontSize: 10.0,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> list = [];
    if (_cameraControllerInitialise == false) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      list.add(
        SizedBox(
          width: size.width,
          height: size.height,
          child: AspectRatio(
            aspectRatio: _cameraController.value.aspectRatio,
            child: CameraPreview(_cameraController),
          ),
        ),
      );
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
            iconTheme: const IconThemeData(color: Colors.white)),
        backgroundColor: Colors.black,
        body: Container(
          color: Colors.black,
          child: Stack(
            children: list,
          ),
        ),
      );
    }
  }
}
