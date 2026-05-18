import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:main_app/pages/accessibility_provider.dart';
import 'package:main_app/profile_pages/stats_page.dart';
import 'package:main_app/profile_pages/news.dart';
import 'package:main_app/profile_pages/information.dart';
import 'package:main_app/profile_pages/guide.dart';
import 'package:main_app/profile_pages/support.dart';
import 'package:main_app/profile_pages/general_sett.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
        backgroundColor: accessibilityProvider.highContrast ? Colors.black : null,
        foregroundColor: accessibilityProvider.highContrast ? Colors.white : null,
      ),
      backgroundColor: accessibilityProvider.highContrast ? Colors.black : Colors.grey[100],
      body: ListView(
        children: [
          _buildMenuItem(
            context,
            icon: Icon(
              Icons.settings,
              color: accessibilityProvider.highContrast ? Colors.white : Colors.blue,
            ),
            title: 'Impostazioni generali',
            onTap: () {
              accessibilityProvider.triggerHapticFeedback();
              accessibilityProvider.speak('Impostazioni generali');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ImpostazioniGeneraliScreen())
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icon(
              Icons.menu_book,
              color: accessibilityProvider.highContrast ? Colors.white : Colors.blue,
            ),
            title: 'Guida',
            onTap: () {
              accessibilityProvider.triggerHapticFeedback();
              accessibilityProvider.speak('Guida');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GuidaScreen())
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icon(
              Icons.headset_mic,
              color: accessibilityProvider.highContrast ? Colors.white : Colors.blue,
            ),
            title: 'Supporto',
            onTap: () {
              accessibilityProvider.triggerHapticFeedback();
              accessibilityProvider.speak('Supporto');
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const Support()));
            },
          ),
          _buildMenuItem(
            context,
            icon: Icon(
              Icons.new_releases,
              color: accessibilityProvider.highContrast ? Colors.white : Colors.blue,
            ),
            title: 'Novità',
            onTap: () {
              accessibilityProvider.triggerHapticFeedback();
              accessibilityProvider.speak('Novità');

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewsScreen()),
              );

            },
          ),
          _buildMenuItem(
            context,
            icon: Icon(
              Icons.info,
              color: accessibilityProvider.highContrast ? Colors.white : Colors.blue,
            ),
            title: 'Informazioni',
            onTap: () {
              accessibilityProvider.triggerHapticFeedback();
              accessibilityProvider.speak('Informazioni');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InformazioniScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: accessibilityProvider.highContrast ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: accessibilityProvider.highContrast
            ? Border.all(color: Colors.white, width: 1)
            : null,
      ),
      child: ListTile(
        leading: icon,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: accessibilityProvider.highContrast ? Colors.white : Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: accessibilityProvider.highContrast ? Colors.white : Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}