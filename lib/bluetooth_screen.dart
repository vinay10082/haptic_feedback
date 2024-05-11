// For performing some operations asynchronously
import 'dart:async';
import 'dart:convert';

// For using PlatformException
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
// Initializing the Bluetooth connection state to be unknown
  late BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  // Get the instance of the Bluetooth
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  // Track the Bluetooth connection with the remote device
  late BluetoothConnection connection;

  late int _deviceState;

  late bool isDisconnecting = false;

  // To track whether the device is still connected to Bluetooth
  bool get isConnected => connection != null && connection.isConnected;

  // Define some variables, which will be required later
  late List<BluetoothDevice> _devicesList = [];
  late BluetoothDevice _device;
  late bool _connected = false;
  late bool _isButtonUnavailable = false;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _deviceState = 0; // neutral

    // If the bluetooth of the device is not enabled,
    // then request permission to turn on bluetooth
    // as the app starts up
    enableBluetooth();

    // Listen for further state changes
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
  }

  @override
  void dispose() {
    // Avoid memory leak and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
    }

    super.dispose();
  }

  // Request Bluetooth permission from the user
  Future<bool> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If the bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  // For retrieving and storing the paired devices
  // in a list.
  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }

    // It is an error to call [setState] unless [mounted] is true.
    if (!mounted) {
      return;
    }

    // Store the [devices] list in the [_devicesList] for accessing
    // the list outside this class
    setState(() {
      _devicesList = devices;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
              backgroundColor:
                  WidgetStateProperty.all<Color>(Colors.deepPurple),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.deepPurple)),
              ),
            ),
            onPressed: () async {
              // So, that when new devices are paired
              // while the app is running, user can refresh
              // the paired devices list.
              await getPairedDevices().then((_) {
                show('Device list refreshed');
              });
            },
          ),
        ],
      ),
      body: Container(
        child: Column(
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
                          await FlutterBluetoothSerial.instance.requestEnable();
                        } else {
                          await FlutterBluetoothSerial.instance
                              .requestDisable();
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
                                onPressed: _connected
                                    ? _sendOnMessageToBluetooth
                                    : null,
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
      ),
    );
  }

  // Create the List of devices to be shown in Dropdown Menu
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

  // Method to connect to bluetooth
  void _connect() async {
    setState(() {
      _isButtonUnavailable = true;
    });
    if (_device == null) {
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

  // Method to disconnect bluetooth
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

  // Method to send message,
  // for turning the Bluetooth device on
  void _sendOnMessageToBluetooth() async {
    connection.output.add(utf8.encode("1\r\n"));
    await connection.output.allSent;
    show('Device Turned On');
    setState(() {
      _deviceState = 1; // device on
    });
  }

  // Method to send message,
  // for turning the Bluetooth device off
  void _sendOffMessageToBluetooth() async {
    connection.output.add(utf8.encode("0" + "\r\n"));
    await connection.output.allSent;
    show('Device Turned Off');
    setState(() {
      _deviceState = -1; // device off
    });
  }

  // Method to show a Snackbar,
  // taking message as the text
  Future show(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    SnackBar(
      content: Text(
        message,
      ),
      duration: duration,
    );
  }
}
