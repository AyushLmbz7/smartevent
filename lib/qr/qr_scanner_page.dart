import 'package:eventapp/participant/participant_service.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  final String eventId; //pass current event

  const QRScannerPage({super.key, required this.eventId});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final service = ParticipantService();
  bool scanned = false;

  final MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR")),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) async {
          if (scanned) return;

          final barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;

          final raw = barcodes.first.rawValue;
          if (raw == null || raw.isEmpty) return;

          setState(() {
            scanned = true;
          });

          controller.stop();

          try {
            //QR only contains guestId
            final guestId = raw.trim();

            await service.markAttendanceByGuestId(
              guestId,
              currentEventId: widget.eventId, //event validation
            );

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Attendance Marked")));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to mark Attendance")),
            );
          }

          // restart scanner
          Future.delayed(const Duration(seconds: 2), () {
            setState(() {
              scanned = false;
            });
            controller.start();
          });
        },
      ),
    );
  }
}
