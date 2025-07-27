import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:wakelock_plus/wakelock_plus.dart'; // Import wakelock_plus

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
      await windowManager.setIgnoreMouseEvents(false); // Initial state of ignore mouse events
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
  bool isDraggable = true; // Separate setting for draggable
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
    });
    // ONLY apply opacity and size to the current window (Settings screen) on load
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.setOpacity(opacity);
      await windowManager.setSize(Size(windowSize, windowSize));
      // Do NOT set ignoreMouseEvents or movable here, as they should only apply to PomodoroScreen
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
            const Text(
              'Timer Sections (minutes)',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            ...List.generate(
              4,
              (index) => TextField(
                decoration: InputDecoration(
                  labelText: 'Section ${index + 1}',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: sectionMinutes[index].toString()), // Added controller
                onChanged: (value) {
                  sectionMinutes[index] =
                      int.tryParse(value) ?? sectionMinutes[index];
                },
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text(
                'Sound Enabled',
                style: TextStyle(color: Colors.white),
              ),
              value: isSoundEnabled,
              onChanged: (value) {
                setState(() {
                  isSoundEnabled = value;
                  _savePreferences();
                });
              },
            ),
            SwitchListTile(
              title: const Text(
                'Vibration/Flash Enabled',
                style: TextStyle(color: Colors.white),
              ),
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
              title: const Text(
                'Work Color',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Container(width: 30, height: 30, color: workColor),
              onTap: () => _selectColor(context, true),
            ),
            ListTile(
              title: const Text(
                'Rest Color',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Container(width: 30, height: 30, color: restColor),
              onTap: () => _selectColor(context, false),
            ),
            const SizedBox(height: 20),
            const Text(
              'Audio Duration (seconds)',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Slider(
              value: audioDuration,
              min: 0.5,
              max: 10.5,
              divisions: 20,
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
              const Text(
                'Desktop Settings',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const Text(
                'Window Opacity',
                style: TextStyle(color: Colors.white),
              ),
              Slider(
                value: opacity,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: opacity.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    opacity = value;
                    windowManager.setOpacity(value); // Apply to current window
                    _savePreferences();
                  });
                },
              ),
              const Text('Window Size', style: TextStyle(color: Colors.white)),
              Slider(
                value: windowSize,
                min: 100.0,
                max: 900.0,
                divisions: 40,
                label: windowSize.toStringAsFixed(0),
                onChanged: (value) {
                  setState(() {
                    windowSize = value;
                    windowManager.setSize(Size(value, value)); // Apply to current window
                    _savePreferences();
                  });
                },
              ),
              SwitchListTile(
                title: const Text(
                  'Click-Through',
                  style: TextStyle(color: Colors.white),
                ),
                value: isClickThroughEnabled,
                onChanged: (value) {
                  setState(() {
                    isClickThroughEnabled = value;
                    _savePreferences();
                  });
                },
              ),
              SwitchListTile(
                title: const Text(
                  'Draggable',
                  style: TextStyle(color: Colors.white),
                ),
                value: isDraggable,
                onChanged: (value) {
                  setState(() {
                    isDraggable = value;
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
                        isDraggable: isDraggable,
                        workColor: workColor,
                        restColor: restColor,
                        audioDuration: audioDuration,
                        opacity: opacity, // Pass opacity to PomodoroScreen
                        windowSize: windowSize, // Pass windowSize to PomodoroScreen
                      ),
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
  final List<int> sections;
  final bool isSoundEnabled;
  final bool isVibrationEnabled;
  final bool isClickThroughEnabled;
  final bool isDraggable;
  final Color workColor;
  final Color restColor;
  final double audioDuration;
  final double opacity; // New property
  final double windowSize; // New property

  const PomodoroScreen({
    super.key,
    required this.sections,
    required this.isSoundEnabled,
    required this.isVibrationEnabled,
    required this.isClickThroughEnabled,
    required this.isDraggable,
    required this.workColor,
    required this.restColor,
    required this.audioDuration,
    required this.opacity, // Make it required
    required this.windowSize, // Make it required
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
      // Apply desktop specific settings when PomodoroScreen is initialized
      windowManager.setMovable(widget.isDraggable);
      windowManager.setIgnoreMouseEvents(widget.isClickThroughEnabled);
      windowManager.setOpacity(widget.opacity);
      windowManager.setSize(Size(widget.windowSize, widget.windowSize));
    }
  }

  @override
  void didUpdateWidget(covariant PomodoroScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // React to changes in settings passed from SettingsStartScreen
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      if (widget.isDraggable != oldWidget.isDraggable) {
        windowManager.setMovable(widget.isDraggable);
      }
      if (widget.isClickThroughEnabled != oldWidget.isClickThroughEnabled) {
        windowManager.setIgnoreMouseEvents(widget.isClickThroughEnabled);
      }
      if (widget.opacity != oldWidget.opacity) {
        windowManager.setOpacity(widget.opacity);
      }
      if (widget.windowSize != oldWidget.windowSize) {
        windowManager.setSize(Size(widget.windowSize, widget.windowSize));
      }
    }
  }

  Future<void> _loadAudio() async {
    try {
      // Try loading local asset first
      await _player.setAsset('assets/sounds/tick.wav');
      debugPrint('Successfully loaded local audio asset: assets/sounds/tick.wav');
    } catch (e) {
      debugPrint('Error loading local audio asset: $e. Attempting to load online audio.');
      try {
        // Fallback to a publicly available online audio file for testing
        await _player.setUrl('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
        debugPrint('Successfully loaded online audio asset.');
      } catch (onlineError) {
        debugPrint('Error loading online audio asset: $onlineError. Audio will not play.');
      }
    } finally {
      // Apply clip duration after asset/url is set
      try {
        await _player.setClip(
          end: Duration(milliseconds: (widget.audioDuration * 1000).toInt()),
        );
        await _player.load(); // Explicitly pre-load to prevent delays/issues on first play
      } catch (clipLoadError) {
        debugPrint('Error setting clip or pre-loading audio: $clipLoadError');
      }
    }
  }

  void _startTimer() {
    if (!isRunning) {
      setState(() {
        isRunning = true;
      });
      _playTransitionEffects(currentSection % 2 == 0);
      _tick();
      if (Platform.isAndroid || Platform.isIOS) { // Acquire wakelock only for mobile
        WakelockPlus.enable(); // Enable wakelock when timer starts
      }
    }
  }

  void _pauseTimer() {
    if (isRunning) {
      setState(() {
        isRunning = false;
      });
      if (Platform.isAndroid || Platform.isIOS) { // Release wakelock for mobile
        WakelockPlus.disable(); // Disable wakelock when timer pauses
      }
    }
  }

  void _tick() {
    if (!isRunning) return; // Stop if paused

    setState(() {
      timeLeftInSeconds--;
      _checkSectionTransition();
    });

    if (timeLeftInSeconds > 0) {
      Future.delayed(const Duration(seconds: 1), _tick);
    } else {
      _playTransitionEffects(true); // Play final transition effect
      
      // Release wakelock when timer finishes and loops, will be re-acquired on next _startTimer
      if (Platform.isAndroid || Platform.isIOS) {
        WakelockPlus.disable(); 
      }
      
      // Reset timer state and mark as not running immediately for UI update
      setState(() {
        timeLeftInSeconds = widget.sections.reduce((a, b) => a + b);
        currentSection = 0;
        isRunning = false; // Set to false so the button updates to 'Play'
      });

      // After a brief delay to ensure UI updates, restart the timer
      Future.delayed(const Duration(milliseconds: 100), () {
        _startTimer(); // This will make it loop
      });
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
    // Handle the very end of the timer, where elapsed time equals total time
    if (elapsedTime >= totalTime) {
      newSection = widget.sections.length - 1; // Last section
    }

    if (newSection != currentSection) {
      setState(() {
        currentSection = newSection;
      });
      // Only play sound when transitioning *from* a section, not on initial start (currentSection from -1 to 0)
      if (currentSection != 0 || (elapsedTime > 0 && currentSection == 0)) {
        _playTransitionEffects(currentSection % 2 == 0);
      }
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
    // This dialog is opened from PomodoroScreen, so changes to window properties
    // like click-through or draggable here will be applied to the PomodoroScreen's window.
    List<int> sectionMinutes = widget.sections.map((s) => s ~/ 60).toList();
    bool localClickThrough = widget.isClickThroughEnabled;
    bool localDraggable = widget.isDraggable;
    double localOpacity = widget.opacity; // Get current opacity for dialog slider
    double localWindowSize = widget.windowSize; // Get current window size for dialog slider

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
                  labelText: 'Section ${index + 1} (minutes)',
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: sectionMinutes[index].toString()),
                onChanged: (value) {
                  sectionMinutes[index] =
                      int.tryParse(value) ?? sectionMinutes[index];
                },
              ),
            ),
            if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ...[
              CheckboxListTile(
                title: const Text('Click-Through'),
                value: localClickThrough,
                onChanged: (value) {
                  setState(() {
                    localClickThrough = value ?? false;
                    windowManager.setIgnoreMouseEvents(localClickThrough); // Apply immediately to current (Pomodoro) window
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Draggable'),
                value: localDraggable,
                onChanged: (value) {
                  setState(() {
                    localDraggable = value ?? false;
                    windowManager.setMovable(localDraggable); // Apply immediately to current (Pomodoro) window
                  });
                },
              ),
              const Text(
                'Window Opacity',
                style: TextStyle(color: Colors.black54), // Adjust text color for AlertDialog
              ),
              Slider(
                value: localOpacity,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: localOpacity.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    localOpacity = value;
                    windowManager.setOpacity(localOpacity); // Apply immediately to current (Pomodoro) window
                  });
                },
              ),
              const Text('Window Size', style: TextStyle(color: Colors.black54)),
              Slider(
                value: localWindowSize,
                min: 100.0,
                max: 900.0,
                divisions: 40,
                label: localWindowSize.toStringAsFixed(0),
                onChanged: (value) {
                  setState(() {
                    localWindowSize = value;
                    windowManager.setSize(Size(localWindowSize, localWindowSize)); // Apply immediately to current (Pomodoro) window
                  });
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Update state of PomodoroScreen based on dialog changes
              setState(() {
                // Since widget.sections is final, we re-calculate for the current screen's state
                // The actual saving to SharedPreferences is done below.
                timeLeftInSeconds = sectionMinutes.reduce((a, b) => a + b) * 60;
                currentSection = 0;
                // Update PomodoroScreen's properties (not directly, but will trigger didUpdateWidget if we navigated back)
                // For a more immediate update without pop/push, you'd use a callback.
              });
              
              // Save preferences
              SharedPreferences.getInstance().then((prefs) {
                prefs.setBool('click_through_enabled', localClickThrough);
                prefs.setBool('draggable_enabled', localDraggable);
                prefs.setDouble('opacity', localOpacity); // Save opacity
                prefs.setDouble('window_size', localWindowSize); // Save window size
                for (int i = 0; i < 4; i++) {
                  prefs.setInt('section_$i', sectionMinutes[i]);
                }
              });
              Navigator.pop(context); // Close the dialog
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
    if (Platform.isAndroid || Platform.isIOS) {
      WakelockPlus.disable();
    }
    // Revert desktop specific settings to non-interactive/non-draggable when going back to settings
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.setIgnoreMouseEvents(false); // Make it clickable again
      windowManager.setMovable(true); // Make it draggable again
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    if (Platform.isAndroid || Platform.isIOS) {
      WakelockPlus.disable();
    }
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
                  sections: widget.sections.map((m) => m ~/ 60).toList(), // Pass sections in minutes for painter
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
              onPressed: () {
                if (isRunning) {
                  _pauseTimer();
                } else {
                  _startTimer();
                }
              },
              backgroundColor: isRunning ? Colors.orange : Colors.red, // Orange for Pause, Red for Play
              child: Icon(
                isRunning ? Icons.pause : Icons.play_arrow,
                size: 50,
                color: Colors.white,
              ),
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
  final List<int> sections; // These are now durations in minutes
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

    double currentDrawAngle = 270; // Start at 12 o'clock (top)
    int cumulativeSecondsPassed = 0;

    for (int i = 0; i < sections.length; i++) {
      final int sectionDurationSeconds = sections[i] * 60; // Convert minutes to seconds
      final double sectionSweepDegrees = (sectionDurationSeconds / totalTimeInSeconds) * 360;

      final Color solidColor = i % 2 == 0 ? workColor : restColor;
      final Color lightColor = i % 2 == 0 ? workColor.withOpacity(0.3) : restColor.withOpacity(0.3);

      final int secondsElapsedSoFar = totalTimeInSeconds - timeLeftInSeconds;

      // Case 1: This section is entirely in the past (fully elapsed)
      if (secondsElapsedSoFar >= cumulativeSecondsPassed + sectionDurationSeconds) {
        final paintLight = Paint()..style = PaintingStyle.fill..color = lightColor;
        canvas.drawArc(
          oval,
          currentDrawAngle * math.pi / 180,
          sectionSweepDegrees * math.pi / 180,
          true,
          paintLight,
        );
      }
      // Case 2: This is the current active section
      else if (secondsElapsedSoFar >= cumulativeSecondsPassed && secondsElapsedSoFar < cumulativeSecondsPassed + sectionDurationSeconds) {
        // Calculate the elapsed part of this section
        final int elapsedInCurrentSection = secondsElapsedSoFar - cumulativeSecondsPassed;
        final double elapsedPartSweepDegrees = (elapsedInCurrentSection / sectionDurationSeconds) * sectionSweepDegrees;

        // Draw the elapsed part with light color
        if (elapsedPartSweepDegrees > 0) {
          final paintLight = Paint()..style = PaintingStyle.fill..color = lightColor;
          canvas.drawArc(
            oval,
            currentDrawAngle * math.pi / 180,
            elapsedPartSweepDegrees * math.pi / 180,
            true,
            paintLight,
          );
        }

        // Calculate the remaining part of this section
        final double remainingPartSweepDegrees = sectionSweepDegrees - elapsedPartSweepDegrees;
        // Draw the remaining part with solid color
        if (remainingPartSweepDegrees > 0) {
          final paintSolid = Paint()..style = PaintingStyle.fill..color = solidColor;
          canvas.drawArc(
            oval,
            (currentDrawAngle + elapsedPartSweepDegrees) * math.pi / 180,
            remainingPartSweepDegrees * math.pi / 180,
            true,
            paintSolid,
          );
        }
      }
      // Case 3: This section is entirely in the future
      else {
        final paintSolid = Paint()..style = PaintingStyle.fill..color = solidColor;
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

    // Draw Zeiger (hand)
    final double elapsedAngleDegreesForPointer = 360 * (1 - timeLeftInSeconds / totalTimeInSeconds);
    final zeigerAngle = (elapsedAngleDegreesForPointer + 270) * math.pi / 180;
    final zeigerX = center.dx + radius * math.cos(zeigerAngle);
    final zeigerY = center.dy + radius * math.sin(zeigerAngle);
    final zeigerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(center, Offset(zeigerX, zeigerY), zeigerPaint);

    const dotRadius = 3.0;
    final extendedZeigerX = center.dx + (radius + dotRadius / 2) * math.cos(zeigerAngle);
    final extendedZeigerY = center.dy + (radius + dotRadius / 2) * math.sin(zeigerAngle);
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(extendedZeigerX, extendedZeigerY),
      dotRadius,
      dotPaint,
    );

    // Draw time text in the center
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(timeLeftInSeconds ~/ 60).toString().padLeft(2, '0')}:'
              '${(timeLeftInSeconds % 60).toString().padLeft(2, '0')}',
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
  bool shouldRepaint(CircleTimerPainter oldDelegate) => true;
}
