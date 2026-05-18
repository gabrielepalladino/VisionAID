import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:main_app/pages/accessibility_provider.dart';

class ImpostazioniGeneraliScreen extends StatelessWidget {
  const ImpostazioniGeneraliScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AccessibilityProvider>(context);
    final hc  = ap.highContrast;
    return Scaffold(
      backgroundColor: ap.highContrast ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text('Impostazioni generali', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        backgroundColor: hc ? Colors.black : Colors.blue,
        foregroundColor: Colors.white,
      ),      
      body: ListView(
        children: [
          // ── Accessibilità ──────────────────────────────────────
          _buildSectionHeader(context, 'Accessibilità'),

          _buildSwitchItem(
            context,
            icon: Icons.contrast,
            title: 'Alto contrasto',
            subtitle: 'Aumenta il contrasto dei colori',
            semanticLabel:
                'Alto contrasto, interruttore, ${ap.highContrast ? "attivo" : "disattivo"}. Tocca per cambiare.',
            value: ap.highContrast,
            onChanged: (val) {
              ap.triggerHapticFeedback();
              ap.setHighContrast(val);
              ap.speak(val ? 'Alto contrasto attivato' : 'Alto contrasto disattivato');
            },
          ),

          _buildSwitchItem(
            context,
            icon: Icons.record_voice_over,
            title: 'Guida vocale',
            subtitle: 'Legge ad alta voce gli elementi',
            semanticLabel:
                'Guida vocale, interruttore, ${ap.voiceGuidance ? "attiva" : "disattiva"}. Tocca per cambiare.',
            value: ap.voiceGuidance,
            onChanged: (val) {
              ap.triggerHapticFeedback();
              ap.setVoiceGuidance(val);
            },
          ),

          _buildSwitchItem(
            context,
            icon: Icons.vibration,
            title: 'Feedback aptico',
            subtitle: 'Vibrazione al tocco degli elementi',
            semanticLabel:
                'Feedback aptico, interruttore, ${ap.hapticFeedback ? "attivo" : "disattivo"}. Tocca per cambiare.',
            value: ap.hapticFeedback,
            onChanged: (val) {
              ap.setHapticFeedback(val);
              ap.speak(val ? 'Feedback aptico attivato' : 'Feedback aptico disattivato');
            },
          ),

          // ── Testo ──────────────────────────────────────────────
          _buildSectionHeader(context, 'Testo'),

          _buildSliderItem(
            context,
            icon: Icons.text_fields,
            title: 'Dimensione testo',
            semanticLabel:
                'Dimensione testo, dispositivo di scorrimento. Valore corrente: livello ${ap.textSize.round()} su 5.',
            value: ap.textSize,
            min: 1.0,
            max: 5.0,
            divisions: 4,
            onChanged: (val) => ap.setTextSize(val),
            onChangeEnd: (val) {
              ap.triggerHapticFeedback();
              ap.speak('Dimensione testo impostata al livello ${val.round()}');
            },
          ),

          // ── Lingua ─────────────────────────────────────────────
          _buildSectionHeader(context, 'Lingua'),

          _buildMenuItem(
            context,
            icon: Icons.language,
            title: 'Lingua',
            subtitle: 'Italiano',
            semanticLabel:
                'Lingua, attualmente impostata su Italiano. Tocca per cambiare.',
            onTap: () {
              ap.triggerHapticFeedback();
              ap.speak('Selezione lingua');
              // TODO: apri selezione lingua
            },
          ),

          // ── Dati ───────────────────────────────────────────────
          _buildSectionHeader(context, 'Dati'),

          _buildMenuItem(
            context,
            icon: Icons.delete_outline,
            title: 'Cancella dati locali',
            subtitle: 'Rimuovi tutti i dati salvati sul dispositivo',
            semanticLabel:
                'Cancella dati locali. Attenzione: azione irreversibile. Tocca per procedere.',
            isDestructive: true,
            onTap: () {
              ap.triggerHapticFeedback();
              ap.speak('Cancella dati locali');
              _showConfirmDialog(context, ap);
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Builders ───────────────────────────────────────────────────

  Widget _buildSectionHeader(BuildContext context, String title) {
    final ap = Provider.of<AccessibilityProvider>(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: ap.highContrast ? Colors.white70 : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String semanticLabel,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final ap = Provider.of<AccessibilityProvider>(context);

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true, // evita duplicazione con il SwitchListTile interno
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: ap.highContrast ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: ap.highContrast
              ? Border.all(color: Colors.white, width: 1)
              : null,
        ),
        child: SwitchListTile(
          secondary: Icon(
            icon,
            color: ap.highContrast ? Colors.white : Colors.blue,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: ap.highContrast ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: ap.highContrast ? Colors.white70 : Colors.grey[600],
                  ),
                )
              : null,
          value: value,
          onChanged: onChanged,
          activeColor: ap.highContrast ? Colors.white : Colors.blue,
        ),
      ),
    );
  }

  Widget _buildSliderItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String semanticLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    final ap = Provider.of<AccessibilityProvider>(context);

    // Etichette descrittive per ogni livello
    const sizeLabels = {1: 'Molto piccolo', 2: 'Piccolo', 3: 'Normale', 4: 'Grande', 5: 'Molto grande'};
    final currentLabel = sizeLabels[value.round()] ?? 'Normale';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: ap.highContrast ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: ap.highContrast ? Border.all(color: Colors.white, width: 1) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: ap.highContrast ? Colors.white : Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ap.highContrast ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Semantics(
                  label: 'Valore corrente: $currentLabel',
                  child: Text(
                    currentLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: ap.highContrast ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            Semantics(
              slider: true,
              label: semanticLabel,
              value: currentLabel,
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
                activeColor: ap.highContrast ? Colors.white : Colors.blue,
                inactiveColor: ap.highContrast ? Colors.white30 : Colors.blue[100],
              ),
            ),
            // Anteprime della dimensione del testo
            Semantics(
              label: 'Anteprima del testo con la dimensione selezionata',
              child: Center(
                child: Text(
                  'Anteprima testo',
                  style: TextStyle(
                    fontSize: 14 * ap.textScaleFactor,
                    color: ap.highContrast ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String semanticLabel,
    String? subtitle,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final ap = Provider.of<AccessibilityProvider>(context);
    final Color activeColor = isDestructive
        ? Colors.red
        : (ap.highContrast ? Colors.white : Colors.blue);

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: ap.highContrast ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: ap.highContrast
              ? Border.all(color: Colors.white, width: 1)
              : null,
        ),
        child: ListTile(
          leading: Icon(icon, color: activeColor),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDestructive
                  ? Colors.red
                  : (ap.highContrast ? Colors.white : Colors.black87),
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: ap.highContrast ? Colors.white70 : Colors.grey[600],
                  ),
                )
              : null,
          trailing: Icon(
            Icons.chevron_right,
            color: ap.highContrast ? Colors.white : Colors.grey,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, AccessibilityProvider ap) {
    showDialog(
      context: context,
      builder: (ctx) => Semantics(
        label: 'Finestra di dialogo: conferma eliminazione dati locali',
        child: AlertDialog(
          backgroundColor: ap.highContrast ? Colors.grey[900] : Colors.white,
          title: Text(
            'Cancella dati locali',
            style: TextStyle(
                color: ap.highContrast ? Colors.white : Colors.black87),
          ),
          content: Text(
            'Sei sicuro di voler eliminare tutti i dati salvati sul dispositivo? Questa azione è irreversibile.',
            style: TextStyle(
                color: ap.highContrast ? Colors.white70 : Colors.black54),
          ),
          actions: [
            Semantics(
              label: 'Annulla: chiudi senza eliminare i dati',
              button: true,
              child: TextButton(
                onPressed: () {
                  ap.triggerHapticFeedback();
                  Navigator.pop(ctx);
                  ap.speak('Operazione annullata');
                },
                child: Text(
                  'Annulla',
                  style: TextStyle(
                      color: ap.highContrast ? Colors.white : Colors.blue),
                ),
              ),
            ),
            Semantics(
              label: 'Elimina: conferma e cancella tutti i dati locali',
              button: true,
              child: TextButton(
                onPressed: () {
                  ap.triggerHapticFeedback();
                  Navigator.pop(ctx);
                  ap.speak('Dati locali eliminati');
                  // TODO: implementa cancellazione dati
                },
                child: const Text(
                  'Elimina',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}