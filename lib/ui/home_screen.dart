import 'package:flutter/material.dart';
import '../logic/timer_logic.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final timer = TimerLogic(totalSeconds: 600); // 10 minutes

  @override
  void initState() {
    super.initState();
    timer.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = timer.formattedTime;
    return Scaffold(
      appBar: AppBar(title: const Text("10 Minute Timer")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(timeStr, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: timer.isRunning ? timer.pause : timer.start,
                  child: Text(timer.isRunning ? 'Pause' : 'Start'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: timer.reset,
                  child: const Text('Reset'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
