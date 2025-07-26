import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(400, 400),
    center: true,
    alwaysOnTop: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setOpacity(0.8);
    await windowManager.setIgnoreMouseEvents(true);
    await windowManager.show();
  });
  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TPCFLU',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const StartScreen(),
    );
  }
}

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool isSoundEnabled = true;
  bool isVibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', isSoundEnabled);
    await prefs.setBool('vibration_enabled', isVibrationEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PomodoroScreen(
                      isSoundEnabled: isSoundEnabled,
                      isVibrationEnabled: isVibrationEnabled,
                    ),
                  ),
                );
              },
              child:
                  const Icon(Icons.play_arrow, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      isSoundEnabled = !isSoundEnabled;
                      _savePreferences();
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    isVibrationEnabled
                        ? Icons.vibration
                        : Icons.vibration_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      isVibrationEnabled = !isVibrationEnabled;
                      _savePreferences();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PomodoroScreen extends StatefulWidget {
  final bool isSoundEnabled;
  final bool isVibrationEnabled;

  const PomodoroScreen({
    super.key,
    required this.isSoundEnabled,
    required this.isVibrationEnabled,
  });

  @override
  _PomodoroScreenState createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  List<int> sections = [
    18 * 60,
    12 * 60,
    18 * 60,
    12 * 60
  ]; // 18/12/18/12 minutes
  int currentSection = 0;
  int timeLeftInSeconds = 60 * 60; // 1 hour
  bool isRunning = false;
  bool showBackButton = false;
  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _loadAudio();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  Future<void> _loadAudio() async {
    await _player.setAsset(
        'assets/sounds/tick.wav'); // Replace with kanlgschalde.wav if available
  }

  void _startTimer() {
    if (!isRunning) {
      setState(() {
        isRunning = true;
      });
      _playTransitionEffects(currentSection % 2 == 0);
      _tick();
    }
  }

  void _tick() {
    if (!isRunning) return;
    setState(() {
      timeLeftInSeconds--;
      _checkSectionTransition();
    });
    if (timeLeftInSeconds > 0) {
      Future.delayed(const Duration(seconds: 1), _tick);
    } else {
      _playTransitionEffects(true);
      setState(() {
        timeLeftInSeconds = 60 * 60;
        currentSection = 0;
      });
      _startTimer();
    }
  }

  void _checkSectionTransition() {
    int totalTime = 60 * 60;
    int elapsedTime = totalTime - timeLeftInSeconds;
    int accumulatedTime = 0;
    int newSection = 0;
    for (int i = 0; i < sections.length; i++) {
      accumulatedTime += sections[i];
      if (elapsedTime < accumulatedTime) {
        newSection = i;
        break;
      }
    }
    if (newSection != currentSection) {
      setState(() {
        currentSection = newSection;
      });
      _playTransitionEffects(currentSection % 2 == 0);
    }
  }

  void _playTransitionEffects(bool isLongBreak) {
    if (widget.isSoundEnabled) {
      _player.seek(Duration.zero);
      _player.play();
    }
    if (widget.isVibrationEnabled) {
      _flashController.forward().then((_) => _flashController.reverse());
    }
  }

  void _showSettingsDialog() {
    List<int> sectionMinutes = sections.map((s) => s ~/ 60).toList();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Section Durations (minutes)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
              4,
              (index) => TextField(
                    decoration:
                        InputDecoration(labelText: 'Section ${index + 1}'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      sectionMinutes[index] =
                          int.tryParse(value) ?? sectionMinutes[index];
                    },
                  )),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                sections = sectionMinutes.map((m) => m * 60).toList();
                timeLeftInSeconds = sections.reduce((a, b) => a + b);
                currentSection = 0;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBackButton() {
    setState(() {
      showBackButton = true;
    });
    Future.delayed(const Duration(milliseconds: 1727), () {
      setState(() {
        showBackButton = false;
      });
    });
  }

  void _resetAndGoBack() {
    setState(() {
      isRunning = false;
      timeLeftInSeconds = sections.reduce((a, b) => a + b);
      currentSection = 0;
    });
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _player.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onTap: _showSettingsDialog,
            child: Center(
              child: CustomPaint(
                size: const Size(300, 300),
                painter: CircleTimerPainter(
                  timeLeftInSeconds: timeLeftInSeconds,
                  totalTimeInSeconds: sections.reduce((a, b) => a + b),
                  sections: sections,
                  currentSection: currentSection,
                  flashOpacity: _flashController.value,
                ),
              ),
            ),
          ),
          if (showBackButton)
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _resetAndGoBack,
              ),
            ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _startTimer,
              backgroundColor: Colors.red,
              child: const Icon(Icons.play_arrow, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class CircleTimerPainter extends CustomPainter {
  final int timeLeftInSeconds;
  final int totalTimeInSeconds;
  final List<int> sections;
  final int currentSection;
  final double flashOpacity;

  CircleTimerPainter({
    required this.timeLeftInSeconds,
    required this.totalTimeInSeconds,
    required this.sections,
    required this.currentSection,
    required this.flashOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final oval = Rect.fromCircle(center: center, radius: radius);

    // Flash effect for "vibration"
    if (flashOpacity > 0) {
      final flashPaint = Paint()
        ..color = Colors.white.withOpacity(flashOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius + 12, flashPaint);
    }

    double startAngle = 270; // 12 o'clock
    double elapsedAngle = 360 * (1 - timeLeftInSeconds / totalTimeInSeconds);
    bool isActive = true;

    for (int i = 0; i < sections.length; i++) {
      final sweepAngle = 360 * sections[i] / totalTimeInSeconds;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = i % 2 == 0
            ? (isActive ? Colors.red : Colors.red.withOpacity(0.3))
            : (isActive ? Colors.cyan : Colors.cyan.withOpacity(0.3));

      if (isActive) {
        canvas.drawArc(oval, startAngle * math.pi / 180,
            sweepAngle * math.pi / 180, true, paint);
        if (elapsedAngle > 0) {
          final progressAngle = math.min(elapsedAngle, sweepAngle);
          final progressPaint = Paint()
            ..style = PaintingStyle.fill
            ..color = i % 2 == 0
                ? Colors.red.withOpacity(0.5)
                : Colors.cyan.withOpacity(0.5);
          canvas.drawArc(oval, startAngle * math.pi / 180,
              progressAngle * math.pi / 180, true, progressPaint);
          elapsedAngle -= progressAngle;
          if (elapsedAngle <= 0) isActive = false;
        }
      } else {
        canvas.drawArc(oval, startAngle * math.pi / 180,
            sweepAngle * math.pi / 180, true, paint);
      }
      startAngle += sweepAngle;
    }

    // Draw clock hand (zeiger)
    final zeigerAngle =
        (360 * (1 - timeLeftInSeconds / totalTimeInSeconds) + 270) *
            math.pi /
            180;
    final zeigerX = center.dx + radius * math.cos(zeigerAngle);
    final zeigerY = center.dy + radius * math.sin(zeigerAngle);
    final zeigerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawLine(center, Offset(zeigerX, zeigerY), zeigerPaint);

    // Draw dot at end of hand
    final dotRadius = 12.0;
    final extendedZeigerX =
        center.dx + (radius + dotRadius / 2) * math.cos(zeigerAngle);
    final extendedZeigerY =
        center.dy + (radius + dotRadius / 2) * math.sin(zeigerAngle);
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(extendedZeigerX, extendedZeigerY), dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(CircleTimerPainter oldDelegate) => true;
}
