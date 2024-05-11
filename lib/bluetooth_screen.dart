import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  late BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  late BluetoothConnection connection;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  int _deviceState = 0;
  bool isDisconnecting = false;
  bool get isConnected => connection.isConnected;
  late List<BluetoothDevice> _devicesList = [];
  late BluetoothDevice _device;
  late bool _connected = false;
  late bool _isButtonUnavailable = false;

  @override
  void initState() {
    super.initState();
    // Get current state
    _bluetooth.state.then((state) {
      if (mounted) {
        setState(() {
          _bluetoothState = state;
        });
      }
    });

    _deviceState = 0; // neutral

    if (!_bluetoothState.isEnabled) {
      enableBluetooth();
    } else {
      getPairedDevices();
    }

    _bluetooth.onStateChanged().listen((BluetoothState state) {
      if (mounted) {
        setState(() {
          _bluetoothState = state;
          if (_bluetoothState == BluetoothState.STATE_OFF) {
            _isButtonUnavailable = true;
          }
          getPairedDevices();
        });
      }
    });
  }

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
    }
    super.dispose();
  }

  Future<bool> enableBluetooth() async {
    _bluetoothState = await _bluetooth.state;
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await _bluetooth.requestEnable();
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
    } on PlatformException {
      print("Error");
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
      _devicesList.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name.toString()),
          value: device,
        ));
      });
    }
    return items;
  }

  void _connect() async {
    setState(() {
      _isButtonUnavailable = true;
    });
    if (!_device.isConnected) {
      show('No device selected');
    } else {
      if (!isConnected) {
        await BluetoothConnection.toAddress(_device.address)
            .then((_connection) {
          print('Connected to the device');
          connection = _connection;
          setState(() {
            _connected = true;
          });

          connection.input?.listen(null).onDone(() {
            if (isDisconnecting) {
              print('Disconnecting locally!');
            } else {
              print('Disconnected remotely!');
            }
            if (this.mounted) {
              setState(() {});
            }
          });
        }).catchError((error) {
          print('Cannot connect, exception occurred');
          print(error);
        });
        show('Device connected');
        setState(() => _isButtonUnavailable = false);
      }
    }
  }

  void _disconnect() async {
    setState(() {
      _isButtonUnavailable = true;
      _deviceState = 0;
    });

    await connection.close();
    show('Device disconnected');
    if (!connection.isConnected) {
      setState(() {
        _connected = false;
        _isButtonUnavailable = false;
      });
    }
  }

  void _sendOnMessageToBluetooth() async {
    connection.output.add(utf8.encode("1\r\n"));
    await connection.output.allSent;
    show('Device Turned On');
    setState(() {
      _deviceState = 1; // device on
    });
  }

  void _sendOffMessageToBluetooth() async {
    connection.output.add(utf8.encode("0\r\n"));
    await connection.output.allSent;
    show('Device Turned Off');
    setState(() {
      _deviceState = -1; // device off
    });
  }

  Future show(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        duration: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("Flutter Bluetooth"),
        backgroundColor: Colors.deepPurple,
        actions: <Widget>[
          TextButton.icon(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            label: const Text(
              "Refresh",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              backgroundColor:
                  MaterialStateProperty.all<Color>(Colors.deepPurple),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(color: Colors.deepPurple),
                ),
              ),
            ),
            onPressed: () async {
              await getPairedDevices().then((_) {
                show('Device list refreshed');
              });
            },
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Visibility(
            visible: _isButtonUnavailable &&
                _bluetoothState == BluetoothState.STATE_ON,
            child: const LinearProgressIndicator(
              backgroundColor: Colors.yellow,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Enable Bluetooth',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
                Switch(
                  value: _bluetoothState.isEnabled,
                  onChanged: (bool value) {
                    future() async {
                      if (value) {
                        await _bluetooth.requestEnable();
                      } else {
                        await _bluetooth.requestDisable();
                      }

                      await getPairedDevices();
                      _isButtonUnavailable = false;

                      if (_connected) {
                        _disconnect();
                      }
                    }

                    future().then((_) {
                      setState(() {});
                    });
                  },
                )
              ],
            ),
          ),
          Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      "PAIRED DEVICES",
                      style: TextStyle(fontSize: 24, color: Colors.blue),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'Device:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButton(
                          items: _getDeviceItems(),
                          onChanged: (value) =>
                              setState(() => _device = value!),
                          value: _devicesList.isNotEmpty ? _device : null,
                        ),
                        ElevatedButton(
                          onPressed: _isButtonUnavailable
                              ? null
                              : _connected
                                  ? _disconnect
                                  : _connect,
                          child: Text(_connected ? 'Disconnect' : 'Connect'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: _deviceState == 0
                              ? Colors.transparent
                              : (_deviceState == 1)
                                  ? Colors.green
                                  : Colors.red,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      elevation: _deviceState == 0 ? 4 : 0,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                "DEVICE 1",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: _deviceState == 0
                                      ? Colors.blue
                                      : _deviceState == 1
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  _connected ? _sendOnMessageToBluetooth : null,
                              child: const Text("ON"),
                            ),
                            TextButton(
                              onPressed: _connected
                                  ? _sendOffMessageToBluetooth
                                  : null,
                              child: const Text("OFF"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                color: Colors.blue,
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      "NOTE: If you cannot find the device in the list, please pair the device by going to the bluetooth settings",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      child: const Text("Bluetooth Settings"),
                      onPressed: () {
                        FlutterBluetoothSerial.instance.openSettings();
                      },
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
