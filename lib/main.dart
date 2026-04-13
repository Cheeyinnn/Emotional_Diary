import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/diary_provider.dart';
import 'screens/welcome_screen.dart'; // 确保路径正确

void main() async {
  // 1. 确保 Flutter 引擎完全启动
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 初始化 Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// 🔥 就是缺少下面这部分代码，它是你 App 的根组件
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COOKIE LAB',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D9E75)),
        useMaterial3: true,
      ),
      // 默认启动页面
      home: const WelcomeScreen(),
    );
  }
}