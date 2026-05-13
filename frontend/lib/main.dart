import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:main_app/pages/detect_page.dart';
import 'package:main_app/pages/accessibility_page.dart';
import 'package:main_app/pages/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:main_app/pages/accessibility_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final accessibilityProvider = AccessibilityProvider();
  await accessibilityProvider.loadSettings();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => ChangeNotifierProvider.value(
        value: accessibilityProvider,
        child: const MyApp(),
      ),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, accessibilityProvider, child) {
        return MaterialApp(
          title: 'VisionAID',
          theme: accessibilityProvider.getTheme(context),
          builder: (context, child) {
            return MediaQuery(data: MediaQuery.of(context).copyWith(
              textScaleFactor: accessibilityProvider.textScaleFactor,
            ),
            child: child!,
          );
        },
        home: const MainPage(),
        debugShowCheckedModeBanner: false,
      );
    });
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DetectPage(),
    AccessibilityPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);

    return Scaffold(
      
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          accessibilityProvider.triggerHapticFeedback();


          final pageNames = ['Detect', 'Accessibilità', 'Profilo'];
          accessibilityProvider.speak('Pagina ${pageNames[index]}');
        },


        selectedItemColor: accessibilityProvider.highContrast ? Colors.white : null,
        unselectedItemColor: accessibilityProvider.highContrast ? Colors.grey[400] : null,
        backgroundColor: accessibilityProvider.highContrast ? Colors.black : null,

        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.visibility,
            ),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.accessibility_new,
              color: accessibilityProvider.highContrast ? Colors.white : null
            ),
            label: 'Accessibilità',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: accessibilityProvider.highContrast ? Colors.white : null
            ),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }
}


Widget detect(BuildContext context) {
  return MaterialApp(
    title: 'Detect App',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    ),
    home: const DetectPage(),
  );
}

@override
Widget stats(BuildContext context) {
  return MaterialApp(
    title: 'Accessibility Page',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    ),
    home: const AccessibilityPage(),
  );
}

@override
Widget accessibility(BuildContext context) {
  return MaterialApp(
    title: 'Accessibility Page',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    ),
    home: const AccessibilityPage(),
  );
}
