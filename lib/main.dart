import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

void main() {
  runApp(const TPCFLUApp());
}

class TPCFLUApp extends StatelessWidget {
  const TPCFLUApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TPCFLU - Universal Pomodoro Timer',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(50),
            backgroundColor: Colors.red,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TimerScreen()),
            );
          },
          child: const Icon(
            Icons.play_arrow,
            size: 60,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TimerScreenState extends State<TimerScreen> {
  late Timer _timer;
  int _totalSeconds = 25 * 60; // Start with 25 minutes
  int _currentSeconds = 0;
  bool _isWorkPeriod = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSound();
    _startTimer();
  }

  Future<void> _loadSound() async {
    try {
      await _audioPlayer.setAsset('assets/sounds/tick.wav'); // Changed to WAV
      setState(() {
        _isSoundLoaded = true;
      });
    } catch (e) {
      print('Error loading sound: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentSeconds++;
        if (_currentSeconds >= _totalSeconds) {
          _currentSeconds = 0;
          _isWorkPeriod = !_isWorkPeriod;
          _totalSeconds = _isWorkPeriod ? 25 * 60 : 5 * 60;
          if (_isSoundLoaded) {
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.play();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = _currentSeconds / _totalSeconds;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 20,
                backgroundColor: _isWorkPeriod
                    ? Colors.red.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                    _isWorkPeriod ? Colors.red : Colors.green),
              ),
            ),
            Text(
              _isWorkPeriod ? 'Work' : 'Break',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
