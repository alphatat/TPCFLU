import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/timer/timer_page.dart';

void main() {
  runApp(ProviderScope(child: TPCApp()));
}

class TPCApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TPCFLU',
      theme: ThemeData.dark(),
      home: TimerPage(),
    );
  }
}
