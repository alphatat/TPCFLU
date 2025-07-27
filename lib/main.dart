import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const WindowOptions windowOptions = WindowOptions(
      size: Size(400, 400),
      center: true,
      alwaysOnTop: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAsFrameless();
      await windowManager.setOpacity(0.8);
      await windowManager.setIgnoreMouseEvents(false);
      await windowManager.show();
    });
  }
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
        scaffoldBackgroundColor: kIsWeb || Platform.isAndroid || Platform.isIOS
            ? Colors.black
            : Colors.transparent,
      ),
      home: const SettingsStartScreen(),
    );
  }
}

class SettingsStartScreen extends StatefulWidget {
  const SettingsStartScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SettingsStartScreenState createState() => _SettingsStartScreenState();
}

class _SettingsStartScreenState extends State<SettingsStartScreen> {
  List<int> sectionMinutes = [18, 12, 18, 12];
  bool isSoundEnabled = true;
  bool isVibrationEnabled = true;
  bool isClickThroughEnabled = false;
  bool isDraggable = true;
  double opacity = 0.8;
  double windowSize = 400.0;
  Color workColor = Colors.red;
  Color restColor = Colors.cyan;
  double audioDuration = 1.0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      sectionMinutes = List.generate(
          4, (i) => prefs.getInt('section_$i') ?? [18, 12, 18, 12][i]);
      isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      isClickThroughEnabled = prefs.getBool('click_through_enabled') ?? false;
      isDraggable = prefs.getBool('draggable_enabled') ?? true;
      opacity = prefs.getDouble('opacity') ?? 0.8;
      windowSize = prefs.getDouble('window_size') ?? 400.0;
      workColor = Color(prefs.getInt('work_color') ?? Colors.red.value);
      restColor = Color(prefs.getInt('rest_color') ?? Colors.cyan.value);
      audioDuration = prefs.getDouble('audio_duration') ?? 1.0;
    });
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.setIgnoreMouseEvents(isClickThroughEnabled);
      await windowManager.setOpacity(opacity);
      await windowManager.setSize(Size(windowSize, windowSize));
      await windowManager.setMovable(isDraggable);
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < 4; i++) {
      await prefs.setInt('section_$i', sectionMinutes[i]);
    }
    await prefs.setBool('sound_enabled', isSoundEnabled);
    await prefs.setBool('vibration_enabled', isVibrationEnabled);
    await prefs.setBool('click_through_enabled', isClickThroughEnabled);
    await prefs.setBool('draggable_enabled', isDraggable);
    await prefs.setDouble('opacity', opacity);
    await prefs.setDouble('window_size', windowSize);
    await prefs.setInt('work_color', workColor.value);
    await prefs.setInt('rest_color', restColor.value);
    await prefs.setDouble('audio_duration', audioDuration);
  }

  void _selectColor(BuildContext context, bool isWorkColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWorkColor ? 'Select Work Color' : 'Select Rest Color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: isWorkColor ? workColor : restColor,
            onColorChanged: (color) {
              setState(() {
                if (isWorkColor) {
                  workColor = color;
                } else {
                  restColor = color;
                }
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _savePreferences();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Timer Sections (minutes)',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            ...List.generate(
                4,
                (index) => TextField(
                      decoration: InputDecoration(
                        labelText: 'Section ${index + 1}',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70)),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        sectionMinutes[index] =
                            int.tryParse(value) ?? sectionMinutes[index];
                      },
                    )),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Sound Enabled',
                  style: TextStyle(color: Colors.white)),
              value: isSoundEnabled,
              onChanged: (value) {
                setState(() {
                  isSoundEnabled = value;
                  _savePreferences();
                });
              },
            ),
            SwitchListTile(
              title: const Text('Vibration/Flash Enabled',
                  style: TextStyle(color: Colors.white)),
              value: isVibrationEnabled,
              onChanged: (value) {
                setState(() {
                  isVibrationEnabled = value;
                  _savePreferences();
                });
              },
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Work Color',
                  style: TextStyle(color: Colors.white)),
              trailing: Container(width: 30, height: 30, color: workColor),
              onTap: () => _selectColor(context, true),
            ),
            ListTile(
              title: const Text('Rest Color',
                  style: TextStyle(color: Colors.white)),
              trailing: Container(width: 30, height: 30, color: restColor),
              onTap: () => _selectColor(context, false),
            ),
            const SizedBox(height: 20),
            const Text('Audio Duration (seconds)',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            Slider(
              value: audioDuration,
              min: 0.5,
              max: 5.0,
              divisions: 9,
              label: audioDuration.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  audioDuration = value;
                  _savePreferences();
                });
              },
            ),
            if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ...[
              const SizedBox(height: 20),
              const Text('Desktop Settings',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              const Text('Window Opacity',
                  style: TextStyle(color: Colors.white)),
              Slider(
                value: opacity,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: opacity.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    opacity = value;
                    windowManager.setOpacity(value);
                    _savePreferences();
                  });
                },
              ),
              const Text('Window Size', style: TextStyle(color: Colors.white)),
              Slider(
                value: windowSize,
                min: 200.0,
                max: 800.0,
                divisions: 12,
                label: windowSize.toStringAsFixed(0),
                onChanged: (value) {
                  setState(() {
                    windowSize = value;
                    windowManager.setSize(Size(value, value));
                    _savePreferences();
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Click-Through',
                    style: TextStyle(color: Colors.white)),
                value: isClickThroughEnabled,
                onChanged: (value) {
                  setState(() {
                    isClickThroughEnabled = value;
                    windowManager.setIgnoreMouseEvents(value);
                    _savePreferences();
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Draggable',
                    style: TextStyle(color: Colors.white)),
                value: isDraggable,
                onChanged: (value) {
                  setState(() {
                    isDraggable = value;
                    windowManager.setMovable(value);
                    _savePreferences();
                  });
                },
              ),
            ],
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
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
                        sections: sectionMinutes.map((m) => m * 60).toList(),
                        isSoundEnabled: isSoundEnabled,
                        isVibrationEnabled: isVibrationEnabled,
                        isClickThroughEnabled: isClickThroughEnabled,
                        workColor: workColor,
                        restColor: restColor,
                        audioDuration: audioDuration,
                      ),
                    ),
                  );
                },
                child:
                    const Icon(Icons.play_arrow, size: 50, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PomodoroScreen extends StatefulWidget {
  final List<int> sections;
  final bool isSoundEnabled;
  final bool isVibrationEnabled;
  final bool isClickThroughEnabled;
  final Color workColor;
  final Color restColor;
  final double audioDuration;

  const PomodoroScreen({
    super.key,
    required this.sections,
    required this.isSoundEnabled,
    required this.isVibrationEnabled,
    required this.isClickThroughEnabled,
    required this.workColor,
    required this.restColor,
    required this.audioDuration,
  });

  @override
  // ignore: library_private_types_in_public_api
  _PomodoroScreenState createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  int currentSection = 0;
  late int timeLeftInSeconds;
  bool isRunning = false;
  bool showBackButton = false;
  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    timeLeftInSeconds = widget.sections.reduce((a, b) => a + b);
    _loadAudio();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.setMovable(widget.isClickThroughEnabled);
    }
  }

  Future<void> _loadAudio() async {
    try {
      await _player.setAsset('assets/sounds/tick.wav');
      await _player.setClip(
          end: Duration(milliseconds: (widget.audioDuration * 1000).toInt()));
    } catch (e) {
      // Log error silently
    }
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
        timeLeftInSeconds = widget.sections.reduce((a, b) => a + b);
        currentSection = 0;
      });
      _startTimer();
    }
  }

  void _checkSectionTransition() {
    int totalTime = widget.sections.reduce((a, b) => a + b);
    int elapsedTime = totalTime - timeLeftInSeconds;
    int accumulatedTime = 0;
    int newSection = 0;
    for (int i = 0; i < widget.sections.length; i++) {
      accumulatedTime += widget.sections[i];
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
    List<int> sectionMinutes = widget.sections.map((s) => s ~/ 60).toList();
    bool localClickThrough = widget.isClickThroughEnabled;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timer Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(
                4,
                (index) => TextField(
                      decoration: InputDecoration(
                          labelText: 'Section ${index + 1} (minutes)'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        sectionMinutes[index] =
                            int.tryParse(value) ?? sectionMinutes[index];
                      },
                    )),
            if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
              CheckboxListTile(
                title: const Text('Click-Through'),
                value: localClickThrough,
                onChanged: (value) {
                  setState(() {
                    localClickThrough = value ?? false;
                  });
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.sections.clear();
                widget.sections.addAll(sectionMinutes.map((m) => m * 60));
                timeLeftInSeconds = widget.sections.reduce((a, b) => a + b);
                currentSection = 0;
              });
              if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                windowManager.setIgnoreMouseEvents(localClickThrough);
              }
              Navigator.pop(context);
              SharedPreferences.getInstance().then((prefs) {
                prefs.setBool('click_through_enabled', localClickThrough);
                for (int i = 0; i < 4; i++) {
                  prefs.setInt('section_$i', sectionMinutes[i]);
                }
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _resetAndGoBack() {
    setState(() {
      isRunning = false;
      timeLeftInSeconds = widget.sections.reduce((a, b) => a + b);
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
                  totalTimeInSeconds: widget.sections.reduce((a, b) => a + b),
                  sections: widget.sections,
                  currentSection: currentSection,
                  flashOpacity: _flashController.value,
                  workColor: widget.workColor,
                  restColor: widget.restColor,
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
  final Color workColor;
  final Color restColor;

  CircleTimerPainter({
    required this.timeLeftInSeconds,
    required this.totalTimeInSeconds,
    required this.sections,
    required this.currentSection,
    required this.flashOpacity,
    required this.workColor,
    required this.restColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final oval = Rect.fromCircle(center: center, radius: radius);

    if (flashOpacity > 0) {
      final flashPaint = Paint()
        // ignore: deprecated_member_use
        ..color = Colors.white.withOpacity(flashOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius + 12, flashPaint);
    }

    double startAngle = 270;
    double elapsedAngle = 360 * (1 - timeLeftInSeconds / totalTimeInSeconds);
    bool isActive = true;

    for (int i = 0; i < sections.length; i++) {
      final sweepAngle = 360 * sections[i] / totalTimeInSeconds;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = i % 2 == 0
            // ignore: deprecated_member_use
            ? (isActive ? workColor : workColor.withOpacity(0.3))
            // ignore: deprecated_member_use
            : (isActive ? restColor : restColor.withOpacity(0.3));

      if (isActive) {
        canvas.drawArc(oval, startAngle * math.pi / 180,
            sweepAngle * math.pi / 180, true, paint);
        if (elapsedAngle > 0) {
          final progressAngle = math.min(elapsedAngle, sweepAngle);
          final progressPaint = Paint()
            ..style = PaintingStyle.fill
            // ignore: deprecated_member_use
            ..color = i % 2 == 0
                ? workColor.withOpacity(0.5)
                : restColor.withOpacity(0.5);
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

    const dotRadius = 12.0;
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
