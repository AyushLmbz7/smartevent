import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRPage extends StatelessWidget {
  final String? data;

  const QRPage({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null || data!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Participant QR Code")),
        body: const Center(child: Text("QR Data Missing")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Participant QR Code")),
      body: Center(
        child: QrImageView(data: data!, version: QrVersions.auto, size: 200),
      ),
    );
  }
}
