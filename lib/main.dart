import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screen/admin_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Car Wash Admin',
      theme: AppTheme.light(),
      home: AdminHomeScreen(),
    );
  }
}
