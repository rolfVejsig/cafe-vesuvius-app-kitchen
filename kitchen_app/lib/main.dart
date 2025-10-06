import 'package:flutter/material.dart';
import 'package:kitchen_app/screens/login_screen.dart';
import 'package:kitchen_app/theme/app_theme.dart';

void main() {
  runApp(const KitchenApp());
}

class KitchenApp extends StatelessWidget {
  const KitchenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vesuvius Kitchen App',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}