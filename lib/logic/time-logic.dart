import 'dart:async';
import 'package:flutter/foundation.dart';

class TimerLogic extends ChangeNotifier {
  int totalSeconds;
  late int _secondsLeft;
  Timer? _timer;
  bool isRunning = false;

  TimerLogic({required this.totalSeconds}) {
    _secondsLeft = totalSeconds;
  }

  String get formattedTime {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void start() {
    if (isRunning) return;
    isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        _secondsLeft--;
        notifyListeners();
      } else {
        pause();
      }
    });
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    isRunning = false;
    notifyListeners();
  }

  void reset() {
    pause();
    _secondsLeft = totalSeconds;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
