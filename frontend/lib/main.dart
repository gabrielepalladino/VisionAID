import 'package:camera/camera.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:main_app/pages/accessibility_provider.dart';
import 'package:main_app/pages/accessibility_page.dart';
import 'package:main_app/pages/detect_page.dart';
import 'package:main_app/pages/profile_page.dart';
import 'package:provider/provider.dart';

List<CameraDescription> appCameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    appCameras = await availableCameras();
  } catch (e) {
    debugPrint('[VisionAID] Camera discovery failed: $e');
  }

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
      builder: (context, ap, child) {
        return MaterialApp(
          title: 'VisionAID',
          theme: ap.getTheme(context),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaleFactor: ap.textScaleFactor),
              child: child!,
            );
          },
          home: const MainPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // DetectPage receives the camera list discovered in main().
  late final List<Widget> _pages = [
    DetectPage(cameras: appCameras),
    const AccessibilityPage(),
    const ProfilePage(),
  ];

  static const _pageNames = ['Detect', 'Accessibilità', 'Profilo'];

  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AccessibilityProvider>(context);

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          ap.triggerHapticFeedback();
          ap.speak('Pagina ${_pageNames[index]}');
        },
        selectedItemColor: ap.highContrast ? Colors.white : null,
        unselectedItemColor: ap.highContrast ? Colors.grey[400] : null,
        backgroundColor: ap.highContrast ? Colors.black : null,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.visibility),
            label: 'Detect',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.accessibility_new),
            label: 'Accessibilità',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }
}