import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:main_app/pages/accessibility_provider.dart';

class Support extends StatefulWidget {
  const Support({super.key});

  @override
  State<Support> createState() => _SupportState();
}

class _SupportState extends State<Support> {
  // ─── Endpoint ──────────────────────────────────────────────────────────────
  static const String _apiUrl =
      'https://visionaid.altervista.org/create_ticket.php';

  // ─── Categorie ─────────────────────────────────────────────────────────────
  final List<String> _categories = [
    'Problema tecnico',
    'Errore nell\'app',
    'Richiesta funzionalità',
    'Account e accesso',
    'Altro',
  ];

  // ─── Controllers ───────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _selectedCategory;
  File?   _screenshot;
  bool    _isLoading = false;

  // ─── Screenshot picker ─────────────────────────────────────────────────────
  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() => _screenshot = File(picked.path));
    }
  }

  void _removeScreenshot() => setState(() => _screenshot = null);

  // ─── Invio ticket ──────────────────────────────────────────────────────────
  Future<void> _submitTicket(AccessibilityProvider acc) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    acc.triggerHapticFeedback();

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));

      request.fields['email'] = _emailCtrl.text.trim();
      request.fields['phone'] = _phoneCtrl.text.trim();
      request.fields['category'] = _selectedCategory ?? '';
      request.fields['description'] = _descCtrl.text.trim();

      // Screenshot in base64
      if (_screenshot != null) {
        final bytes = await _screenshot!.readAsBytes();
        final b64 = base64Encode(bytes);
        request.fields['screenshot_base64'] = b64;
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 20),
      );
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        acc.speak('Ticket inviato con successo.');
        _showResultDialog(
          success: true,
          message: 'Ticket #${body['ticket_id']} creato!\nTi risponderemo all\'indirizzo email fornito.',
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
    _phoneCtrl.clear();
    _descCtrl.clear();
    setState(() {
      _selectedCategory = null;
      _screenshot       = null;
    });
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
    _phoneCtrl.dispose();
    _descCtrl.dispose();
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
        title: Text(
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
              // Intestazione
              _SectionHeader(text: 'Crea un nuovo ticket', hc: hc),
              const SizedBox(height: 4),
              Text(
                'Il nostro team ti risponderà il prima possibile.',
                style: TextStyle(
                  color: hc ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 24),

              // Email
              _buildLabel('Email', hc),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _emailCtrl,
                hc: hc,
                hint: 'tua@email.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email obbligatoria';
                  if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v)) {
                    return 'Email non valida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Categoria
              _buildLabel('Categoria', hc),
              const SizedBox(height: 6),
              _buildDropdown(hc),
              const SizedBox(height: 16),

              // Descrizione
              _buildLabel('Descrizione', hc),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _descCtrl,
                hc: hc,
                hint: 'Descrivi il problema nel dettaglio...',
                maxLines: 5,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Descrizione obbligatoria';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bottone invio
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
                    style: TextStyle( fontWeight: FontWeight.bold),
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
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle( color: hc ? Colors.white : Colors.black87),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: hc ? Colors.white38 : Colors.black38,
        ),
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

  Widget _buildDropdown(bool hc) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      dropdownColor: hc ? Colors.grey[900] : Colors.white,
      style: TextStyle(color: hc ? Colors.white : Colors.black87),
      decoration: InputDecoration(
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      hint: Text(
        'Seleziona categoria',
        style: TextStyle(
          color: hc ? Colors.white38 : Colors.black38,
        ),
      ),
      validator: (v) => v == null ? 'Seleziona una categoria' : null,
      items: _categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) => setState(() => _selectedCategory = v),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final bool hc;

  const _SectionHeader({
    required this.text,
    required this.hc,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: hc ? Colors.white : Colors.black87,
      ),
    );
  }
}