import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_v2/tflite_v2.dart';

class ObjectDistanceEstimationPage extends StatefulWidget {
  const ObjectDistanceEstimationPage({Key? key}) : super(key: key);

  @override
  State<ObjectDistanceEstimationPage> createState() =>
      _ObjectDistanceEstimationPageState();
}

class _ObjectDistanceEstimationPageState
    extends State<ObjectDistanceEstimationPage> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  late CameraImage? cameraImage;
  List<dynamic> recognitionsList = [];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    setupCamera();
    loadModel();
  }

  Future<void> setupCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras.first, ResolutionPreset.low);
    await _cameraController.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _cameraController.startImageStream((CameraImage image) {
        cameraImage = image;
        runModel();
        _cameraController.stopImageStream();
      });
    });
  }

  void runModel() async {
    if (cameraImage == null) return;
    final List<dynamic>? results = await Tflite.detectObjectOnFrame(
      bytesList: cameraImage!.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      imageHeight: cameraImage!.height,
      imageWidth: cameraImage!.width,
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
  void dispose() {
    _timer.cancel();
    _cameraController.stopImageStream();
    _cameraController.dispose();
    Tflite.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> list = [];

    if (cameraImage != null) {
      list.addAll(displayBoxesAroundRecognizedObjects(size));
    }

    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
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
          ),
      );
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    return recognitionsList.map((result) {
      return Positioned(
        left: result["rect"]["x"] * screen.width,
        top: result["rect"]["y"] * screen.height,
        width: result["rect"]["w"] * screen.width,
        height: result["rect"]["h"] * screen.height,
        child: RecognizedObjectBox(
          result: result,
        ),
      );
    }).toList();
  }
}

class RecognizedObjectBox extends StatelessWidget {
  final dynamic result;

  const RecognizedObjectBox({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
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
