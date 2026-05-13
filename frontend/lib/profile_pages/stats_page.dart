import 'package:flutter/material.dart';
import 'package:main_app/profile_pages/stats_box.dart';
import 'package:provider/provider.dart';
import 'package:main_app/pages/accessibility_provider.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiche',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            StatBox(
              title: 'Tempo di utilizzo totale',
              value: '0',
              unit: 'min',
              icon: Icons.timer,
              onTap: () {
                accessibilityProvider.triggerHapticFeedback();
              },
            ),

            const SizedBox(height: 16),

            StatBox(
              title: 'Ostacoli rilevati',
              value: '0',
              unit: '',
              icon: Icons.warning_amber_rounded,
              onTap: () {
                accessibilityProvider.triggerHapticFeedback();
                accessibilityProvider.speak('Ostacoli rilevati: 0');
              },
            ),
          ],
        ),
      ),
    );
  }
}


