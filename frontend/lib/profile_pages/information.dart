import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:main_app/pages/accessibility_provider.dart'; // adatta il path se necessario

class InformazioniScreen extends StatelessWidget {
  const InformazioniScreen({super.key});

  // ── Dati app ────────────────────────────────────────────────────────────────
  static const String _appName        = 'VisionAid';
  static const String _version        = '2.1.4';
  static const String _build          = 'B20250228-1142';
  static const String _releaseDate    = '28 Febbraio 2025';
  static const String _copyright      = '© 2025 VisionAid. Tutti i diritti riservati.';
  static const String _privacyUrl     = 'https://tuosito.altervista.org/privacy.php';
  static const String _termsUrl       = 'https://tuosito.altervista.org/termini.php';
  static const String _supportEmail   = 'support@tuosito.com';

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
          'Informazioni',
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Hero versione ────────────────────────────────────────────────
          _HeroCard(hc: hc, acc: acc),
          const SizedBox(height: 20),

          // ── Dettagli build ───────────────────────────────────────────────
          _SectionCard(
            hc: hc,
            icon: Icons.info_outline_rounded,
            title: 'Dettagli applicazione',
            children: [
              _InfoRow(label: 'Nome',           value: _appName,      hc: hc),
              _InfoRow(label: 'Versione',       value: _version,      hc: hc),
              _InfoRow(label: 'Numero di build',value: _build,        hc: hc, isMono: true, copyable: true, acc: acc),
              _InfoRow(label: 'Data rilascio',  value: _releaseDate,  hc: hc),
              _InfoRow(label: 'Piattaforme',    value: 'Android, iOS',hc: hc),
            ],
          ),
          const SizedBox(height: 16),

          // ── Requisiti ────────────────────────────────────────────────────
          _SectionCard(
            hc: hc,
            icon: Icons.phone_android_rounded,
            title: 'Requisiti di sistema',
            children: [
              _InfoRow(label: 'Android minimo', value: 'Android 8.0 (Oreo)', hc: hc),
              _InfoRow(label: 'iOS minimo',     value: 'iOS 14.0',           hc: hc),
            ],
          ),
          const SizedBox(height: 16),

          // ── Note legali ──────────────────────────────────────────────────
          _SectionCard(
            hc: hc,
            icon: Icons.gavel_rounded,
            title: 'Note legali',
            children: [
              _LegalText(
                title: 'Copyright',
                body: _copyright,
                hc: hc,
              ),
              _LegalText(
                title: 'Licenza d\'uso',
                body:
                    'L\'applicazione è concessa in licenza d\'uso personale e non '
                    'trasferibile. È vietata la riproduzione, distribuzione o '
                    'modifica del software senza autorizzazione scritta.',
                hc: hc,
              ),
              _LegalText(
                title: 'Trattamento dei dati (GDPR)',
                body:
                    'I dati personali raccolti (email, modello dispositivo, OS) '
                    'sono trattati in conformità al Regolamento UE 2016/679 e al '
                    'D.Lgs. 196/2003, esclusivamente per finalità di supporto tecnico.',
                hc: hc,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Link utili ───────────────────────────────────────────────────
          _SectionCard(
            hc: hc,
            icon: Icons.link_rounded,
            title: 'Link utili',
            children: [
              _LinkRow(
                label: 'Privacy Policy',
                url: _privacyUrl,
                hc: hc,
                acc: acc,
                context: context,
              ),
              _LinkRow(
                label: 'Termini e condizioni',
                url: _termsUrl,
                hc: hc,
                acc: acc,
                context: context,
              ),
              _LinkRow(
                label: 'Contatta il supporto',
                url: 'mailto:$_supportEmail',
                hc: hc,
                acc: acc,
                context: context,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Footer copyright ─────────────────────────────────────────────
          Center(
            child: Text(
              _copyright,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: hc ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Hero card con nome app e versione ─────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final bool hc;
  final dynamic acc;

  const _HeroCard({required this.hc, required this.acc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hc ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: hc ? Border.all(color: Colors.white24) : null,
        boxShadow: hc
            ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Icona app
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: hc ? Colors.white : Colors.blue,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (hc ? Colors.white : Colors.blue).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.visibility_rounded,
              color: hc ? Colors.black : Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  InformazioniScreen._appName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hc ? Colors.white : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versione ${InformazioniScreen._version}',
                  style: TextStyle(
                    color: hc ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                // Badge stabile
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: hc ? Colors.white.withOpacity(0.1) : Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hc ? Colors.white30 : Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 12,
                          color: hc ? Colors.greenAccent : Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Versione stabile',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: hc ? Colors.greenAccent : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card sezione con header e figli ──────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final bool hc;
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.hc,
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: hc ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: hc ? Border.all(color: Colors.white24) : null,
        boxShadow: hc
            ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header sezione
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: hc ? Colors.white.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: hc ? Colors.white : Colors.blue),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hc ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: hc ? Colors.white12 : Colors.grey[200]),
          ...children,
        ],
      ),
    );
  }
}

// ── Riga info label/valore ────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool hc;
  final bool isMono;
  final bool copyable;
  final dynamic acc;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.hc,
    this.isMono = false,
    this.copyable = false,
    this.acc,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: copyable
          ? () {
              Clipboard.setData(ClipboardData(text: value));
              acc?.triggerHapticFeedback();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Build copiata negli appunti'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: hc ? Colors.white12 : Colors.grey[100]!, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: hc ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: hc ? Colors.white : Colors.black87,
                        fontFamily: isMono ? 'monospace' : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Blocco testo legale ───────────────────────────────────────────────────────
class _LegalText extends StatelessWidget {
  final String title;
  final String body;
  final bool hc;
  final bool isLast;

  const _LegalText({
    required this.title,
    required this.body,
    required this.hc,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: hc ? Colors.white12 : Colors.grey[100]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: hc ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: hc ? Colors.white60 : Colors.black54,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Riga link esterno ─────────────────────────────────────────────────────────
class _LinkRow extends StatelessWidget {
  final String label;
  final String url;
  final bool hc;
  final dynamic acc;
  final BuildContext context;
  final bool isLast;

  const _LinkRow({
    required this.label,
    required this.url,
    required this.hc,
    required this.acc,
    required this.context,
    this.isLast = false,
  });

  void _open() {
    acc?.triggerHapticFeedback();
    acc?.speak(label);
    // Usa url_launcher se disponibile:
    // launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: _open,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: hc ? Colors.white12 : Colors.grey[100]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: hc ? Colors.white : Colors.blue,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: hc ? Colors.white38 : Colors.blue.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}