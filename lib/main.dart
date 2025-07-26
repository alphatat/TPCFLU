import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TPCFLU',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PomodoroScreen(),
    );
  }
}

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  _PomodoroScreenState createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  final AudioPlayer _player = AudioPlayer();
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  bool _isWorkPhase = true;

  @override
  void initState() {
    super.initState();
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    await _player.setAsset('assets/sounds/tick.wav');
  }

  void _startTimer() {
    if (!_isRunning) {
      setState(() {
        _isRunning = true;
      });
      _player.play();
      Future.delayed(const Duration(seconds: 1), _tick);
    }
  }

  void _tick() {
    if (_isRunning && _secondsRemaining > 0) {
      setState(() {
        _secondsRemaining--;
      });
      Future.delayed(const Duration(seconds: 1), _tick);
    } else if (_secondsRemaining == 0) {
      setState(() {
        _isRunning = false;
        _isWorkPhase = !_isWorkPhase;
        _secondsRemaining = _isWorkPhase ? 25 * 60 : 5 * 60;
      });
      _player.play();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TPCFLU Pomodoro')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_secondsRemaining ~/ 60}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 48),
            ),
            Text(_isWorkPhase ? 'Work' : 'Break'),
            ElevatedButton(
              onPressed: _startTimer,
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}
