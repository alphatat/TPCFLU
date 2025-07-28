import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart'; // Keep this for desktop audio backend
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart' as window_manager;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

class PomodoroSettings with ChangeNotifier {
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

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    sectionMinutes = List.generate(
      4,
      (i) => prefs.getInt('section_$i') ?? [18, 12, 18, 12][i],
    );
    isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
    isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    isClickThroughEnabled = prefs.getBool('click_through_enabled') ?? false;
    isDraggable = prefs.getBool('draggable_enabled') ?? true;
    opacity = prefs.getDouble('opacity') ?? 0.8;
    windowSize = prefs.getDouble('window_size') ?? 400.0;
    workColor = Color(prefs.getInt('work_color') ?? Colors.red.value);
    restColor = Color(prefs.getInt('rest_color') ?? Colors.cyan.value);
    audioDuration = prefs.getDouble('audio_duration') ?? 1.0;
    notifyListeners();
  }

  Future<void> savePreferences() async {
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
    notifyListeners();
  }

  void updateSectionMinutes(int index, int value) {
    sectionMinutes[index] = value;
    notifyListeners();
  }

  void updateSoundEnabled(bool value) {
    isSoundEnabled = value;
    notifyListeners();
  }

  void updateVibrationEnabled(bool value) {
    isVibrationEnabled = value;
    notifyListeners();
  }

  void updateClickThrough(bool value) {
    isClickThroughEnabled = value;
    notifyListeners();
  }

  void updateDraggable(bool value) {
    isDraggable = value;
    notifyListeners();
  }

  void updateOpacity(double value) {
    opacity = value;
    notifyListeners();
  }

  void updateWindowSize(double value) {
    windowSize = value;
    notifyListeners();
  }

  void updateWorkColor(Color color) {
    workColor = color;
    notifyListeners();
  }

  void updateRestColor(Color color) {
    restColor = color;
    notifyListeners();
  }

  void updateAudioDuration(double value) {
    audioDuration = value;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Always ensure initialized first

  // Initialize JustAudioMediaKit backend for desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    JustAudioMediaKit.ensureInitialized(); // No need for windows: true or linux: true, it handles it
  }

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      await window_manager.WindowManager.instance.ensureInitialized();
      const window_manager.WindowOptions windowOptions =
          window_manager.WindowOptions(
            size: Size(400, 400),
            center: true,
            alwaysOnTop: true,
            backgroundColor: Colors.transparent,
            skipTaskbar: false,
          );
      await window_manager.WindowManager.instance.waitUntilReadyToShow(
        windowOptions,
        () async {
          await window_manager.WindowManager.instance.setAsFrameless();
          await window_manager.WindowManager.instance.show();
        },
      );
    } catch (e) {
      debugPrint('WindowManager initialization failed: $e');
    }
  }
  final settings = PomodoroSettings();
  await settings.loadPreferences();
  runApp(
    ChangeNotifierProvider(create: (_) => settings, child: const PomodoroApp()),
  );
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
            : Colors.white,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white, fontSize: 18),
          labelMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const SettingsStartScreen(),
    );
  }
}

class SettingsStartScreen extends StatelessWidget {
  const SettingsStartScreen({super.key});

  void _selectColor(
    BuildContext context,
    bool isWorkColor,
    PomodoroSettings settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWorkColor ? 'Select Work Color' : 'Select Rest Color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: isWorkColor ? settings.workColor : settings.restColor,
            onColorChanged: (color) {
              if (isWorkColor) {
                settings.updateWorkColor(color);
              } else {
                settings.updateRestColor(color);
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              settings.savePreferences();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<PomodoroSettings>(context);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Timer Sections (minutes)'),
            ...List.generate(
              4,
              (index) => TextField(
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: settings.sectionMinutes[index].toString(),
                ),
                onChanged: (value) {
                  final intValue =
                      int.tryParse(value) ?? settings.sectionMinutes[index];
                  settings.updateSectionMinutes(index, intValue);
                },
                onSubmitted: (_) => settings.savePreferences(),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Sound Enabled'),
              value: settings.isSoundEnabled,
              onChanged: (value) {
                settings.updateSoundEnabled(value);
                settings.savePreferences();
              },
            ),
            SwitchListTile(
              title: const Text('Vibration/Flash Enabled'),
              value: settings.isVibrationEnabled,
              onChanged: (value) {
                settings.updateVibrationEnabled(value);
                settings.savePreferences();
              },
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Work Color'),
              trailing: Container(
                width: 30,
                height: 30,
                color: settings.workColor,
              ),
              onTap: () => _selectColor(context, true, settings),
            ),
            ListTile(
              title: const Text('Rest Color'),
              trailing: Container(
                width: 30,
                height: 30,
                color: settings.restColor,
              ),
              onTap: () => _selectColor(context, false, settings),
            ),
            const SizedBox(height: 20),
            const Text('Audio Duration (seconds)'),
            Slider(
              value: settings.audioDuration,
              min: 0.5,
              max: 10.0,
              divisions: 19,
              label: settings.audioDuration.toStringAsFixed(1),
              onChanged: (value) {
                settings.updateAudioDuration(value);
              },
              onChangeEnd: (_) => settings.savePreferences(),
            ),
            if (!kIsWeb &&
                (Platform.isWindows ||
                    Platform.isLinux ||
                    Platform.isMacOS)) ...[
              const SizedBox(height: 20),
              const Text('Desktop Settings'),
              const Text('Window Opacity'),
              Slider(
                value: settings.opacity,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: settings.opacity.toStringAsFixed(1),
                onChanged: (value) {
                  settings.updateOpacity(value);
                },
                onChangeEnd: (_) => settings.savePreferences(),
              ),
              const Text('Window Size'),
              Slider(
                value: settings.windowSize,
                min: 200.0,
                max: 800.0,
                divisions: 12,
                label: settings.windowSize.toStringAsFixed(0),
                onChanged: (value) {
                  settings.updateWindowSize(value);
                },
                onChangeEnd: (_) => settings.savePreferences(),
              ),
              SwitchListTile(
                title: const Text('Click-Through'),
                value: settings.isClickThroughEnabled,
                onChanged: (value) {
                  settings.updateClickThrough(value);
                  settings.savePreferences();
                },
              ),
              SwitchListTile(
                title: const Text('Draggable'),
                value: settings.isDraggable,
                onChanged: (value) {
                  settings.updateDraggable(value);
                  settings.savePreferences();
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
                      builder: (context) => PomodoroScreen(settings: settings),
                    ),
                  );
                },
                child: const Icon(
                  Icons.play_arrow,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PomodoroScreen extends StatefulWidget {
  final PomodoroSettings settings;

  const PomodoroScreen({super.key, required this.settings});

  @override
  _PomodoroScreenState createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  int currentSection = 0;
  late int timeLeftInSeconds;
  bool isRunning = false; // This now just indicates if the timer is *active* after initial start
  late AnimationController _flashController;
  Timer? _timer;

  // NEW: Variables for central back button visibility
  Timer? _centralButtonVisibilityTimer;
  bool _isCentralButtonVisible = false;

  @override
  void initState() {
    super.initState();
    timeLeftInSeconds =
        widget.settings.sectionMinutes.reduce((a, b) => a + b) * 60;
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _loadAudio();
    _applyDesktopSettings();

    // Start the timer automatically when entering the screen
    _startTimer();
  }

  Future<void> _loadAudio() async {
    try {
      await _player.setAsset('assets/sounds/tick.wav');
      await _player.setClip(
        end: Duration(
          milliseconds: (widget.settings.audioDuration * 1000).toInt(),
        ),
      );
      await _player.load(); // Preload to reduce latency
    } catch (e) {
      debugPrint('Audio load error: $e');
    }
  }

  void _applyDesktopSettings() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        await window_manager.WindowManager.instance.setOpacity(
          widget.settings.opacity,
        );
        await window_manager.WindowManager.instance.setSize(
          Size(widget.settings.windowSize, widget.settings.windowSize),
        );
        await window_manager.WindowManager.instance.setMovable(
          widget.settings.isDraggable,
        );
        await window_manager.WindowManager.instance.setIgnoreMouseEvents(
          widget.settings.isClickThroughEnabled,
        );
      } catch (e) {
        debugPrint('Desktop settings error: $e');
      }
    }
  }

  // Modified: Timer now starts and continues until back is pressed
  void _startTimer() {
    // Only start if not already running (first entry into screen or after reset cycle)
    if (!isRunning) {
      setState(() {
        isRunning = true;
      });
      // Play initial transition effect if starting fresh
      if (currentSection == 0 && timeLeftInSeconds == widget.settings.sectionMinutes.reduce((a, b) => a + b) * 60) {
         _playTransitionEffects(currentSection % 2 == 0);
      }
      if (Platform.isAndroid || Platform.isIOS) {
        WakelockPlus.enable();
      }
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    if (!isRunning) return; // This check makes sure the timer pauses if isRunning becomes false (e.g., from _resetAndGoBack)
    setState(() {
      timeLeftInSeconds--;
      _checkSectionTransition();
    });
    if (timeLeftInSeconds <= 0) {
      _playTransitionEffects(true);
      setState(() {
        timeLeftInSeconds =
            widget.settings.sectionMinutes.reduce((a, b) => a + b) * 60;
        currentSection = 0;
        // isRunning remains true to keep the cycle going
      });
      // The timer itself does not cancel and restart, it just continues to tick
      // The logic above ensures timeLeftInSeconds resets and the cycle repeats.
    }
  }

  void _checkSectionTransition() {
    final totalTime =
        widget.settings.sectionMinutes.reduce((a, b) => a + b) * 60;
    final elapsedTime = totalTime - timeLeftInSeconds;
    int accumulatedTime = 0;
    int newSection = 0;
    for (int i = 0; i < widget.settings.sectionMinutes.length; i++) {
      accumulatedTime += widget.settings.sectionMinutes[i] * 60;
      if (elapsedTime < accumulatedTime) {
        newSection = i;
        break;
      }
    }
    if (elapsedTime >= totalTime) {
      newSection = widget.settings.sectionMinutes.length - 1;
    }
    if (newSection != currentSection) {
      setState(() {
        currentSection = newSection;
      });
      if (currentSection != 0 || elapsedTime > 0) {
        _playTransitionEffects(currentSection % 2 == 0);
      }
    }
  }

  void _playTransitionEffects(bool isWork) {
    if (widget.settings.isSoundEnabled) {
      _player.seek(Duration.zero);
      _player.play().catchError((e) {
        debugPrint('Audio play error: $e');
      });
    }
    if (widget.settings.isVibrationEnabled) {
      _flashController.forward().then((_) => _flashController.reverse());
    }
  }

  // Removed _showSettingsDialog functionality tied to main clock tap.
  // The functionality of _showSettingsDialog is for the settings page.

  // NEW: Method to show the central back button and start its hide timer
  void _showCentralBackButton() {
    _centralButtonVisibilityTimer?.cancel(); // Cancel any existing timer
    if (!_isCentralButtonVisible) {
      setState(() {
        _isCentralButtonVisible = true; // Show the button
      });
    }
    _centralButtonVisibilityTimer = Timer(const Duration(seconds: 3), () { // Hide after 3 seconds
      if (mounted) {
        setState(() {
          _isCentralButtonVisible = false; // Hide the button
        });
      }
    });
  }

  void _resetAndGoBack() {
    _timer?.cancel(); // Stop the timer when going back
    setState(() {
      isRunning = false; // Set isRunning to false to stop the timer.
      timeLeftInSeconds =
          widget.settings.sectionMinutes.reduce((a, b) => a + b) * 60;
      currentSection = 0;
    });
    if (Platform.isAndroid || Platform.isIOS) {
      WakelockPlus.disable();
    }
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        window_manager.WindowManager.instance.setIgnoreMouseEvents(false);
        window_manager.WindowManager.instance.setMovable(true);
        window_manager.WindowManager.instance.setOpacity(1.0);
        window_manager.WindowManager.instance.setSize(const Size(400, 400));
      } catch (e) {
        debugPrint('Reset desktop settings error: $e');
      }
    }
    Navigator.pop(context); // Go back to the previous screen (settings)
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    _flashController.dispose();
    _centralButtonVisibilityTimer?.cancel(); // Dispose visibility timer
    if (Platform.isAndroid || Platform.isIOS) {
      WakelockPlus.disable();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder( // Use LayoutBuilder to get the size for central tap detection
        builder: (context, constraints) {
          final centerX = constraints.maxWidth / 2;
          final centerY = constraints.maxHeight / 2;
          final clockRadius = math.min(constraints.maxWidth, constraints.maxHeight) / 2 - 12; // Re-use clock radius calc
          final centralTapRadius = clockRadius * 0.10; // 10% of clock radius

          return GestureDetector(
            // Tap anywhere to show the new central back button on desktop (via MouseRegion onHover)
            // On mobile, tapping anywhere will also trigger _showCentralBackButton
            // The main tap area is now for showing the central button, not for settings dialog.
            onTapDown: (details) { // Use onTapDown to get precise tap position
              final tapPosition = details.localPosition;
              final distance = math.sqrt(
                math.pow(tapPosition.dx - centerX, 2) +
                math.pow(tapPosition.dy - centerY, 2),
              );

              if (distance <= centralTapRadius) {
                _showCentralBackButton();
              }
              // If outside the central region, nothing happens on tap
            },
            behavior: HitTestBehavior.translucent, // Ensures taps are detected across the whole screen
            child: MouseRegion( // For desktop mouse movement
              onHover: (event) {
                // Not using onHover to show the central button anymore,
                // only onTapDown in the central region will show it.
                // This MouseRegion is now primarily for the old back button opacity behavior
                // (which is being removed). Will simplify this later.
              },
              child: Stack(
                children: [
                  // Original CustomPaint for the clock
                  Center(
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight), // Make clock fill available space
                      painter: CircleTimerPainter(
                        timeLeftInSeconds: timeLeftInSeconds,
                        totalTimeInSeconds:
                            widget.settings.sectionMinutes.reduce((a, b) => a + b) * 60,
                        sections: widget.settings.sectionMinutes,
                        currentSection: currentSection,
                        flashOpacity: _flashController.value,
                        workColor: widget.settings.workColor,
                        restColor: widget.settings.restColor,
                      ),
                    ),
                  ),

                  // NEW: Central Back Button
                  Center(
                    child: AnimatedOpacity(
                      opacity: _isCentralButtonVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer( // Always ignore when not visible, always active when visible
                        ignoring: !_isCentralButtonVisible,
                        child: FloatingActionButton(
                          onPressed: _resetAndGoBack, // Go back to settings page
                          backgroundColor: Colors.blueGrey, // A distinct color for this button
                          heroTag: 'centralBackButton', // Required if you have multiple FABs
                          child: const Icon(Icons.settings_backup_restore, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
        ..color = Colors.white.withOpacity(flashOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius + 12, flashPaint);
    }

    double currentDrawAngle = 270;
    int cumulativeSecondsPassed = 0;

    for (int i = 0; i < sections.length; i++) {
      final sectionDurationSeconds = sections[i] * 60;
      final sectionSweepDegrees =
          (sectionDurationSeconds / totalTimeInSeconds) * 360;
      final solidColor = i % 2 == 0 ? workColor : restColor;
      final lightColor = i % 2 == 0
          ? workColor.withOpacity(0.3)
          : restColor.withOpacity(0.3);
      final secondsElapsedSoFar = totalTimeInSeconds - timeLeftInSeconds;

      if (secondsElapsedSoFar >=
          cumulativeSecondsPassed + sectionDurationSeconds) {
        final paintLight = Paint()
          ..style = PaintingStyle.fill
          ..color = lightColor;
        canvas.drawArc(
          oval,
          currentDrawAngle * math.pi / 180,
          sectionSweepDegrees * math.pi / 180,
          true,
          paintLight,
        );
      } else if (secondsElapsedSoFar >= cumulativeSecondsPassed) {
        final elapsedInCurrentSection =
            secondsElapsedSoFar - cumulativeSecondsPassed;
        final elapsedPartSweepDegrees =
            (elapsedInCurrentSection / sectionDurationSeconds) *
            sectionSweepDegrees;
        if (elapsedPartSweepDegrees > 0) {
          final paintLight = Paint()
            ..style = PaintingStyle.fill
            ..color = lightColor;
          canvas.drawArc(
            oval,
            currentDrawAngle * math.pi / 180,
            elapsedPartSweepDegrees * math.pi / 180,
            true,
            paintLight,
          );
        }
        final remainingPartSweepDegrees =
            sectionSweepDegrees - elapsedPartSweepDegrees;
        if (remainingPartSweepDegrees > 0) {
          final paintSolid = Paint()
            ..style = PaintingStyle.fill
            ..color = solidColor;
          canvas.drawArc(
            oval,
            (currentDrawAngle + elapsedPartSweepDegrees) * math.pi / 180,
            remainingPartSweepDegrees * math.pi / 180,
            true,
            paintSolid,
          );
        }
      } else {
        final paintSolid = Paint()
          ..style = PaintingStyle.fill
          ..color = solidColor;
        canvas.drawArc(
          oval,
          currentDrawAngle * math.pi / 180,
          sectionSweepDegrees * math.pi / 180,
          true,
          paintSolid,
        );
      }

      currentDrawAngle += sectionSweepDegrees;
      cumulativeSecondsPassed += sectionDurationSeconds;
    }

    final elapsedAngleDegrees =
        360 * (1 - timeLeftInSeconds / totalTimeInSeconds);
    final zeigerAngle = (elapsedAngleDegrees + 270) * math.pi / 180;
    final zeigerX = center.dx + radius * math.cos(zeigerAngle);
    final zeigerY = center.dy + radius * math.sin(zeigerAngle);
    final zeigerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(center, Offset(zeigerX, zeigerY), zeigerPaint);

    const dotRadius = 3.0;
    final extendedZeigerX =
        center.dx + (radius + dotRadius / 2) * math.cos(zeigerAngle);
    final extendedZeigerY =
        center.dy + (radius + dotRadius / 2) * math.sin(zeigerAngle);
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(extendedZeigerX, extendedZeigerY),
      dotRadius,
      dotPaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text:
            '${(timeLeftInSeconds ~/ 60).toString().padLeft(2, '0')}:${(timeLeftInSeconds % 60).toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(CircleTimerPainter oldDelegate) {
    return timeLeftInSeconds != oldDelegate.timeLeftInSeconds ||
        currentSection != oldDelegate.currentSection ||
        flashOpacity != oldDelegate.flashOpacity ||
        workColor != oldDelegate.workColor ||
        restColor != oldDelegate.restColor ||
        sections != oldDelegate.sections ||
        totalTimeInSeconds != oldDelegate.totalTimeInSeconds;
  }
}
