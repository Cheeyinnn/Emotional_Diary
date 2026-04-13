import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // 🔥 Added
import 'firebase_options.dart'; // 🔥 Added
import 'providers/diary_provider.dart';
import 'screens/welcome_screen.dart';

// Change main to 'async' so we can wait for Firebase to start
void main() async { 
  // 1. Essential: Initialize Flutter's engine bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Start Firebase using your generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => DiaryProvider(),
      child: const EmotionDiaryApp(),
    ),
  );
}

class EmotionDiaryApp extends StatelessWidget {
  const EmotionDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COOKIE LAB',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D9E75)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
          iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}