import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:haptic_feedback/providers/obstacle_detection_provider.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:flutter_tts/flutter_tts.dart';

class detectNearObjScreen extends StatefulWidget {
  const detectNearObjScreen({super.key});

  @override
  State<detectNearObjScreen> createState() => _detectNearObjScreenState();
}

class _detectNearObjScreenState extends State<detectNearObjScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  late CameraController _cameraController;
  late bool _cameraControllerInitialise = false;
  List<dynamic> recognitionsList = [];
  late FlutterTts flutterTts;
  late Size screen;

  //Bluetooth variables
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? connection;

  bool get isConnected => connection?.isConnected ?? false;

  bool isDisconnecting = false;

  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _device;
  bool _connected = false;
  bool _isButtonUnavailable = true;

  late String blue = "";

  void playVoice(String s) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.8);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(0.3);
    await flutterTts.speak(s);
  }

  Future<void> setupCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras.first, ResolutionPreset.low);
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

    //finding obstacle in image
    double maxObstacleProb = 0.0;
    double maxObstacleProbHeight = 0.0;
    double maxObstacleProbWidth = 0.0;
    double maxObstacleProbTop = 0.0;
    double maxObstacleProbLeft = 0.0;
    String obstacle = "obstacle";

    for (dynamic result in recognitionsList) {
      if (maxObstacleProb < result['confidenceInClass']) {
        maxObstacleProb = result['confidenceInClass'];
        maxObstacleProbHeight = result["rect"]["h"] * screen.height;
        maxObstacleProbWidth = result["rect"]["w"] * screen.width;
        maxObstacleProbTop = result["rect"]["y"] * screen.height;
        maxObstacleProbLeft = result["rect"]["x"] * screen.width;
        obstacle = result['detectedClass'].toString();
        if (obstacle.contains('?')) obstacle = 'obstacle';
      }
    }

    // Call updateDetection method of the ObstacleDetectionProvider
    if (mounted) {
      Provider.of<ObstacleDetectionProvider>(context, listen: false)
          .updateDetection(
        maxObstacleProb,
        maxObstacleProbHeight,
        maxObstacleProbWidth,
        maxObstacleProbTop,
        maxObstacleProbLeft,
        obstacle,
      );
    }
  }

  Future<void> loadModel() async {
    Tflite.close();
    await Tflite.loadModel(
        model: "assets/ssd_mobilenet_v1_1_metadata_1.tflite",
        labels: "assets/labels.txt");
  }

  Future<bool> enableBluetooth() async {
    _bluetoothState = await FlutterBluetoothSerial.instance.state;
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await _bluetooth.getBondedDevices();
    } catch (error) {
      print(">>>>>>>>$error");
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _devicesList = devices;
    });
  }

  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(const DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      for (var device in _devicesList) {
        items.add(DropdownMenuItem(
          value: device,
          child: Text('${device.name}'),
        ));
      }
    }
    return items;
  }

  void show(String message) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _scaffoldKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    ));
  }

  void _connect() async {
    setState(() => _isButtonUnavailable = false);
    if (!isConnected) {
      try {
        BluetoothConnection? newConnection =
            await BluetoothConnection.toAddress(_device!.address);
        show('Connected to the device');
        setState(() {
          _connected = true;
          connection = newConnection;
        });
        connection!.input!.listen((Uint8List data) {
          blue = ascii.decode(data);
          show('Data incoming: ${ascii.decode(data)}');
        }).onDone(() {
          if (isDisconnecting) {
            show('Disconnecting locally!');
          } else {
            setState(() {
              _connected = false;
            });
            show('Disconnected remotely!');
          }

          if (mounted) {
            setState(() {});
          }
        });
        // Timer(const Duration(milliseconds: 20), () => _listenForData(connection!));
      } catch (error) {
        print('>>>>>>>Cannot connect, exception occurred');
        print('>>>>>>>$error');
        show('Device Not found');
      }
      setState(() => _isButtonUnavailable = true);
    }
  }

  void _disconnect() async {
    setState(() => _isButtonUnavailable = false);
    await connection!.close();
    show('Device disconnected');
    if (!connection!.isConnected) {
      setState(() {
        _connected = false;
        _isButtonUnavailable = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    setupCamera();
    loadModel();
    flutterTts = FlutterTts();

    //handle bluetooth
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });
    enableBluetooth();
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        if (_bluetoothState == BluetoothState.STATE_OFF) {
          _isButtonUnavailable = true;
        }
        getPairedDevices();
      });
    });
    setState(() {});
  }

  @override
  void dispose() {
    _cameraController.stopImageStream();
    flutterTts.stop();
    _cameraController.dispose();
    Tflite.close();

    if (isConnected) {
      isDisconnecting = true;
      connection!.dispose();
    }

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
      screen = MediaQuery.of(context).size;
      return ScaffoldMessenger(
        key: _scaffoldKey,
        child: Scaffold(
            appBar: AppBar(
                title: const Text("Obstacle Detector",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                backgroundColor: const Color(0xFFD8C465),
                centerTitle: true, // Center the title
                iconTheme: const IconThemeData(
                  color: Colors.white, // Change this to white
                )),
            backgroundColor: Colors.black,
            body: SlidingUpPanel(
              minHeight: 30,
              maxHeight: screen.height / 3,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(100.0),
                  topRight: Radius.circular(100.0)),
              panel: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Center(
                      child: Text(
                          isConnected
                              ? '${_device!.name}'
                              : 'No Device Connected',
                          style: TextStyle(
                              color: isConnected ? Colors.green : Colors.grey,
                              fontSize: 20,
                              fontWeight: isConnected
                                  ? FontWeight.bold
                                  : FontWeight.normal))),
                  Column(
                    children: <Widget>[
                      const Text(
                        'Paired Devices:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton(
                        items: _getDeviceItems(),
                        onChanged: (value) {
                          setState(() => _device = value as BluetoothDevice);
                        },
                        value: _devicesList.isNotEmpty ? _device : null,
                      ),
                      ElevatedButton(
                        onPressed: (_isButtonUnavailable)
                            ? () {
                                (_device == null)
                                    ? show('No device selected')
                                    : _connect();
                              }
                            : (_connected ? _disconnect : _connect),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                            const Color(0xFFD8C465),
                          ),
                        ),
                        child: Text(
                          _connected ? 'Disconnect' : 'Connect',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Text(
                            "Device not paired ?",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.bluetooth_audio_rounded,
                              color: Color.fromRGBO(239, 154, 154, 1),
                            ),
                            tooltip: 'Bluetooth Settings',
                            splashRadius: 30,
                            splashColor: Colors.grey,
                            onPressed: () async {
                              await FlutterBluetoothSerial.instance
                                  .openSettings();
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Text(
                            "Already paired, but not found ?",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.youtube_searched_for_outlined,
                              color: Color.fromRGBO(239, 154, 154, 1),
                            ),
                            tooltip: 'Refresh',
                            splashRadius: 30,
                            splashColor: Colors.grey,
                            onPressed: () async {
                              await getPairedDevices().then((_) {
                                show('Device list refreshed');
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              body: Container(
                  color: Colors.black,
                  child: Consumer<ObstacleDetectionProvider>(
                      builder: (context, value, _) {
                    Size size = MediaQuery.of(context).size;
                    Color colorPick = Colors.green;

                    double x = value.maxObstacleProbLeft / size.width;
                    double y = value.maxObstacleProbTop / size.height;
                    double distance = sqrt(x * x + y * y) * 100 + 5;

                    if (blue != "" || value.maxObstacleProbHeight >= size.height - 200) {
                      colorPick = Colors.red;
                      blue = "";
                      if (value.maxObstacleProbLeft >= (size.width / 2) &&
                          value.maxObstacleProbWidth <= (size.width / 2)) {
                        playVoice('${value.obstacle} in right, please go left');
                      } else if (value.maxObstacleProbLeft <= 10 &&
                          value.maxObstacleProbWidth <= (size.width / 2)) {
                        playVoice('${value.obstacle} in left, please go right');
                      } else {
                        playVoice('Please stop, ${value.obstacle} ahead');
                      }
                    }
                    return Stack(children: [
                      SizedBox(
                        width: size.width,
                        height: size.height,
                        child: AspectRatio(
                          aspectRatio: _cameraController.value.aspectRatio,
                          child: CameraPreview(_cameraController),
                        ),
                      ),
                      Positioned(
                          left: value.maxObstacleProbLeft,
                          top: value.maxObstacleProbTop,
                          width: value.maxObstacleProbWidth,
                          height: value.maxObstacleProbHeight,
                          child: Container(
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: colorPick, width: 3.0),
                              ),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${value.obstacle} ${(value.maxObstacleProb * 100).toStringAsFixed(0)}%",
                                      style: TextStyle(
                                        background: Paint()..color = colorPick,
                                        color: Colors.white,
                                        fontSize: value.maxObstacleProbWidth / 35,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                        "Distance: ${distance.toStringAsFixed(5)} cm",
                                        style: TextStyle(
                                          background: Paint()
                                            ..color = colorPick,
                                          color: Colors.white,
                                          fontSize: value.maxObstacleProbWidth / 35,
                                          fontWeight: FontWeight.bold,
                                        ))
                                  ]))),
                      Visibility(
                        visible: _isButtonUnavailable == false &&
                            _bluetoothState == BluetoothState.STATE_ON,
                        child: const LinearProgressIndicator(
                          backgroundColor: Colors.white,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      ),
                    ]);
                  })),
            )),
      );
    }
  }
}
