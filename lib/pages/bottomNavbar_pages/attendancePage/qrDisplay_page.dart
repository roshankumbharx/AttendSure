import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrDisplayPage extends StatelessWidget {
  final int otp;
  final String subject;
  final String startTime;
  final String endTime;
  
  const QrDisplayPage({
    super.key,
    required this.otp,
    required this.subject,
    required this.startTime,
    required this.endTime,
  });
  
  @override
  Widget build(BuildContext context) {
    // Generate QR data string from the provided parameters
    final String qrData = "$subject|$otp|$startTime|$endTime";
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Code for Attendance"),
      ),
      body: Center(
        child: QrImageView(
          data: qrData,
          version: QrVersions.auto,
          size: 300.0,
        ),
      ),
    );
  }
}
