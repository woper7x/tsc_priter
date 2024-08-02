import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_simple_bluetooth_printer/flutter_simple_bluetooth_printer.dart';

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



// Uint8List generateTsplData() {
//   // สร้างคำสั่ง TSPL
//   String tsplCommands = '''
    // SIZE 2,1
    // GAP 0,0
    // DIRECTION 1
    // CLS
    // TEXT 100,100,"3",0,1,1,"TechEx Co.,Ltb."
    // PRINT 1,1
//   ''';

//   // แปลงคำสั่ง TSPL เป็น bytes
//   List<int> bytes = tsplCommands.codeUnits;

//   // แปลง bytes เป็น Uint8List
//   Uint8List uint8list = Uint8List.fromList(bytes);

//   return uint8list;
// }

// void _print2X1() async {
//   if (selectedPrinter == null) return;

//   try {
//     await _connectDevice();
//     if (!_isConnected) {
//       print('Not connected');
//       return;
//     }

//     // สร้างข้อมูลพิมพ์ TSPL
//     Uint8List printData = generateTsplData();

//     // พิมพ์ข้อมูล
//     final isSuccess = await bluetoothManager.writeRawData(printData);
//     print("tspl : $printData");
//     if (isSuccess) {
//       print('Print successful');
//     } else {
//       print('Print failed');
//     }
//   } on BTException catch (e) {
//     print(e);
//   }
// }

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Future<Uint8List> convertImageToGrayscale(Uint8List byteData2, int width, int height) async {
//   // Decode the image from bytes
//   final codec = await ui.instantiateImageCodec(byteData2);
//   final frame = await codec.getNextFrame();
//   final image = frame.image;

//   // Create a new image to store the grayscale result
//   final recorder = ui.PictureRecorder();
//   final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
//   final paint = Paint();

//   // Create a shader to apply the grayscale effect
//   final grayscaleShader = ui.ImageShader(
//     image,
//     ui.TileMode.clamp,
//     ui.TileMode.clamp,
//     Matrix4.identity().storage
//   );

//   // Set paint shader to grayscale effect
//   paint.shader = grayscaleShader;

//   // Draw the image onto the canvas
//   canvas.drawImage(image, Offset.zero, paint);

//   // End recording and convert the picture to an image
//   final grayscaleImage = await recorder.endRecording().toImage(width, height);

//   // Convert the grayscale image to bytes
//   ByteData? byteData = await grayscaleImage.toByteData(format: ui.ImageByteFormat.png);
//   return byteData!.buffer.asUint8List();
// }

// String uint8ListToHex(Uint8List bytes) {
//   final sb = StringBuffer();
//   for (final byte in bytes) {
//     sb.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
//   }
//   return sb.toString();
// }

// Future<Uint8List> generateBitmapTsplData(String imagePath) async {
//   final bytesPerRow = (400/ 8).ceil();
//   // โหลดรูปภาพจาก assets
//   ByteData data = await rootBundle.load(imagePath);
//   ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
//   ui.FrameInfo frameInfo = await codec.getNextFrame();

//   // แปลงรูปภาพเป็นบิตแมป
 
//   ui.Image image = frameInfo.image;
//   ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
//   Uint8List pixels = byteData!.buffer.asUint8List();
//   Uint8List tsplData = await convertImageToGrayscale(pixels,400,400);
//   // สร้างคำสั่ง TSPL สำหรับบิตแมป
//    final tsplCode = 'IMAGE 1,1,0,0,$width,$height,$hexData\n'
//       'PRINT\n';

//   String tsplHeader = '''
//     SIZE 2,1
//     GAP 0,0
//     DIRECTION 1
//     CLS
//   ''';

//    String tsplBitmap = 'BITMAP 0,0,${image.width},${image.height},1,';
//    //String tsplData = 'BITMAP 0,0,${image.width},${image.height},1,';

//   // แปลงบิตแมปเป็นข้อมูลบิตสำหรับ TSPL
//   StringBuffer bitmapBuffer = StringBuffer();
//   for (int i = 0; i < pixels.length; i += 4) {
//     int value = pixels[i] > 127 ? 0 : 1; // แปลงเป็นบิตขาวดำ (0 หรือ 1)
//     bitmapBuffer.write(value);
//   }

//   // รวมคำสั่ง TSPL ทั้งหมด
//   String tsplCommands = tsplHeader + tsplBitmap + bitmapBuffer.toString() + '\nPRINT 1,1\n';

//   // แปลงคำสั่ง TSPL เป็น Uint8List
//   List<int> bytes = tsplCommands.codeUnits;
//   Uint8List uint8list = Uint8List.fromList(bytes);

//   return uint8list;
// }

void _print2X1() async {
  if (selectedPrinter == null) return;

  try {
    await _connectDevice();
    if (!_isConnected) {
      print('Not connected');
      return;
    }

    // สร้างข้อมูลพิมพ์ TSPL สำหรับรูปภาพ

    Uint8List printData = await generateResizedBitmapTsplData('assets/images/speedypng.png');

    // พิมพ์ข้อมูล
    final isSuccess = await bluetoothManager.writeRawData(printData);
    // log("tspl : $printData");
    if (isSuccess) {
      print('Print successful');
    } else {
      print('Print failed');
    }
  } on BTException catch (e) {
    print(e);
  }
}


Future<Uint8List> generateResizedBitmapTsplData(String imagePath, {int width = 200, int height = 100}) async {
  // โหลดรูปภาพจาก assets
  ByteData data = await rootBundle.load(imagePath);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  ui.FrameInfo frameInfo = await codec.getNextFrame();
  ui.Image image = frameInfo.image;

  // ปรับขนาดของรูปภาพ
  ui.PictureRecorder recorder = ui.PictureRecorder();
  ui.Canvas canvas = ui.Canvas(recorder, Rect.fromPoints(Offset(0, 0), Offset(width.toDouble(), height.toDouble())));
  ui.Size size = ui.Size(width.toDouble(), height.toDouble());
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromLTWH(0, 0, size.width, size.height),
    ui.Paint(),
  );
  ui.Image resizedImage = await recorder.endRecording().toImage(width, height);

  // แปลงรูปภาพที่ปรับขนาดเป็นบิตแมป
  ByteData? byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.rawRgba);
  Uint8List pixels = byteData!.buffer.asUint8List();

  // สร้างคำสั่ง TSPL สำหรับบิตแมป
  String tsplHeader = '''
    SIZE ${width / 4},${height / 4}
    GAP 0,0
    CLS
  ''';

  String tsplBitmap = 'BITMAP 0,0,$width,$height,1,';

  // แปลงบิตแมปเป็นข้อมูลบิตสำหรับ TSPL
  StringBuffer bitmapBuffer = StringBuffer();
  for (int i = 0; i < pixels.length; i += 4) {
    int value = pixels[i] > 127 ? 0 : 1; // แปลงเป็นบิตขาวดำ (0 หรือ 1)
    bitmapBuffer.write(value);
  }

  // รวมคำสั่ง TSPL ทั้งหมด
  String tsplCommands = tsplHeader + tsplBitmap + bitmapBuffer.toString() + '\nPRINT 1,1\n';
  log("tspl commands : $tsplCommands");

  // แปลงคำสั่ง TSPL เป็น Uint8List
  List<int> bytes = tsplCommands.codeUnits;
  Uint8List uint8list = Uint8List.fromList(bytes);

  return uint8list;
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
                                      child: Text("Print Zpl",
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
