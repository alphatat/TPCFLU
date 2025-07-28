import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    JustAudioMediaKit.ensureInitialized(
      windows: Platform.isWindows,
      linux: Platform.isLinux,
    );
  }
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(400, 400));
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => PomodoroSettings()..loadSettings(),
      child: const PomodoroApp(),
    ),
  );
}

class PomodoroSettings extends ChangeNotifier {
  List<int> sectionMinutes = [1, 1, 1, 1]; // Shortened for testing
  bool isSoundEnabled = true;
  bool isVibrationEnabled = true;
  Color workColor = Colors.red;
  Color breakColor = Colors.green;
  double audioDuration = 1.0;
  double windowOpacity = 1.0;
  double windowSize = 400.0;
  bool isClickThrough = false;
  bool isDraggable = true;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    sectionMinutes = (prefs.getString('sectionMinutes') ?? '1,1,1,1')
        .split(',')
        .map(int.parse)
        .toList();
    isSoundEnabled = prefs.getBool('isSoundEnabled') ?? true;
    isVibrationEnabled = prefs.getBool('isVibrationEnabled') ?? true;
    workColor = Color(prefs.getInt('workColor') ?? 0xFFFF0000);
    breakColor = Color(prefs.getInt('breakColor') ?? 0xFF00FF00);
    audioDuration = prefs.getDouble('audioDuration') ?? 1.0;
    windowOpacity = prefs.getDouble('windowOpacity') ?? 1.0;
    windowSize = prefs.getDouble('windowSize') ?? 400.0;
    isClickThrough = prefs.getBool('isClickThrough') ?? false;
    isDraggable = prefs.getBool('isDraggable') ?? true;
    notifyListeners();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sectionMinutes', sectionMinutes.join(','));
    await prefs.setBool('isSoundEnabled', isSoundEnabled);
    await prefs.setBool('isVibrationEnabled', isVibrationEnabled);
    await prefs.setInt(
        'workColor', workColor.toARGB32()); // Safe for SharedPreferences
    await prefs.setInt(
        'breakColor', breakColor.toARGB32()); // Safe for SharedPreferences
    await prefs.setDouble('audioDuration', audioDuration);
    await prefs.setDouble('windowOpacity', windowOpacity);
    await prefs.setDouble('windowSize', windowSize);
    await prefs.setBool('isClickThrough', isClickThrough);
    await prefs.setBool('isDraggable', isDraggable);
    notifyListeners();
  }
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TPCFLU',
      theme: ThemeData(useMaterial3: true),
      home: const SettingsStartScreen(),
    );
  }
}

class SettingsStartScreen extends StatelessWidget {
  const SettingsStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<PomodoroSettings>(context);
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          height: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Pomodoro Timer',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(40),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: settings,
                        child: const PomodoroScreen(),
                      ),
                    ),
                  );
                },
                child:
                    const Icon(Icons.play_arrow, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => _showSettingsDialog(context, settings),
                child: const Text('Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, PomodoroSettings settings) {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(settings: settings),
    );
  }
}

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with TickerProviderStateMixin {
  late AnimationController _flashController;
  late AudioPlayer _player;
  Timer? _timer;
  int _currentSection = 0;
  int _secondsRemaining = 0;
  bool _isRunning = false;
  bool _isHoveringBackButton = false;
  double _currentAudioDuration = 1.0; // Track current audio duration

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final settings = Provider.of<PomodoroSettings>(context, listen: false);
    _secondsRemaining = settings.sectionMinutes[0] * 60;
    _currentAudioDuration = settings.audioDuration;
    _loadAudio(_currentAudioDuration);
    settings.addListener(() {
      if (settings.audioDuration != _currentAudioDuration) {
        _currentAudioDuration = settings.audioDuration;
        _loadAudio(_currentAudioDuration);
      }
    });
  }

  Future<void> _loadAudio(double audioDuration) async {
    try {
      debugPrint('Attempting to load audio: assets/sounds/test.wav');
      await _player.setAsset('assets/sounds/test.wav', preload: true);
      await _player.setClip(
          end: Duration(milliseconds: (audioDuration * 1000).toInt()));
      await _player.load();
      debugPrint('Audio loaded successfully');
    } catch (e, stackTrace) {
      debugPrint('Audio load error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
    });
    if (Platform.isAndroid || Platform.isIOS) {
      WakelockPlus.enable();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!_isRunning) return;
    setState(() {
      _secondsRemaining--;
      if (_secondsRemaining <= 0) {
        final settings = Provider.of<PomodoroSettings>(context, listen: false);
        _currentSection =
            (_currentSection + 1) % settings.sectionMinutes.length;
        _secondsRemaining = settings.sectionMinutes[_currentSection] * 60;
        _playTransitionEffects(_currentSection % 2 == 0);
      }
    });
  }

  void _playTransitionEffects(bool isWork) {
    final settings = Provider.of<PomodoroSettings>(context, listen: false);
    if (settings.isSoundEnabled) {
      try {
        debugPrint('Playing audio for section transition');
        _player.seek(Duration.zero);
        _player.play().then((_) {
          debugPrint('Audio playback completed');
        }).catchError((e, stackTrace) {
          debugPrint('Audio play error: $e');
          debugPrint('Stack trace: $stackTrace');
        });
      } catch (e, stackTrace) {
        debugPrint('Audio play attempt error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
    if (settings.isVibrationEnabled) {
      _flashController.forward().then((_) => _flashController.reverse());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    _flashController.dispose();
    if (Platform.isAndroid || Platform.isIOS) {
      WakelockPlus.disable();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<PomodoroSettings>(context);
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.setOpacity(settings.windowOpacity);
      windowManager.setSize(Size(settings.windowSize, settings.windowSize));
      windowManager.setAsFrameless();
      windowManager.setAlwaysOnTop(true);
      windowManager.setIgnoreMouseEvents(settings.isClickThrough);
      windowManager.setMovable(settings.isDraggable);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () =>
                SettingsStartScreen()._showSettingsDialog(context, settings),
            child: AnimatedBuilder(
              animation: _flashController,
              builder: (context, _) {
                return Container(
                  color: _currentSection % 2 == 0
                      ? settings.workColor
                          .withValues(alpha: _flashController.value * 255.0)
                      : settings.breakColor
                          .withValues(alpha: _flashController.value * 255.0),
                  child: CustomPaint(
                    painter: PomodoroPainter(
                      progress: _secondsRemaining /
                          (settings.sectionMinutes[_currentSection] * 60),
                      isWork: _currentSection % 2 == 0,
                      workColor: settings.workColor,
                      breakColor: settings.breakColor,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),
          if (!_isRunning)
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(40),
                ),
                onPressed: _startTimer,
                child:
                    const Icon(Icons.play_arrow, size: 48, color: Colors.white),
              ),
            ),
          Positioned(
            top: 10,
            left: 10,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHoveringBackButton = true),
              onExit: (_) => setState(() => _isHoveringBackButton = false),
              child: IgnorePointer(
                ignoring: settings.isClickThrough && !_isHoveringBackButton,
                child: AnimatedOpacity(
                  opacity: _isHoveringBackButton ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PomodoroPainter extends CustomPainter {
  final double progress;
  final bool isWork;
  final Color workColor;
  final Color breakColor;

  PomodoroPainter({
    required this.progress,
    required this.isWork,
    required this.workColor,
    required this.breakColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;

    paint.color = isWork ? breakColor : workColor;
    canvas.drawCircle(center, radius, paint);

    paint.color = isWork ? workColor : breakColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -90 * pi / 180,
      2 * pi * progress,
      false,
      paint,
    );

    final handLength = radius * 0.8;
    final angle = -90 * pi / 180 + 2 * pi * progress;
    final handEnd =
        center + Offset(cos(angle) * handLength, sin(angle) * handLength);
    paint.color = Colors.black;
    paint.strokeWidth = 2.0;
    canvas.drawLine(center, handEnd, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SettingsDialog extends StatelessWidget {
  final PomodoroSettings settings;

  const SettingsDialog({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pomodoro Settings'),
      content: SingleChildScrollView(
        child: Consumer<PomodoroSettings>(
          builder: (context, settings, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Work 1 (min)'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  settings.sectionMinutes[0] =
                      int.tryParse(value) ?? settings.sectionMinutes[0];
                  settings.saveSettings();
                },
                controller: TextEditingController(
                    text: settings.sectionMinutes[0].toString()),
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Break 1 (min)'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  settings.sectionMinutes[1] =
                      int.tryParse(value) ?? settings.sectionMinutes[1];
                  settings.saveSettings();
                },
                controller: TextEditingController(
                    text: settings.sectionMinutes[1].toString()),
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Work 2 (min)'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  settings.sectionMinutes[2] =
                      int.tryParse(value) ?? settings.sectionMinutes[2];
                  settings.saveSettings();
                },
                controller: TextEditingController(
                    text: settings.sectionMinutes[2].toString()),
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Break 2 (min)'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  settings.sectionMinutes[3] =
                      int.tryParse(value) ?? settings.sectionMinutes[3];
                  settings.saveSettings();
                },
                controller: TextEditingController(
                    text: settings.sectionMinutes[3].toString()),
              ),
              CheckboxListTile(
                title: const Text('Sound Enabled'),
                value: settings.isSoundEnabled,
                onChanged: (value) {
                  settings.isSoundEnabled = value ?? settings.isSoundEnabled;
                  settings.saveSettings();
                },
              ),
              CheckboxListTile(
                title: const Text('Vibration Enabled'),
                value: settings.isVibrationEnabled,
                onChanged: (value) {
                  settings.isVibrationEnabled =
                      value ?? settings.isVibrationEnabled;
                  settings.saveSettings();
                },
              ),
              ListTile(
                title: const Text('Work Color'),
                trailing: Container(
                  width: 24,
                  height: 24,
                  color: settings.workColor,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Pick Work Color'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: settings.workColor,
                          onColorChanged: (color) {
                            settings.workColor = color;
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            settings.saveSettings();
                            Navigator.pop(context);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Break Color'),
                trailing: Container(
                  width: 24,
                  height: 24,
                  color: settings.breakColor,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Pick Break Color'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: settings.breakColor,
                          onColorChanged: (color) {
                            settings.breakColor = color;
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            settings.saveSettings();
                            Navigator.pop(context);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Slider(
                value: settings.audioDuration,
                min: 0.5,
                max: 5.0,
                divisions: 45,
                label: '${settings.audioDuration.toStringAsFixed(1)}s',
                onChanged: (value) {
                  settings.audioDuration = value;
                  settings.saveSettings();
                },
              ),
              if (Platform.isWindows ||
                  Platform.isMacOS ||
                  Platform.isLinux) ...[
                Slider(
                  value: settings.windowOpacity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: settings.windowOpacity.toStringAsFixed(1),
                  onChanged: (value) {
                    settings.windowOpacity = value;
                    settings.saveSettings();
                  },
                ),
                Slider(
                  value: settings.windowSize,
                  min: 200.0,
                  max: 800.0,
                  divisions: 60,
                  label: settings.windowSize.toStringAsFixed(0),
                  onChanged: (value) {
                    settings.windowSize = value;
                    settings.saveSettings();
                  },
                ),
                CheckboxListTile(
                  title: const Text('Click Through'),
                  value: settings.isClickThrough,
                  onChanged: (value) {
                    settings.isClickThrough = value ?? settings.isClickThrough;
                    settings.saveSettings();
                  },
                ),
                CheckboxListTile(
                  title: const Text('Draggable'),
                  value: settings.isDraggable,
                  onChanged: (value) {
                    settings.isDraggable = value ?? settings.isDraggable;
                    settings.saveSettings();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
