import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme.dart';
import '../../services/qr_service.dart';
import 'scan_result_screen.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen>
    with WidgetsBindingObserver {
  late MobileScannerController _ctrl;
  bool _hasScanned = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ctrl.start();
    } else if (state == AppLifecycleState.paused) {
      _ctrl.stop();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    setState(() => _hasScanned = true);
    _ctrl.stop();

    final data = QrService.decodePayload(raw);

    if (data == null) {
      // Not a JanRaksha QR
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Not a valid JanRaksha QR code'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _hasScanned = false);
          _ctrl.start();
        }
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanResultScreen(data: data),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _hasScanned = false);
        _ctrl.start();
      }
    });
  }

  void _toggleTorch() {
    _ctrl.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Code',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: _torchOn ? Colors.yellow : Colors.white,
            ),
            onPressed: _toggleTorch,
            tooltip: 'Toggle Torch',
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Camera Preview ─────────────────────────────────
          MobileScanner(
            controller: _ctrl,
            onDetect: _onDetect,
          ),

          // ── Dark overlay with scan window ──────────────────
          CustomPaint(
            painter: _ScanOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // ── Scan box border ────────────────────────────────
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppTheme.accentColor, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _hasScanned
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.accentColor))
                  : null,
            ),
          ),

          // ── Corner accents ─────────────────────────────────
          const Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  _Corner(top: 0, left: 0, rotate: 0),
                  _Corner(top: 0, right: 0, rotate: 90),
                  _Corner(bottom: 0, right: 0, rotate: 180),
                  _Corner(bottom: 0, left: 0, rotate: 270),
                ],
              ),
            ),
          ),

          // ── Instructions ───────────────────────────────────
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner,
                    color: Colors.white54, size: 28),
                const SizedBox(height: 10),
                const Text(
                  'Point camera at a JanRaksha QR Code',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'The data is read instantly, even offline.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scan Window Overlay Painter ────────────────────────────────
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    const scanSize = 260.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final left = cx - scanSize / 2;
    final top = cy - scanSize / 2;

    // Draw dark overlay minus the scan window
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, scanSize, scanSize),
            const Radius.circular(16),
          )),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Corner Accent Widget ───────────────────────────────────────
class _Corner extends StatelessWidget {
  final double? top, left, right, bottom;
  final double rotate;

  const _Corner(
      {this.top, this.left, this.right, this.bottom, required this.rotate});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Transform.rotate(
        angle: rotate * 3.14159 / 180,
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: 3),
              left: BorderSide(color: Colors.white, width: 3),
            ),
          ),
        ),
      ),
    );
  }
}