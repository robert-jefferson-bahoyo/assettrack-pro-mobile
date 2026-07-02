import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SerialNumberScannerScreen extends StatefulWidget {
  const SerialNumberScannerScreen({super.key});

  @override
  State<SerialNumberScannerScreen> createState() =>
      _SerialNumberScannerScreenState();
}

class _SerialNumberScannerScreenState extends State<SerialNumberScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();

  bool _isProcessing = false;

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isProcessing) {
      return;
    }

    final barcodes = capture.barcodes;

    if (barcodes.isEmpty) {
      return;
    }

    final rawValue = barcodes.first.rawValue?.trim();

    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    _isProcessing = true;

    await _controller.stop();

    if (!mounted) return;

    Navigator.of(context).pop(rawValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D6EFD);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Serial Number'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect,
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black.withOpacity(0.35),
                    width: 36,
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Card(
              color: Colors.black.withOpacity(0.70),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Point the camera at the serial number barcode or QR code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}