import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:main_app/pages/accessibility_provider.dart';

class AccessibilityPage extends StatelessWidget {
  const AccessibilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accessibilità',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
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
                  _buildHapticFeedbackTile(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSizeSection(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: accessibilityProvider.highContrast
            ? Border.all(color: Colors.black, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_fields,
                color: accessibilityProvider.highContrast
                    ? Colors.black
                    : Colors.blue,
              ),
              const SizedBox(width: 12),
              const Text(
                'Dimensione testo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('A', style: TextStyle(fontSize: 14)),
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
                  activeColor: accessibilityProvider.highContrast
                      ? Colors.black
                      : null,
                ),
              ),
              const Text('A', style: TextStyle(fontSize: 24)),
            ],
          ),
          Center(
            child: Text(
              'Esempio di testo',
              style: TextStyle(
                fontSize: 12 + (accessibilityProvider.textSize * 4),
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

  Widget _buildHapticFeedbackTile(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    
    return _buildSwitchTile(
      context: context,
      title: 'Feedback tattile',
      subtitle: 'Vibrazioni per confermare le azioni',
      icon: Icons.vibration,
      value: accessibilityProvider.hapticFeedback,
      onChanged: (value) {
        accessibilityProvider.setHapticFeedback(value);
        accessibilityProvider.speak(
          value ? 'Feedback tattile attivato' : 'Feedback tattile disattivato',
        );
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
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: accessibilityProvider.highContrast
            ? Border.all(color: Colors.black, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: accessibilityProvider.highContrast ? Colors.black : Colors.blue,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: accessibilityProvider.highContrast
                        ? Colors.black
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}