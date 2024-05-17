import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:haptic_feedback/object_param_model.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DetectNearObjScreen extends StatefulWidget {
  const DetectNearObjScreen({super.key});

  @override
  State<DetectNearObjScreen> createState() => _DetectNearObjScreenState();
}

class _DetectNearObjScreenState extends State<DetectNearObjScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  //camera variables
  late CameraController _cameraController;
  late bool _cameraControllerInitialise = false;

  //obstacle boxes variables
  List<dynamic> recognitionsList = [];
  late Size screen;
  final ValueNotifier<ObjectParam> _objectParam = ValueNotifier(ObjectParam());

  //Bluetooth variables
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? connection;
  bool get isConnected => connection?.isConnected ?? false; //important
  bool isDisconnecting = false;
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _device;
  bool _connected = false;
  bool _isButtonUnavailable = true;
  late String blue = ""; //message signal set to null

  //voice feedback variable
  late FlutterTts flutterTts;

  void playVoice(String s) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(1);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(0.9);
    await flutterTts.speak(s);
  }

  Future<void> setupCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras.first, ResolutionPreset.max);
    await _cameraController.initialize();
    setState(() {
      _cameraControllerInitialise = true;
    });

    //feeding the images to the ml model
    var cameraCount = 0;
    _cameraController.startImageStream((CameraImage image) {
      if (cameraCount % 30 == 0) {
        runModel(image);
      }
      cameraCount++;
    });
  }

  //load the tflite model and output labels
  Future<void> loadModel() async {
    Tflite.close();
    await Tflite.loadModel(
        model: "assets/ssd_mobilenet_v1_1_metadata_1.tflite",
        labels: "assets/labels.txt");
  }

  //detect obstacle on image
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

    recognitionsList = results ?? [];

    //again initialize the parameters
    _objectParam.value = ObjectParam();

    //finding obstacle in image
    for (dynamic result in recognitionsList) {
      if (_objectParam.value.maxObstacleProb < result['confidenceInClass']) {
        _objectParam.value = ObjectParam(
          maxObstacleProb: result['confidenceInClass'],
          maxObstacleProbHeight: result["rect"]["h"] * (screen.height - 100),
          maxObstacleProbWidth: result["rect"]["w"] * screen.width,
          maxObstacleProbTop: result["rect"]["y"] * (screen.height - 100),
          maxObstacleProbLeft: result["rect"]["x"] * screen.width,
          obstacle: result['detectedClass'].toString(),
        );
        if (_objectParam.value.obstacle.contains('?')) {
          _objectParam.value.obstacle = 'obstacle';
        }
      }
    }
    //distance estimation
    //y = mx + c (approx)
    //y --- distance
    //x --- width of object in image
    _objectParam.value.distance = (screen.width -
            ((_objectParam.value.maxObstacleProbWidth * screen.width) / 500)) -
        100;

    // Call the Detection method on crossing threshold
    if (blue != "" || _objectParam.value.distance <= 60) {
      blue = "";
      _objectParam.value.colorPick = Colors.red;

      if (_objectParam.value.maxObstacleProbLeft >= (screen.width / 2) &&
          _objectParam.value.maxObstacleProbWidth <= (screen.width / 2)) {
        playVoice('${_objectParam.value.obstacle} in right, please go left');
      } else if (_objectParam.value.maxObstacleProbLeft <= 10 &&
          _objectParam.value.maxObstacleProbWidth <= (screen.width / 2)) {
        playVoice('${_objectParam.value.obstacle} in left, please go right');
      } else {
        playVoice('Please stop, ${_objectParam.value.obstacle} ahead');
      }
    }
  }

  //now the bluetooth functioning start
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

//update drop down list of paired devices
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

//show the snackbar of message
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
          show('Sensor Detect Obstacle');
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
    screen = MediaQuery.of(context).size;

    print(">>>>>>>>build ${DateTime.now()}");
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
          minHeight: 40,
          maxHeight: screen.height / 3,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0)),
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
                const SizedBox(height: 10),
                Column(children: <Widget>[
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
                      )),
                      child: Text(
                        _connected ? 'Disconnect' : 'Connect',
                        style: const TextStyle(color: Colors.white),
                      )),
                ]),
                Column(children: <Widget>[
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text("Device not paired ?",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            )),
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
                            }),
                      ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text("Already paired, but not found ?",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            )),
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
                            })
                      ])
                ])
              ]),
          body: (_cameraControllerInitialise == true)
              ? Stack(children: [
                  CameraPreview(_cameraController),
                  ValueListenableBuilder(
                    valueListenable: _objectParam,
                    builder: (context, value, child) {
                      return Positioned(
                        left: value.maxObstacleProbLeft,
                        top: value.maxObstacleProbTop,
                        width: value.maxObstacleProbWidth,
                        height: value.maxObstacleProbHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: value.colorPick, width: 3.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "${value.obstacle} ${(value.maxObstacleProb * 100).toStringAsFixed(0)}%",
                                  style: TextStyle(
                                    background: Paint()
                                      ..color = value.colorPick,
                                    color: Colors.white,
                                    fontSize: value.maxObstacleProbWidth / 20,
                                    fontWeight: FontWeight.bold,
                                  )),
                              Text(
                                  "Distance: ${value.distance.toStringAsFixed(2)} cm",
                                  style: TextStyle(
                                    background: Paint()
                                      ..color = value.colorPick,
                                    color: Colors.white,
                                    fontSize: value.maxObstacleProbWidth / 20,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Visibility(
                      visible: _isButtonUnavailable == false &&
                          _bluetoothState == BluetoothState.STATE_ON,
                      child: const LinearProgressIndicator(
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      )),
                ])
              : const Center(
                  child: CircularProgressIndicator(),
                ),
        ),
      ),
    );
  }
}
