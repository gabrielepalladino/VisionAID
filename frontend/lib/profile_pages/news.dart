import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:main_app/pages/accessibility_provider.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  static final List<Map<String, String>> _newsList = [
    {
      'title': 'Aggiornamento App',
      'version': 'v2.0.0',
      'description':
          'Nuova interfaccia utente con supporto all\'accessibilità migliorato. '
              'Aggiunto supporto per l\'alto contrasto e il feedback aptico.',
    },
    {
      'title': 'Nuove Funzionalità',
      'version': 'v1.5.0',
      'description':
          'Introdotta la sintesi vocale per tutti i menu principali. '
              'Migliorata la navigazione tra le schermate.',
    },
    {
      'title': 'Correzioni Bug',
      'version': 'v1.4.2',
      'description':
          'Risolti problemi di visualizzazione su dispositivi con schermo piccolo. '
              'Ottimizzate le prestazioni generali dell\'applicazione.',
    },
    {
      'title': 'Prima Release',
      'version': 'v1.0.0',
      'description':
          'Benvenuto nella prima versione ufficiale dell\'app! '
              'Scopri tutte le funzionalità disponibili.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final bool highContrast = accessibilityProvider.highContrast;

    return Scaffold(
      backgroundColor: highContrast ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: highContrast ? Colors.black : Colors.blue,
        foregroundColor: Colors.white,
        title: Text(
          'Novità',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            accessibilityProvider.triggerHapticFeedback();
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _newsList.length,
        itemBuilder: (context, index) {
          final news = _newsList[index];
          return _NewsCard(
            title: news['title']!,
            version: news['version']!,
            description: news['description']!,
            highContrast: highContrast,
            accessibilityProvider: accessibilityProvider,
          );
        },
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final String title;
  final String version;
  final String description;
  final bool highContrast;
  final dynamic accessibilityProvider;

  const _NewsCard({
    required this.title,
    required this.version,
    required this.description,
    required this.highContrast,
    required this.accessibilityProvider,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        accessibilityProvider.triggerHapticFeedback();
        accessibilityProvider.speak('$title, versione $version. $description');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: highContrast ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: highContrast
              ? Border.all(color: Colors.white, width: 1.5)
              : null,
          boxShadow: highContrast
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titolo + Badge versione
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: highContrast ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: highContrast ? Colors.white : Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      version,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: highContrast ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Descrizione
              Text(
                description,
                style: TextStyle(
                  color: highContrast ? Colors.white70 : Colors.black54,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}