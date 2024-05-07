import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'providers/distance_estimation_provider.dart';

class ObjectDistanceEstimationPage extends StatefulWidget {
  @override
  _ObjectDistanceEstimationPageState createState() =>
      _ObjectDistanceEstimationPageState();
}

class _ObjectDistanceEstimationPageState
    extends State<ObjectDistanceEstimationPage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isModelReady = false;
  Interpreter? _interpreter;

  @override
  void initState() {
    super.initState();
    loadModel().then((value) {
      setState(() {
        _isModelReady = true;
      });
    });
    setupCamera();
  }

  Future<void> setupCamera() async {
    List<CameraDescription> cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.veryHigh);

    await _cameraController!.initialize();
    setState(() {
      _isCameraInitialized = true;
    });

    _cameraController!.startImageStream((CameraImage image) {
      if (_isModelReady) {
        runModelOnFrame(image);
      }
    });
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/object_distance_model.tflite',
      );
    } on PlatformException {
      print('Failed to load model.');
    }
  }

  Future<void> runModelOnFrame(CameraImage image) async {
    try {
      Uint8List bytes = image.planes[0].bytes;

      // Perform inference
      List<Object> inputs = [bytes as Object];
      List<dynamic> outputs = [
        List.filled(1 * 2, 0).reshape([1, 2])
      ];
      _interpreter!.runForMultipleInputs(inputs, {0: outputs});

      // Access the output
      print(outputs);

      Provider.of<ObjectDistanceModel>(context, listen: false)
          .setRecognitions(outputs);
    } on PlatformException {
      print('Failed to run model on frame.');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Object Distance Estimation'),
      ),
      body: 
      // _isModelReady && 
      _isCameraInitialized
          ? Column(
              children: <Widget>[
                Center(
                  child: Expanded(
                    child: CameraPreview(_cameraController!),
                  ),
                ),
                Expanded(
                  child: Consumer<ObjectDistanceModel>(
                    builder: (context, model, _) => model.distance != null
                        ? Text(
                            'Estimated Distance: ${model.distance} meters',
                            style: TextStyle(fontSize: 20.0),
                          )
                        : const Text(
                            'No predictions yet',
                            style: TextStyle(fontSize: 20.0),
                          ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
