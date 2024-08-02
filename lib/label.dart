import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

class PrintLabel extends StatefulWidget {
  const PrintLabel({super.key});

  @override
  State<PrintLabel> createState() => _PrintLabelState();
}

class _PrintLabelState extends State<PrintLabel> {
  final GlobalKey globalKey = GlobalKey();
  final String image = 'assets/images'; // Adjust the path to your images folder
  final String icon = 'assets/icons'; // Adjust the path to your icons folder

  // Dummy data for demonstration
  final parcelToConfrim = ParcelToConfirm(
    code: '1234567890',
    sender: Sender(
      name: 'John Doe',
      tel: '0123456789',
      address: Address(
        info: '123 Main St',
        subdistrictName: 'Subdistrict',
        districtName: 'District',
        provinceName: 'Province',
        zipcode: '12345',
      ),
    ),
    receiver: Receiver(
      name: 'Jane Doe',
      tel: '0987654321',
      storeId: 'Store123',
      address: Address(
        info: '456 Another St',
        subdistrictName: 'Subdistrict',
        districtName: 'District',
        provinceName: 'Province',
        zipcode: '54321',
      ),
    ),
    product: Product(name: 'Product'),
    insureAmount: '100',
    codValue: '50',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Label'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 3.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade400,
                  blurRadius: 8.0,
                  spreadRadius: 0.4,
                ),
              ],
            ),
            child: RepaintBoundary(
              key: globalKey,
              child: Stack(
                children: [
                  // QR code
                  Positioned(
                    top: 0.1,
                    right: -50,
                    child: BarcodeWidget(
                      barcode: Barcode.qrCode(),
                      data: parcelToConfrim.code,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15, top: 15),
                          child: RotationTransition(
                            turns: const AlwaysStoppedAnimation(350 / 360),
                            child: Transform.rotate(
                              angle: 0.17,
                              child: Image.asset(
                                "$image/speedypng.png",
                                height: 40,
                              ),
                            ),
                          ),
                        ),
                        Text('รหัสไปรษณีย์ปลายทาง',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          parcelToConfrim.receiver?.address?.zipcode ?? "null",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "ผู้ส่ง :  ${parcelToConfrim.sender?.name} (${parcelToConfrim.sender?.tel})",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(parcelToConfrim.sender?.address?.info ?? "Null sender address info"),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(color: Colors.black),
                            children: [
                              TextSpan(text: parcelToConfrim.sender?.address?.subdistrictName),
                              const TextSpan(text: " "),
                              TextSpan(text: parcelToConfrim.sender?.address?.districtName),
                              const TextSpan(text: " "),
                              TextSpan(text: parcelToConfrim.sender?.address?.provinceName),
                              const TextSpan(text: " "),
                              TextSpan(text: parcelToConfrim.sender?.address?.zipcode),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "ผู้รับ :  ${parcelToConfrim.receiver?.name} (${parcelToConfrim.receiver?.tel})",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          parcelToConfrim.receiver?.address?.info ?? "null receiver address info",
                          style: const TextStyle(color: Colors.black),
                        ),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(color: Colors.black),
                            children: [
                              TextSpan(text: parcelToConfrim.receiver?.storeId ?? ""),
                              const TextSpan(text: " "),
                              TextSpan(text: parcelToConfrim.receiver?.address?.subdistrictName),
                              const TextSpan(text: " "),
                              TextSpan(text: parcelToConfrim.receiver?.address?.districtName),
                              const TextSpan(text: " "),
                              TextSpan(text: parcelToConfrim.receiver?.address?.provinceName),
                              const TextSpan(text: " "),
                              TextSpan(text: parcelToConfrim.receiver?.address?.zipcode),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 150,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        constraints: const BoxConstraints(minHeight: 30, maxHeight: 30),
                                        child: Text(parcelToConfrim.product?.name ?? "Null product name"),
                                      ),
                                      parcelToConfrim.insureAmount != "0"
                                          ? Container(
                                              constraints: const BoxConstraints(maxHeight: 30),
                                              child: Image.asset(
                                                "$icon/Shield-Task.png",
                                              ),
                                            )
                                          : const SizedBox(),
                                      if (parcelToConfrim.codValue == "0" || parcelToConfrim.codValue == null)
                                        const SizedBox()
                                      else
                                        Container(
                                          constraints: const BoxConstraints(maxHeight: 30),
                                          child: Image.asset(
                                            "$icon/G1.png",
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Center(
                            child: SizedBox(
                              height: 60,
                              child: BarcodeWidget(
                                barcode: Barcode.code128(),
                                data: parcelToConfrim.code,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ParcelToConfirm {
  final String code;
  final Sender? sender;
  final Receiver? receiver;
  final Product? product;
  final String insureAmount;
  final String? codValue;

  ParcelToConfirm({
    required this.code,
    this.sender,
    this.receiver,
    this.product,
    required this.insureAmount,
    this.codValue,
  });
}

class Sender {
  final String name;
  final String tel;
  final Address? address;

  Sender({
    required this.name,
    required this.tel,
    this.address,
  });
}

class Receiver {
  final String name;
  final String tel;
  final String? storeId;
  final Address? address;

  Receiver({
    required this.name,
    required this.tel,
    this.storeId,
    this.address,
  });
}

class Address {
  final String info;
  final String subdistrictName;
  final String districtName;
  final String provinceName;
  final String zipcode;

  Address({
    required this.info,
    required this.subdistrictName,
    required this.districtName,
    required this.provinceName,
    required this.zipcode,
  });
}

class Product {
  final String name;

  Product({required this.name});
}
