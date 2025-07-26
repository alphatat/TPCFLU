import 'package:flutter/material.dart';
import 'ui/home_screen.dart';
import 'theme.dart';

void main() {
  runApp(const TPCApp());
}

class TPCApp extends StatelessWidget {
  const TPCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TPCFLU',
      theme: appTheme,
      home: const HomeScreen(),
    );
  }
}
