
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isPopped = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Task QR')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isPopped) return;
          
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
             if (barcode.rawValue != null) {
               _isPopped = true;
               Navigator.pop(context, barcode.rawValue);
               break; 
             }
          }
        },
      ),
    );
  }
}
