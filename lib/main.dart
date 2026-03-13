import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
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
  double opacity = 0.8;
  double windowSize = 400.0;
  Color workColor = Colors.red;
  Color restColor = Colors.cyan;
  double audioDuration = 1.0;
  bool isClickThroughEnabled = false; // Kept, but its behavior is modified
  int windowX = 0; // New: X-coordinate (0-100) - NOTE: Not fully functional without getPrimaryDisplay()
  int windowY = 100; // New: Y-coordinate (0-100, 100 is top) - NOTE: Not fully functional without getPrimaryDisplay()

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    sectionMinutes = List.generate(
      4,
      (i) => prefs.getInt('section_$i') ?? [18, 12, 18, 12][i],
    );
    isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
    isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    isClickThroughEnabled = prefs.getBool('click_through_enabled') ?? false;
    opacity = prefs.getDouble('opacity') ?? 0.8;
    windowSize = prefs.getDouble('window_size') ?? 400.0;
    workColor = Color(prefs.getInt('work_color') ?? Colors.red.value);
    restColor = Color(prefs.getInt('rest_color') ?? Colors.cyan.value);
    audioDuration = prefs.getDouble('audio_duration') ?? 1.0;
    windowX = prefs.getInt('window_x') ?? 0; // Load new preference
    windowY = prefs.getInt('window_y') ?? 100; // Load new preference (default top)
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
    await prefs.setDouble('opacity', opacity);
    await prefs.setDouble('window_size', windowSize);
    await prefs.setInt('work_color', workColor.value);
    await prefs.setInt('rest_color', restColor.value);
    await prefs.setDouble('audio_duration', audioDuration);
    await prefs.setInt('window_x', windowX); // Save new preference
    await prefs.setInt('window_y', windowY); // Save new preference
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

  void updateWindowX(int value) {
    windowX = value.clamp(0, 100); // Clamp value between 0 and 100
    notifyListeners();
  }

  void updateWindowY(int value) {
    windowY = value.clamp(0, 100); // Clamp value between 0 and 100
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Always ensure initialized first

  // Initialize JustAudioMediaKit backend for desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    JustAudioMediaKit.ensureInitialized();
  }

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      await window_manager.WindowManager.instance.ensureInitialized();
      // Initial window options
      const window_manager.WindowOptions windowOptions =
          window_manager.WindowOptions(
            size: Size(400, 400),
            center: true, // Initially center
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
        brightness: Brightness.dark, // Set brightness to dark for better defaults
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: kIsWeb || Platform.isAndroid || Platform.isIOS
            ? Colors.black
            : Colors.transparent,
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white),
          displayMedium: TextStyle(color: Colors.white),
          displaySmall: TextStyle(color: Colors.white),
          headlineLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
          labelMedium: TextStyle(color: Colors.white70), // Keep 70% opacity for labels if desired
          labelSmall: TextStyle(color: Colors.white),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.red, // Primary color for some interactive elements
          onPrimary: Colors.white, // Text color on primary background
          secondary: Colors.cyan, // Secondary color
          onSecondary: Colors.white, // Text color on secondary background
          surface: Colors.black, // Surface color for cards, dialogs
          onSurface: Colors.white, // Text color on surface
          background: Colors.black, // Background color
          onBackground: Colors.white, // Text color on background
          error: Colors.red, // Error color
          onError: Colors.white, // Text color on error
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white),
          hintStyle: TextStyle(color: Colors.white70),
          prefixStyle: TextStyle(color: Colors.white),
          suffixStyle: TextStyle(color: Colors.white),
          helperStyle: TextStyle(color: Colors.white70),
          counterStyle: TextStyle(color: Colors.white70),
          errorStyle: TextStyle(color: Colors.redAccent),
          filled: true,
          fillColor: Colors.white10, // A subtle fill for text fields
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent),
          ),
        ),
        sliderTheme: const SliderThemeData(
          overlayColor: Colors.white24, // Color when long-pressed
          thumbColor: Colors.white,
          activeTrackColor: Colors.white,
          inactiveTrackColor: Colors.white54,
          valueIndicatorColor: Colors.white, // For the label that pops up
          valueIndicatorTextStyle: TextStyle(color: Colors.black), // Text on the value indicator
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white; // Thumb color when ON
            }
            return Colors.white; // Thumb color when OFF
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.green; // Track color when ON
            }
            return Colors.grey; // Track color when OFF
          }),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: Colors.white, // Ensure text in ListTiles is white
          iconColor: Colors.white, // Ensure icons in ListTiles are white
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
        title: Text(isWorkColor ? 'Select Work Color' : 'Select Rest Color'), // Now inherits from theme
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
            child: const Text('OK'), // Now inherits from theme
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
                decoration: InputDecoration(
                  labelText: 'Section ${index + 1} (minutes)',
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
              // Window Position Sliders - NOTE: These will not have an effect without window_manager >= 0.5.2
              const Text('Window X Position (0-100) - No effect on this version'),
              Slider(
                value: settings.windowX.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                label: settings.windowX.toString(),
                onChanged: (value) {
                  settings.updateWindowX(value.toInt());
                },
                onChangeEnd: (_) => settings.savePreferences(),
              ),
              const Text('Window Y Position (0-100) - No effect on this version'),
              Slider(
                value: settings.windowY.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                label: settings.windowY.toString(),
                onChanged: (value) {
                  settings.updateWindowY(value.toInt());
                },
                onChangeEnd: (_) => settings.savePreferences(),
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
  bool isRunning = false;
  late AnimationController _flashController;
  Timer? _timer;

  // Variables for central back button visibility
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
    _applyDesktopSettings(); // Apply settings on screen entry

    // Start the timer automatically when entering the screen
    _startTimer();
  }

  Future<void> _loadAudio() async {
    // This method is now effectively a placeholder as audio is prepared on demand in _playTransitionEffects
    try {
      // You can add pre-loading logic here if needed for very quick, repeated sounds
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

        await window_manager.WindowManager.instance.setIgnoreMouseEvents(
          widget.settings.isClickThroughEnabled,
        );

        // Removed the getPrimaryDisplay() call and position calculations
        // as this method is not available in window_manager 0.5.1
        // The window will default to center based on initial windowOptions in main()
        // and only size/opacity/click-through will be applied from settings here.
        debugPrint('Window X/Y positioning not applied (window_manager < 0.5.2)');

      } catch (e) {
        debugPrint('Desktop settings error: $e');
      }
    }
  }

  void _startTimer() {
    if (isRunning) return;
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

  void _tick() {
    if (!isRunning) return;
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
      });
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
      // Play transition effects for new sections
      if (currentSection != 0 || elapsedTime > 0) {
        _playTransitionEffects(currentSection % 2 == 0);
      }
    }
  }

  // Modified: Make _playTransitionEffects async and re-set source/clip
  void _playTransitionEffects(bool isWork) async {
    if (widget.settings.isSoundEnabled) {
      try {
        // Stop any currently playing audio from this player first
        await _player.stop(); // Ensures the player is reset
        // Re-set the asset source and clip before playing to ensure it's fresh for each playback
        await _player.setAsset('assets/sounds/tick.wav');
        await _player.setClip(
          end: Duration(
            milliseconds: (widget.settings.audioDuration * 1000).toInt(),
          ),
        );
        // Explicitly load the source after setting the clip to ensure preparation
        await _player.load(); // CRUCIAL for reliable clipping on desktop
        // Then play
        await _player.play();
      } catch (e) {
        debugPrint('Audio play error: $e');
      }
    }
    if (widget.settings.isVibrationEnabled) {
      _flashController.forward().then((_) => _flashController.reverse());
    }
  }

  void _showCentralBackButton() {
    _centralButtonVisibilityTimer?.cancel();
    if (!_isCentralButtonVisible) {
      setState(() {
        _isCentralButtonVisible = true;
      });
    }
    _centralButtonVisibilityTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isCentralButtonVisible = false;
        });
      }
    });
  }

  void _resetAndGoBack() async {
    _timer?.cancel();
    setState(() {
      isRunning = false;
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
        // Reset desktop window properties to defaults for settings page context
        await window_manager.WindowManager.instance.setIgnoreMouseEvents(false); // Make window clickable again
        await window_manager.WindowManager.instance.setMovable(true); // Make window movable again (temp for settings screen)
        await window_manager.WindowManager.instance.setOpacity(1.0); // Full opacity
        await window_manager.WindowManager.instance.setSize(const Size(400, 400)); // Default size
        await window_manager.WindowManager.instance.center(); // Center the window
      } catch (e) {
        debugPrint('Reset desktop settings error: $e');
      }
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    _flashController.dispose();
    _centralButtonVisibilityTimer?.cancel();
    if (Platform.isAndroid || Platform.isIOS) {
      WakelockPlus.disable();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final centerX = constraints.maxWidth / 2;
          final centerY = constraints.maxHeight / 2;
          final clockRadius = (math.min(constraints.maxWidth, constraints.maxHeight) / 2) - 12;
          final centralTapRadius = clockRadius * 0.10; // 10% of clock radius

          return GestureDetector(
            onTapDown: (details) {
              final tapPosition = details.localPosition;
              final distance = math.sqrt(
                math.pow(tapPosition.dx - centerX, 2) +
                math.pow(tapPosition.dy - centerY, 2),
              );

              if (distance <= centralTapRadius) {
                _showCentralBackButton();
              }
            },
            behavior: HitTestBehavior.translucent,
            child: MouseRegion(
              onHover: (event) {
                final distance = math.sqrt(
                  math.pow(event.localPosition.dx - centerX, 2) +
                  math.pow(event.localPosition.dy - centerY, 2),
                );
                if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS) && distance <= centralTapRadius) {
                  _showCentralBackButton();
                } else if (_isCentralButtonVisible && distance > centralTapRadius && _centralButtonVisibilityTimer != null && !_centralButtonVisibilityTimer!.isActive) {
                    setState(() {
                      _isCentralButtonVisible = false;
                    });
                }
              },
              child: Stack(
                children: [
                  Center(
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
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

                  Center(
                    child: AnimatedOpacity(
                      opacity: _isCentralButtonVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: !_isCentralButtonVisible,
                        child: FloatingActionButton(
                          onPressed: _resetAndGoBack,
                          backgroundColor: Colors.blueGrey,
                          heroTag: 'centralBackButton',
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
