import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:main_app/pages/accessibility_provider.dart';

// ============================================================================
// ENUMS & DATA MODELS
// ============================================================================

enum RiskLevel { critical, high, medium, low, safe }

extension RiskLevelLabel on RiskLevel {
  String get italianLabel {
    switch (this) {
      case RiskLevel.critical:
        return 'Critico';
      case RiskLevel.high:
        return 'Alto';
      case RiskLevel.medium:
        return 'Medio';
      case RiskLevel.low:
        return 'Basso';
      case RiskLevel.safe:
        return 'Sicuro';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.critical:
        return Colors.red;
      case RiskLevel.high:
        return Colors.orange;
      case RiskLevel.medium:
        return Colors.yellow;
      case RiskLevel.low:
      case RiskLevel.safe:
        return Colors.green;
    }
  }
}

class Alert {
  final String cls;
  final RiskLevel risk;
  final String message;
  final double conf;
  final List<double> box;
  final DateTime timestamp;

  Alert({
    required this.cls,
    required this.risk,
    required this.message,
    required this.conf,
    required this.box,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory Alert.fromJson(Map<String, dynamic> json) {
    final riskLevel = RiskLevel.values.firstWhere(
      (e) => e.name.toUpperCase() == (json['risk'] as String).toUpperCase(),
      orElse: () => RiskLevel.low,
    );
    return Alert(
      cls: json['cls'] as String,
      risk: riskLevel,
      message: json['message'] as String,
      conf: (json['conf'] as num).toDouble(),
      box: List<double>.from(
        (json['box'] as List).map((x) => (x as num).toDouble()),
      ),
    );
  }
}

class ServerResponse {
  final List<Alert> alerts;
  final int trackedCount;
  final String status;
  final int frame;

  const ServerResponse({
    required this.alerts,
    required this.trackedCount,
    required this.status,
    required this.frame,
  });

  factory ServerResponse.fromJson(Map<String, dynamic> json) {
    return ServerResponse(
      alerts: (json['alerts'] as List?)
              ?.map((a) => Alert.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      trackedCount: json['tracked_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'ok',
      frame: json['frame'] as int? ?? 0,
    );
  }
}

// ============================================================================
// HAPTIC & AUDIO HANDLER
// ============================================================================

class _AlertHandler {
  _AlertHandler._();

  /// Vibration pattern scaled to risk level.
  static Future<void> triggerVibration(RiskLevel risk) async {
    try {
      switch (risk) {
        case RiskLevel.critical:
          for (int i = 0; i < 3; i++) {
            await HapticFeedback.heavyImpact();
            if (i < 2) await Future.delayed(const Duration(milliseconds: 150));
          }
        case RiskLevel.high:
          for (int i = 0; i < 2; i++) {
            await HapticFeedback.mediumImpact();
            if (i < 1) await Future.delayed(const Duration(milliseconds: 150));
          }
        case RiskLevel.medium:
          await HapticFeedback.lightImpact();
        case RiskLevel.low:
        case RiskLevel.safe:
          break;
      }
    } catch (e) {
      debugPrint('[VisionAID] Haptic error: $e');
    }
  }

  /// System beep sequence for critical alerts.
  static Future<void> triggerSound() async {
    for (int i = 0; i < 3; i++) {
      try {
        await SystemChannels.platform.invokeMethod('Vibrator.vibrate', [100]);
      } catch (_) {
        await HapticFeedback.heavyImpact();
      }
      if (i < 2) await Future.delayed(const Duration(milliseconds: 200));
    }
  }
}

// ============================================================================
// DETECT PAGE  (replaces the old placeholder)
// ============================================================================

class DetectPage extends StatefulWidget {
  /// Camera list from main(). May be empty on simulators.
  final List<CameraDescription> cameras;

  const DetectPage({super.key, required this.cameras});

  @override
  State<DetectPage> createState() => _DetectPageState();
}

class _DetectPageState extends State<DetectPage> {
  // ── Config ─────────────────────────────────────────────────────────────────
  static const String _wsUrl = 'wss://visionaidserver.duckdns.org/detect';
  static const int _bboxPersistenceMs = 1500;
  static const int _notificationDurationMs = 3000;
  static const int _captureIntervalMs = 500;
  static const int _alertCooldownSeconds = 2;

  // ── Camera ─────────────────────────────────────────────────────────────────
  CameraController? _cam;
  bool _cameraReady = false;
  String? _cameraError;

  // ── WebSocket ──────────────────────────────────────────────────────────────
  WebSocketChannel? _channel;
  bool _connected = false;
  String _status = 'Disconnesso';

  // ── Alert state ────────────────────────────────────────────────────────────
  List<Alert> _persistentAlerts = [];
  String? _notificationMessage;
  int _frameCount = 0;
  int _trackedCount = 0;
  final Map<String, DateTime> _lastAlertTime = {};

  // ── Timers ─────────────────────────────────────────────────────────────────
  Timer? _captureTimer;
  Timer? _persistenceTimer;
  Timer? _notificationTimer;

  // ── Accessibility ──────────────────────────────────────────────────────────
  AccessibilityProvider get _ap =>
      Provider.of<AccessibilityProvider>(context, listen: false);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _teardown();
    _cam?.dispose();
    super.dispose();
  }

  // ── Camera init ────────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) {
      setState(() => _cameraError = 'Nessuna fotocamera disponibile sul dispositivo.');
      return;
    }
    try {
      final controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cam = controller;
        _cameraReady = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cameraError = 'Impossibile inizializzare la fotocamera: $e');
      debugPrint('[VisionAID] Camera init error: $e');
    }
  }

  // ── WebSocket connect / disconnect ─────────────────────────────────────────

  void _connect() {
    if (!_cameraReady) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      setState(() {
        _status = 'Connesso';
        _connected = true;
      });
      _ap.speak('Rilevamento avviato');

      _channel!.stream.listen(
        _onServerMessage,
        onError: _onWsError,
        onDone: _onWsDone,
      );

      _captureTimer = Timer.periodic(
        const Duration(milliseconds: _captureIntervalMs),
        (_) => _captureAndSend(),
      );

      debugPrint('[VisionAID] WebSocket connected');
    } catch (e) {
      setState(() => _status = 'Errore connessione: $e');
      debugPrint('[VisionAID] WebSocket connect error: $e');
    }
  }

  void _disconnect() {
    _teardown();
    _ap.speak('Rilevamento interrotto');
    setState(() {
      _connected = false;
      _status = 'Disconnesso';
      _persistentAlerts = [];
      _notificationMessage = null;
    });
  }

  void _teardown() {
    _captureTimer?.cancel();
    _persistenceTimer?.cancel();
    _notificationTimer?.cancel();
    _channel?.sink.close();
  }

  // ── Frame capture ──────────────────────────────────────────────────────────

  Future<void> _captureAndSend() async {
    if (!_connected || _cam == null || !_cam!.value.isInitialized) return;
    try {
      final XFile file = await _cam!.takePicture();
      final Uint8List bytes = await file.readAsBytes();
      _channel?.sink.add(bytes);
    } catch (e) {
      debugPrint('[VisionAID] Capture error: $e');
    }
  }

  // ── WebSocket callbacks ────────────────────────────────────────────────────

  void _onServerMessage(dynamic msg) {
    try {
      final Map<String, dynamic> json = jsonDecode(msg as String);
      final response = ServerResponse.fromJson(json);
      setState(() {
        _frameCount = response.frame;
        _trackedCount = response.trackedCount;
      });
      _processAlerts(response.alerts);
    } catch (e) {
      debugPrint('[VisionAID] Parse error: $e');
    }
  }

  void _onWsError(dynamic error) {
    setState(() {
      _status = 'Errore WebSocket';
      _connected = false;
    });
    debugPrint('[VisionAID] WebSocket error: $error');
  }

  void _onWsDone() {
    setState(() {
      _status = 'Disconnesso';
      _connected = false;
    });
    debugPrint('[VisionAID] WebSocket closed');
  }

  // ── Alert processing ───────────────────────────────────────────────────────

  void _processAlerts(List<Alert> alerts) {
    final now = DateTime.now();
    for (final alert in alerts) {
      // Cooldown: skip repeated alerts within N seconds
      final key = '${alert.cls}_${alert.risk.name}';
      final last = _lastAlertTime[key];
      if (last != null &&
          now.difference(last).inSeconds < _alertCooldownSeconds) {
        continue;
      }
      _lastAlertTime[key] = now;

      debugPrint('[VisionAID] [${alert.risk.name}] ${alert.cls}: ${alert.message}');

      // Haptic — always for medium+ risk
      _AlertHandler.triggerVibration(alert.risk);

      // Audio feedback via TTS (uses AccessibilityProvider voiceGuidance)
      if (alert.risk == RiskLevel.critical || alert.risk == RiskLevel.high) {
        _ap.speak('Attenzione: ${alert.cls}');
      }

      // System sound — only for critical
      if (alert.risk == RiskLevel.critical) {
        _AlertHandler.triggerSound();
        _showNotification('⚠️ PERICOLO CRITICO!\n${alert.cls.toUpperCase()}');
      }

      // Persistent bbox
      _persistenceTimer?.cancel();
      setState(() {
        _persistentAlerts = [alert];
      });
      _persistenceTimer =
          Timer(const Duration(milliseconds: _bboxPersistenceMs), () {
        if (mounted) setState(() => _persistentAlerts = []);
      });
    }
  }

  void _showNotification(String message) {
    _notificationTimer?.cancel();
    setState(() => _notificationMessage = message);
    _notificationTimer =
        Timer(const Duration(milliseconds: _notificationDurationMs), () {
      if (mounted) setState(() => _notificationMessage = null);
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // No camera available
    if (_cameraError != null) return _buildErrorState(_cameraError!);

    // Camera initialising
    if (!_cameraReady || _cam == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final ap = Provider.of<AccessibilityProvider>(context);
    final hc = ap.highContrast;
    final size = MediaQuery.of(context).size;
    final scale = 1 / (_cam!.value.aspectRatio * size.aspectRatio);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera preview ───────────────────────────────────────────────
          Transform.scale(
            scale: scale < 1 ? 1 / scale : scale,
            child: Center(child: CameraPreview(_cam!)),
          ),

          // ── Bounding boxes ───────────────────────────────────────────────
          if (_persistentAlerts.isNotEmpty)
            CustomPaint(painter: _AlertBoxPainter(_persistentAlerts)),

          // ── Top status bar ───────────────────────────────────────────────
          _buildStatusBar(hc),

          // ── Critical notification overlay ────────────────────────────────
          if (_notificationMessage != null)
            _buildCriticalOverlay(_notificationMessage!),

          // ── Connect / Disconnect button ──────────────────────────────────
          _buildConnectButton(hc),
        ],
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildErrorState(String message) {
    final hc = Provider.of<AccessibilityProvider>(context).highContrast;
    return Scaffold(
      backgroundColor: hc ? Colors.black : Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography,
                  size: 64,
                  color: hc ? Colors.white54 : Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: hc ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(bool hc) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.black87,
          child: Row(
            children: [
              Icon(
                _connected ? Icons.circle : Icons.circle_outlined,
                color: _connected ? Colors.greenAccent : Colors.grey,
                size: 11,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _status,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                'Frame: $_frameCount  |  Tracciati: $_trackedCount',
                style:
                    const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriticalOverlay(String message) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.8),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '🚨 PERICOLO IMMINENTE! 🚨',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectButton(bool hc) {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Semantics(
        button: true,
        label: _connected
            ? 'Ferma rilevamento'
            : 'Avvia rilevamento',
        child: Center(
          child: ElevatedButton.icon(
            onPressed: _connected ? _disconnect : _connect,
            icon: Icon(_connected ? Icons.stop : Icons.play_arrow),
            label: Text(_connected ? 'Stop' : 'Connetti'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _connected ? Colors.redAccent : Colors.greenAccent,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTER — bounding boxes
// ============================================================================

class _AlertBoxPainter extends CustomPainter {
  final List<Alert> alerts;
  const _AlertBoxPainter(this.alerts);

  @override
  void paint(Canvas canvas, Size size) {
    for (final alert in alerts) {
      if (alert.box.length < 4) continue;

      final x1 = alert.box[0] * size.width;
      final y1 = alert.box[1] * size.height;
      final x2 = alert.box[2] * size.width;
      final y2 = alert.box[3] * size.height;
      final rect = Rect.fromLTRB(x1, y1, x2, y2);
      final color = alert.risk.color;

      // Box stroke
      canvas.drawRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

      // Label background + text
      final label =
          '${alert.cls} ${(alert.conf * 100).toStringAsFixed(0)}% [${alert.risk.italianLabel}]';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
              color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.drawRect(
        Rect.fromLTWH(x1, y1 - 22, tp.width + 10, 20),
        Paint()..color = color,
      );
      tp.paint(canvas, Offset(x1 + 5, y1 - 20));
    }
  }

  @override
  bool shouldRepaint(_AlertBoxPainter old) => old.alerts != alerts;
}