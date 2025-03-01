import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:petverseapp/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetVerse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF6B4EFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4EFF),
          secondary: const Color(0xFFFF4E8E),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
