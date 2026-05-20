import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// ============================================================================
// ENUM E CLASSI DATA
// ============================================================================

enum RiskLevel { critical, high, medium, low, safe }

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
    RiskLevel riskLevel = RiskLevel.values.firstWhere(
      (e) => e.name.toUpperCase() == (json['risk'] as String).toUpperCase(),
      orElse: () => RiskLevel.low,
    );

    return Alert(
      cls: json['cls'] as String,
      risk: riskLevel,
      message: json['message'] as String,
      conf: (json['conf'] as num).toDouble(),
      box: List<double>.from((json['box'] as List).map((x) => (x as num).toDouble())),
    );
  }
}

class ServerResponse {
  final List<Alert> alerts;
  final int trackedCount;
  final String status;
  final int frame;

  ServerResponse({
    required this.alerts,
    required this.trackedCount,
    required this.status,
    required this.frame,
  });

  factory ServerResponse.fromJson(Map<String, dynamic> json) {
    return ServerResponse(
      alerts: (json['alerts'] as List?)
          ?.map((a) => Alert.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
      trackedCount: json['tracked_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'ok',
      frame: json['frame'] as int? ?? 0,
    );
  }
}

// ============================================================================
// CLASSE PER VIBRAZIONE E SUONO
// ============================================================================

class AlertHandler {
  // Trigger vibrazione per TUTTI gli alert
  static Future<void> triggerVibration(Alert alert) async {
    try {
      if (alert.risk == RiskLevel.critical) {
        // CRITICAL: 3 vibrazione heavy
        await HapticFeedback.heavyImpact();
        await Future.delayed(Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
        await Future.delayed(Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
      } else if (alert.risk == RiskLevel.high) {
        // HIGH: 2 vibrazione medium
        await HapticFeedback.mediumImpact();
        await Future.delayed(Duration(milliseconds: 150));
        await HapticFeedback.mediumImpact();
      } else if (alert.risk == RiskLevel.medium) {
        // MEDIUM: 1 vibrazione light
        await HapticFeedback.lightImpact();
      }
    } catch (e) {
      print("[VIBRATION] Errore: $e");
    }
  }

  // Trigger suono SOLO per CRITICAL
  static Future<void> triggerSound(Alert alert) async {
    try {
      if (alert.risk == RiskLevel.critical) {
        // CRITICAL: Play system sound (3 volte)
        await _playSystemBeep();
        await Future.delayed(Duration(milliseconds: 200));
        await _playSystemBeep();
        await Future.delayed(Duration(milliseconds: 200));
        await _playSystemBeep();
      }
    } catch (e) {
      print("[SOUND] Errore: $e");
    }
  }

  // Suono di sistema usando HapticFeedback
  static Future<void> _playSystemBeep() async {
    try {
      // Usa il metodo di sistema per fare un beep
      await SystemChannels.platform.invokeMethod('Vibrator.vibrate', [100]);
    } catch (e) {
      // Se fallisce, usa comunque HapticFeedback
      await HapticFeedback.heavyImpact();
    }
  }
}

// ============================================================================
// MAIN CAMERA SCREEN
// ============================================================================

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  static const String _wsUrl = 'wss://visionaidserver.duckdns.org/detect';
  static const int _bboxPersistenceMs = 1500; // Bbox rimane 1.5 secondi
  static const int _notificationDurationMs = 3000; // Notifica rimane 3 secondi

  late CameraController _cam;
  WebSocketChannel? _channel;
  List<Alert> _currentAlerts = [];
  List<Alert> _persistentAlerts = [];
  String? _notificationMessage;
  String _status = 'Disconnesso';
  bool _connected = false;
  Timer? _captureTimer;
  Timer? _persistenceTimer;
  Timer? _notificationTimer;
  int _frameCount = 0;
  int _trackedCount = 0;
  final Map<String, DateTime> _lastAlertTime = {};

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cam = CameraController(
      widget.cameras[0],
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _cam.initialize();
    if (mounted) setState(() {});
  }

  void _connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      setState(() {
        _status = 'Connesso';
        _connected = true;
      });

      _channel!.stream.listen(
        (msg) {
          try {
            final Map<String, dynamic> json = jsonDecode(msg);
            final response = ServerResponse.fromJson(json);

            setState(() {
              _currentAlerts = response.alerts;
              _frameCount = response.frame;
              _trackedCount = response.trackedCount;
            });

            _processAlerts(response.alerts);
          } catch (e) {
            print("[APP] Errore parsing: $e");
          }
        },
        onError: (e) {
          setState(() {
            _status = 'Errore WebSocket: $e';
            _connected = false;
          });
        },
        onDone: () {
          setState(() {
            _status = 'Disconnesso';
            _connected = false;
          });
        },
      );

      _captureTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
        if (!_connected || !_cam.value.isInitialized) return;
        try {
          final XFile file = await _cam.takePicture();
          final Uint8List bytes = await file.readAsBytes();
          _channel?.sink.add(bytes);
        } catch (e) {
          print("[APP] Errore cattura: $e");
        }
      });

      print("[APP] Connessione stabilita");
    } catch (e) {
      setState(() => _status = 'Errore connessione: $e');
    }
  }

  void _processAlerts(List<Alert> alerts) {
    for (final alert in alerts) {
      final now = DateTime.now();
      final alertKey = "${alert.cls}_${alert.risk.name}";

      final lastTime = _lastAlertTime[alertKey];
      if (lastTime != null && now.difference(lastTime).inSeconds < 2) {
        continue;
      }

      _lastAlertTime[alertKey] = now;

      print("[ALERT] [${alert.risk.name}] ${alert.cls}: ${alert.message}");

      // =========================================================================
      // VIBRAZIONE PER TUTTI GLI ALERT
      // =========================================================================
      AlertHandler.triggerVibration(alert);

      // =========================================================================
      // SUONO SOLO PER CRITICAL
      // =========================================================================
      if (alert.risk == RiskLevel.critical) {
        AlertHandler.triggerSound(alert);
      }

      // =========================================================================
      // NOTIFICA SOLO PER CRITICAL
      // =========================================================================
      if (alert.risk == RiskLevel.critical) {
        _showNotification("⚠️ PERICOLO CRITICO!\n${alert.cls.toUpperCase()}");
      }

      // Bbox persistente per TUTTI i risk levels
      setState(() {
        _persistentAlerts.clear();
        _persistentAlerts.add(alert);
      });

      // Rimuovi la bbox dopo N millisecondi
      _persistenceTimer?.cancel();
      _persistenceTimer = Timer(Duration(milliseconds: _bboxPersistenceMs), () {
        if (mounted) {
          setState(() {
            _persistentAlerts.clear();
          });
        }
      });
    }
  }

  // =========================================================================
  // MOSTRA NOTIFICA (SOLO PER CRITICAL)
  // =========================================================================

  void _showNotification(String message) {
    _notificationTimer?.cancel();

    setState(() {
      _notificationMessage = message;
    });

    // Nascondi la notifica dopo N millisecondi
    _notificationTimer = Timer(Duration(milliseconds: _notificationDurationMs), () {
      if (mounted) {
        setState(() {
          _notificationMessage = null;
        });
      }
    });
  }

  void _disconnect() {
    _captureTimer?.cancel();
    _persistenceTimer?.cancel();
    _notificationTimer?.cancel();
    _channel?.sink.close();
    setState(() {
      _connected = false;
      _status = 'Disconnesso';
      _currentAlerts = [];
      _persistentAlerts = [];
      _notificationMessage = null;
    });
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _persistenceTimer?.cancel();
    _notificationTimer?.cancel();
    _channel?.sink.close();
    _cam.dispose();
    super.dispose();
  }

  Color _getRiskColor(RiskLevel risk) {
    switch (risk) {
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

  @override
  Widget build(BuildContext context) {
    if (!_cam.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final size = MediaQuery.of(context).size;
    final scale = 1 / (_cam.value.aspectRatio * size.aspectRatio);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          Transform.scale(
            scale: scale < 1 ? 1 / scale : scale,
            child: Center(child: CameraPreview(_cam)),
          ),

          // Disegna bbox persistenti
          if (_persistentAlerts.isNotEmpty)
            CustomPaint(painter: AlertBoxPainter(_persistentAlerts)),

          // Status bar superiore
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                ),
                child: Row(
                  children: [
                    Icon(
                      _connected ? Icons.circle : Icons.circle_outlined,
                      color: _connected ? Colors.greenAccent : Colors.grey,
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      'Frame: $_frameCount | Tracciati: $_trackedCount',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // NOTIFICA CRITICA (Grande, al centro) - SOLO PER CRITICAL
          if (_notificationMessage != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.redAccent,
                      width: 4,
                    ),
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
                        _notificationMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '🚨 PERICOLO IMMINENTE! 🚨',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Connect/Disconnect button
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _connected ? _disconnect : _connect,
                icon: Icon(_connected ? Icons.stop : Icons.play_arrow),
                label: Text(_connected ? 'Stop' : 'Connetti'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _connected ? Colors.redAccent : Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
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

// ============================================================================
// CUSTOM PAINTER PER BBOX
// ============================================================================

class AlertBoxPainter extends CustomPainter {
  final List<Alert> alerts;

  AlertBoxPainter(this.alerts);

  Color _getRiskColor(RiskLevel risk) {
    switch (risk) {
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

  @override
  void paint(Canvas canvas, Size size) {
    for (final alert in alerts) {
      if (alert.box.length < 4) continue;

      final x1 = alert.box[0] * size.width;
      final y1 = alert.box[1] * size.height;
      final x2 = alert.box[2] * size.width;
      final y2 = alert.box[3] * size.height;

      final rect = Rect.fromLTRB(x1, y1, x2, y2);
      final color = _getRiskColor(alert.risk);

      // Disegna box
      canvas.drawRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

      // Disegna label
      final label = '${alert.cls} ${(alert.conf * 100).toStringAsFixed(0)}% [${alert.risk.name}]';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelRect = Rect.fromLTWH(x1, y1 - 22, tp.width + 10, 20);
      canvas.drawRect(labelRect, Paint()..color = color);
      tp.paint(canvas, Offset(x1 + 5, y1 - 20));
    }
  }

  @override
  bool shouldRepaint(AlertBoxPainter old) => old.alerts != alerts;
}