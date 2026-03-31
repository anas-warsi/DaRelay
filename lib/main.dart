import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/identity_service.dart';
import 'services/database_service.dart';
import 'services/nearby_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';

// Global locators for simplicity in this offline app
late IdentityService identityService;
late DatabaseService databaseService;
late NearbyService nearbyService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  identityService = IdentityService();
  await identityService.init();
  
  databaseService = DatabaseService();
  await databaseService.init();
  
  nearbyService = NearbyService(
    identityService: identityService,
    databaseService: databaseService,
  );

  runApp(const CampusChatApp());
}

class CampusChatApp extends StatelessWidget {
  const CampusChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Beautiful dynamic dark theme
    return MaterialApp(
      title: 'Campus Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6), // Blue 500
          secondary: Color(0xFF8B5CF6), // Violet 500
          surface: Color(0xFF1E293B), // Slate 800
        ),
        fontFamily: 'Roboto', // System default fallback
      ),
      home: identityService.hasNickname 
          ? const DashboardScreen() 
          : const OnboardingScreen(),
    );
  }
}
