import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:main_app/pages/accessibility_provider.dart';

class Support extends StatefulWidget {
  const Support({super.key});

  @override
  State<Support> createState() => _SupportState();
}

class _SupportState extends State<Support> {
  static const String _registerUrl    = 'https://visionaid.altervista.org/register_user.php';
  static const String _ticketUrl      = 'https://visionaid.altervista.org/create_ticket.php';
  static const String _deviceUrl      = 'https://visionaid.altervista.org/register_device.php';
  static const String _userIdKey      = 'anonymous_user_id';
  static const String _userRegistered = 'user_registered';
  static const String _deviceRegistered = 'device_registered';

  final _formKey     = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  bool    _isLoading       = false;
  String? _selectedCategory; // 'app' | 'device'

  // ─── Recupera o genera lo user_id persistente ─────────────────────────────
  Future<String> _getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_userIdKey);
    if (userId == null) {
      userId = const Uuid().v4();
      await prefs.setString(_userIdKey, userId);
    }
    return userId;
  }

  // ─── Registra l'utente al primo avvio (se non già fatto) ──────────────────
  Future<bool> _ensureUserRegistered(String userId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_userRegistered) == true) return true;

    try {
      final deviceInfo  = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion  = packageInfo.version;

      String os          = 'other';
      String deviceModel = 'unknown';

      try {
        if (Platform.isAndroid) {
          final info = await deviceInfo.androidInfo;
          os          = 'android';
          deviceModel = info.model;
        } else if (Platform.isIOS) {
          final info = await deviceInfo.iosInfo;
          os          = 'ios';
          deviceModel = info.utsname.machine;
        }
      } catch (e) {
        debugPrint('⚠️ Device info non disponibile: $e');
      }

      final response = await http.post(
        Uri.parse(_registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id':      userId,
          'email':        email,
          'app_version':  appVersion,
          'os':           os,
          'device_model': deviceModel,
        }),
      ).timeout(const Duration(seconds: 20));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        await prefs.setBool(_userRegistered, true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Registrazione utente fallita: $e');
      return false;
    }
  }

  // ─── Registra il dispositivo fisico (solo se problema hardware) ───────────
  Future<bool> _ensureDeviceRegistered(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_deviceRegistered) == true) return true;

    try {
      final deviceInfo = DeviceInfoPlugin();
      String internalDeviceId = 'unknown';

      try {
        if (Platform.isAndroid) {
          final info = await deviceInfo.androidInfo;
          internalDeviceId = info.id; // Android hardware ID
        } else if (Platform.isIOS) {
          final info = await deviceInfo.iosInfo;
          internalDeviceId = info.identifierForVendor ?? 'unknown';
        }
      } catch (e) {
        debugPrint('⚠️ Device ID non disponibile: $e');
      }

      final response = await http.post(
        Uri.parse(_deviceUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id':            userId,
          'internal_device_id': internalDeviceId,
        }),
      ).timeout(const Duration(seconds: 20));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        await prefs.setBool(_deviceRegistered, true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Registrazione device fallita: $e');
      return false;
    }
  }

  // ─── Invio ticket ──────────────────────────────────────────────────────────
  Future<void> _submitTicket(AccessibilityProvider acc) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    acc.triggerHapticFeedback();

    try {
      final userId     = await _getOrCreateUserId();
      final registered = await _ensureUserRegistered(userId, _emailCtrl.text.trim());

      if (!registered) {
        acc.speak('Errore di registrazione.');
        _showResultDialog(
          success: false,
          message: 'Impossibile registrare il dispositivo.\nControlla la connessione e riprova.',
        );
        return;
      }

      // Se il problema riguarda l'hardware, registra il device fisico
      if (_selectedCategory == 'device') {
        final deviceOk = await _ensureDeviceRegistered(userId);
        if (!deviceOk) {
          acc.speak('Errore registrazione dispositivo.');
          _showResultDialog(
            success: false,
            message: 'Impossibile registrare il dispositivo fisico.\nControlla la connessione e riprova.',
          );
          return;
        }
      }

      final response = await http.post(
        Uri.parse(_ticketUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id':  userId,
          'email':    _emailCtrl.text.trim(),
          'subject':  _subjectCtrl.text.trim(),
          'message':  _messageCtrl.text.trim(),
          'category': _selectedCategory,
        }),
      ).timeout(const Duration(seconds: 20));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        acc.speak('Ticket inviato con successo.');
        _showResultDialog(
          success: true,
          message: 'Ticket creato con successo!\nTi risponderemo al più presto.',
        );
        _resetForm();
      } else {
        acc.speak('Errore durante l\'invio del ticket.');
        _showResultDialog(
          success: false,
          message: body['message'] ?? 'Errore sconosciuto.',
        );
      }
    } catch (e) {
      acc.speak('Errore di connessione.');
      _showResultDialog(
        success: false,
        message: 'Impossibile connettersi al server.\nControlla la connessione e riprova.',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _emailCtrl.clear();
    _subjectCtrl.clear();
    _messageCtrl.clear();
    setState(() => _selectedCategory = null);
  }

  // ─── Dialog risultato ──────────────────────────────────────────────────────
  void _showResultDialog({required bool success, required String message}) {
    final acc = Provider.of<AccessibilityProvider>(context, listen: false);
    final hc  = acc.highContrast;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: hc ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              success ? 'Inviato!' : 'Errore',
              style: TextStyle(color: hc ? Colors.white : Colors.black87),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: hc ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () {
              acc.triggerHapticFeedback();
              Navigator.pop(context);
              if (success) Navigator.pop(context);
            },
            child: Text(
              'OK',
              style: TextStyle(color: hc ? Colors.white : Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final acc = Provider.of<AccessibilityProvider>(context);
    final hc  = acc.highContrast;

    return Scaffold(
      backgroundColor: hc ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: hc ? Colors.black : Colors.blue,
        foregroundColor: Colors.white,
        title: const Text(
          'Supporto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            acc.triggerHapticFeedback();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crea un nuovo ticket',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: hc ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Il nostro team ti risponderà il prima possibile.',
                style: TextStyle(color: hc ? Colors.white54 : Colors.black45),
              ),
              const SizedBox(height: 24),

              // ── Email ──────────────────────────────────────────────────────
              _buildLabel('Email', hc),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _emailCtrl,
                hc: hc,
                hint: 'tua@email.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email obbligatoria';
                  if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v.trim())) {
                    return 'Email non valida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Oggetto ────────────────────────────────────────────────────
              _buildLabel('Oggetto', hc),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _subjectCtrl,
                hc: hc,
                hint: 'Es. App si blocca alla schermata iniziale',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Oggetto obbligatorio';
                  if (v.trim().length > 200) return 'Massimo 200 caratteri';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Tipo di problema ───────────────────────────────────────────
              _buildLabel('Tipo di problema', hc),
              const SizedBox(height: 6),
              _buildCategoryDropdown(hc),
              const SizedBox(height: 16),

              // ── Messaggio ──────────────────────────────────────────────────
              _buildLabel('Messaggio', hc),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _messageCtrl,
                hc: hc,
                hint: 'Descrivi il problema nel dettaglio...',
                maxLines: 6,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Messaggio obbligatorio';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // ── Banner info dispositivo (visibile solo se categoria = device) ──
              if (_selectedCategory == 'device') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hc ? Colors.grey[850] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hc ? Colors.white24 : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: hc ? Colors.white70 : Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Il tuo dispositivo verrà registrato automaticamente.',
                          style: TextStyle(
                            fontSize: 13,
                            color: hc ? Colors.white70 : Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Bottone invio ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _submitTicket(acc),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isLoading ? 'Invio in corso...' : 'Invia Ticket',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hc ? Colors.white : Colors.blue,
                    foregroundColor: hc ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor:
                        hc ? Colors.grey[700] : Colors.blue[200],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Widget helpers ────────────────────────────────────────────────────────

  Widget _buildLabel(String text, bool hc) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: hc ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required bool hc,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: hc ? Colors.white : Colors.black87),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hc ? Colors.white38 : Colors.black38),
        filled: true,
        fillColor: hc ? Colors.grey[900] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hc ? Colors.white30 : Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hc ? Colors.white30 : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hc ? Colors.white : Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildCategoryDropdown(bool hc) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      dropdownColor: hc ? Colors.grey[900] : Colors.white,
      style: TextStyle(color: hc ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: 'Seleziona il tipo di problema',
        hintStyle: TextStyle(color: hc ? Colors.white38 : Colors.black38),
        filled: true,
        fillColor: hc ? Colors.grey[900] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hc ? Colors.white30 : Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hc ? Colors.white30 : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hc ? Colors.white : Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: (v) => v == null ? 'Seleziona il tipo di problema' : null,
      items: [
        DropdownMenuItem(
          value: 'app',
          child: Row(
            children: [
              Icon(Icons.phone_android,
                  size: 18, color: hc ? Colors.white70 : Colors.blue),
              const SizedBox(width: 10),
              Text(
                'Problema con l\'app',
                style: TextStyle(color: hc ? Colors.white : Colors.black87),
              ),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'device',
          child: Row(
            children: [
              Icon(Icons.device_hub,
                  size: 18, color: hc ? Colors.white70 : Colors.blue),
              const SizedBox(width: 10),
              Text(
                'Problema con il dispositivo',
                style: TextStyle(color: hc ? Colors.white : Colors.black87),
              ),
            ],
          ),
        ),
      ],
      onChanged: (v) => setState(() => _selectedCategory = v),
    );
  }
}