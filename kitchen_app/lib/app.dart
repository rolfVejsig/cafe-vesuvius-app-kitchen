import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

class KitchenApp extends StatelessWidget {
  const KitchenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Køkken Skærm',
      theme: AppTheme.darkTheme,
      home: const LoginScreen(), // Brug home i stedet for initialRoute
      debugShowCheckedModeBanner: false,
    );
  }
}