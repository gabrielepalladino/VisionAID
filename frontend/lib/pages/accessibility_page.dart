import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:main_app/pages/accessibility_provider.dart';

class AccessibilityPage extends StatelessWidget {
  const AccessibilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);

    // Se l'alto contrasto è attivo, usiamo uno Scaffold con sfondo nero.
    // Se preferisci gestire lo sfondo solo tramite il MaterialApp (punto 1),
    // puoi rimuovere il parametro backgroundColor qui sotto.
    return Scaffold(
      backgroundColor: accessibilityProvider.highContrast ? Colors.black : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accessibilità',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: accessibilityProvider.highContrast ? Colors.white : null,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildTextSizeSection(context),
                    const SizedBox(height: 24),
                    _buildHighContrastTile(context),
                    const SizedBox(height: 16),
                    _buildVoiceGuidanceTile(context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextSizeSection(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isHighContrast = accessibilityProvider.highContrast;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Se alto contrasto, lo sfondo del box è nero, altrimenti usa il colore del tema
        color: isHighContrast ? Colors.grey[900] : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        // Bordo bianco in alto contrasto
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_fields,
                color: isHighContrast ? Colors.white : Colors.blue,
              ),
              const SizedBox(width: 12),
              Text(
                'Dimensione testo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isHighContrast ? Colors.white : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('A', style: TextStyle(fontSize: 14, color: isHighContrast ? Colors.white : null)),
              Expanded(
                child: Slider(
                  value: accessibilityProvider.textSize,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: accessibilityProvider.textSize.round().toString(),
                  onChanged: (value) {
                    accessibilityProvider.setTextSize(value);
                    accessibilityProvider.triggerHapticFeedback();
                    accessibilityProvider.speak(
                      'Dimensione testo ${value.round()}',
                    );
                  },
                  // Colori dello slider in alto contrasto
                  activeColor: isHighContrast ? Colors.grey[800] : null,
                  inactiveColor: isHighContrast ? Colors.white : null,
                  thumbColor: isHighContrast ? Colors.white : null,
                ),
              ),
              Text('A', style: TextStyle(fontSize: 24, color: isHighContrast ? Colors.white : null)),
            ],
          ),
          Center(
            child: Text(
              'Anteprima testo',
              style: TextStyle(
                fontSize: 12 + (accessibilityProvider.textSize * 4),
                color: isHighContrast ? Colors.white : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighContrastTile(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    
    return _buildSwitchTile(
      context: context,
      title: 'Alto contrasto',
      subtitle: 'Migliora la leggibilità con colori contrastati',
      icon: Icons.contrast,
      value: accessibilityProvider.highContrast,
      onChanged: (value) {
        accessibilityProvider.setHighContrast(value);
        accessibilityProvider.triggerHapticFeedback();
        accessibilityProvider.speak(
          value ? 'Alto contrasto attivato' : 'Alto contrasto disattivato',
        );
      },
    );
  }

  Widget _buildVoiceGuidanceTile(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    
    return _buildSwitchTile(
      context: context,
      title: 'Guida vocale',
      subtitle: 'Attiva le istruzioni vocali',
      icon: Icons.record_voice_over,
      value: accessibilityProvider.voiceGuidance,
      onChanged: (value) {
        accessibilityProvider.setVoiceGuidance(value);
        accessibilityProvider.triggerHapticFeedback();
      },
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isHighContrast = accessibilityProvider.highContrast;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.grey[900] : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isHighContrast ? Colors.white : Colors.blue,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isHighContrast ? Colors.white : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isHighContrast ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            // Personalizzazione dello switch per l'alto contrasto
            activeColor: isHighContrast ? Colors.white : null,
            activeTrackColor: isHighContrast ? Colors.grey[800] : Colors.white,
            inactiveThumbColor: isHighContrast ? Colors.white24 : null,
            inactiveTrackColor: isHighContrast ? Colors.white10 : null,
          ),
        ],
      ),
    );
  }
}