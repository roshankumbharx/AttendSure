
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  String scanResult = '';
  bool scanning = true;

  Future<void> scanQR() async {
    try {
      // Call the barcode scanner package's scan method
      var result = await BarcodeScanner.scan();
      // If there is scanned content, update the state and return the result
      if (result.rawContent.isNotEmpty) {
        setState(() {
          scanResult = result.rawContent;
          scanning = false;
        });
        // Return the scanned data to the previous page
        Navigator.pop(context, scanResult);
      } else {
        // No content scanned; update state and pop with null result
        setState(() {
          scanning = false;
        });
        Navigator.pop(context, null);
      }
    } catch (e) {
      setState(() {
        scanning = false;
        scanResult = 'Error occurred: $e';
      });
      Navigator.pop(context, scanResult);
    }
  }

  @override
  void initState() {
    super.initState();
    // Start scanning when the page loads
    scanQR();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
      ),
      body: Center(
        child: scanning
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    scanResult.isNotEmpty ? 'Scanned Data: $scanResult' : 'No data scanned.',
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        scanning = true;
                      });
                      scanQR();
                    },
                    child: const Text('Scan Again'),
                  ),
                ],
              ),
      ),
    );
  }
}

