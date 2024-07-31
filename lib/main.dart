import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_simple_bluetooth_printer/flutter_simple_bluetooth_printer.dart';
import 'package:image/image.dart' as img;

img.Image convertImageToMonochrome(img.Image image) {
  return img.grayscale(image);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var bluetoothManager = FlutterSimpleBluetoothPrinter.instance;
  var _isScanning = false;
  var _isBle = true;
  var _isConnected = false;
  var devices = <BluetoothDevice>[];
  StreamSubscription<BTConnectState>? _subscriptionBtStatus;
  BTConnectState _currentStatus = BTConnectState.disconnect;

  BluetoothDevice? selectedPrinter;

  @override
  void initState() {
    super.initState();
    _discovery();

    // subscription to listen change status of bluetooth connection
    _subscriptionBtStatus = bluetoothManager.connectState.listen((status) {
      print(' ----------------- status bt $status ------------------ ');
      _currentStatus = status;
      if (status == BTConnectState.connected) {
        setState(() {
          _isConnected = true;
        });
      }
      if (status == BTConnectState.disconnect ||
          status == BTConnectState.fail) {
        setState(() {
          _isConnected = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscriptionBtStatus?.cancel();
    super.dispose();
  }

  void _scan() async {
    devices.clear();
    try {
      setState(() {
        _isScanning = true;
      });
      if (_isBle) {
        final results =
            await bluetoothManager.scan(timeout: const Duration(seconds: 10));
        devices.addAll(results);
        setState(() {});
      } else {
        final bondedDevices = await bluetoothManager.getAndroidPairedDevices();
        devices.addAll(bondedDevices);
        setState(() {});
      }
    } on BTException catch (e) {
      print(e);
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _discovery() {
    devices.clear();
    try {
      bluetoothManager.discovery().listen((device) {
        devices.add(device);
        setState(() {});
      });
    } on BTException catch (e) {
      print(e);
    }
  }

  void selectDevice(BluetoothDevice device) async {
    if (selectedPrinter != null) {
      if (device.address != selectedPrinter!.address) {
        await bluetoothManager.disconnect();
      }
    }

    selectedPrinter = device;
    setState(() {});
  }

  String convertImageToZPL(img.Image image) {
    List<String> zplCommands = [];
    for (int y = 0; y < image.height; y++) {
      String line = '';
      for (int x = 0; x < image.width; x++) {
        int pixel = image.getPixel(x, y) as int; // รับค่า pixel เป็น int
        int red = (pixel >> 16) & 0xFF; // ดึงค่า Red component
        int green = (pixel >> 8) & 0xFF; // ดึงค่า Green component
        int blue = pixel & 0xFF; // ดึงค่า Blue component

        // ตรวจสอบสีของพิกเซล
        if (red == 0 && green == 0 && blue == 0) {
          line += '1'; // Black pixel
        } else {
          line += '0'; // White pixel
        }
      }
      // ใส่คำสั่ง ZPL ที่เหมาะสม
      zplCommands
          .add('^FO0,$y^GB${image.width},1,1^FS'); // ใส่บรรทัดใหม่ตามลำดับ
    }
    return zplCommands.join('\n');
  }

  void _print2X1() async {
    if (selectedPrinter == null) return;

    final codes = """
^XA
^FO50,60^A0,40^FDWorld's Best Griddle^FS
^FO60,120^BY3^BCN,60,,,,A^FD1234ABC^FS
^FO25,25^GB380,200,2^FS
^XZ
""";
    try {
      await _connectDevice();
      if (!_isConnected) {
        print('Not connected');
        return;
      }
      final isSuccess = await bluetoothManager.writeText(codes);
      //final isSuccess = await bluetoothManager.writeRawData(Bytes);
      if (isSuccess) {
        await bluetoothManager.disconnect();
        print('Print successful');
      } else {
        print('Print failed');
      }
    } on BTException catch (e) {
      print(e);
    }
  }

  _connectDevice() async {
    if (selectedPrinter == null) return;
    try {
      _isConnected = await bluetoothManager.connect(
          address: selectedPrinter!.address, isBLE: selectedPrinter!.isLE);
    } on BTException catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter '),
        ),
        body: Center(
          child: Container(
            height: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedPrinter == null || _isConnected
                                ? null
                                : () {
                                    _connectDevice();
                                  },
                            child: const Text("Connect",
                                textAlign: TextAlign.center),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedPrinter == null || !_isConnected
                                ? null
                                : () {
                                    if (selectedPrinter != null) {
                                      bluetoothManager.disconnect();
                                    }
                                    setState(() {
                                      _isConnected = false;
                                    });
                                  },
                            child: const Text("Disconnect",
                                textAlign: TextAlign.center),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: Platform.isAndroid,
                    child: SwitchListTile.adaptive(
                      contentPadding:
                          const EdgeInsets.only(bottom: 20.0, left: 20),
                      title: const Text(
                        "BLE (low energy)",
                        textAlign: TextAlign.start,
                        style: TextStyle(fontSize: 19.0),
                      ),
                      value: _isBle,
                      onChanged: (bool? value) {
                        setState(() {
                          _isBle = value ?? false;
                          _isConnected = false;
                          selectedPrinter = null;
                          _scan();
                        });
                      },
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      _scan();
                    },
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 2, horizontal: 20),
                      child: Text("Rescan", textAlign: TextAlign.center),
                    ),
                  ),
                  _isScanning
                      ? const CircularProgressIndicator()
                      : Column(
                          children: devices
                              .map(
                                (device) => ListTile(
                                  title: Text(device.name),
                                  subtitle: Text(device.address),
                                  onTap: () {
                                    // do something
                                    selectDevice(device);
                                  },
                                  trailing: OutlinedButton(
                                    onPressed: selectedPrinter == null ||
                                            device.name != selectedPrinter?.name
                                        ? null
                                        : () async {
                                            _print2X1();
                                          },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 2, horizontal: 20),
                                      child: Text("Print test",
                                          textAlign: TextAlign.center),
                                    ),
                                  ),
                                ),
                              )
                              .toList()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
