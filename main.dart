import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'models/food_entry.dart';
import 'providers/nutrition_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(FoodEntryAdapter());
  await MobileAds.instance.initialize();
  runApp(const FitLensApp());
}

class FitLensApp extends StatelessWidget {
  const FitLensApp({super.key});

  Future<bool> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboardingDone') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NutritionProvider()..init()),
      ],
      child: MaterialApp(
        title: 'FitLens',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0A0A0F),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF10B981),
            secondary: Color(0xFF10B981),
          ),
        ),
        home: FutureBuilder<bool>(
          future: _checkOnboarding(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  backgroundColor: Color(0xFF0A0A0F),
                  body: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF10B981))));
            }
            return snapshot.data == true
                ? const HomeScreen()
                : const OnboardingScreen();
          },
        ),
      ),
    );
  }
}
