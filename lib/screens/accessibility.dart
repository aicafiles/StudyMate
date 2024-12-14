import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  bool _textToSpeechEnabled = false;
  bool _colorblindModeEnabled = false;
  double _fontSize = 16.0;
  bool _darkModeEnabled = false;

  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _textToSpeechEnabled = prefs.getBool('textToSpeech') ?? false;
      _colorblindModeEnabled = prefs.getBool('colorblindMode') ?? false;
      _fontSize = prefs.getDouble('fontSize') ?? 16.0;
      _darkModeEnabled = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('textToSpeech', _textToSpeechEnabled);
    await prefs.setBool('colorblindMode', _colorblindModeEnabled);
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setBool('darkMode', _darkModeEnabled);
  }

  Future<void> _toggleTextToSpeech() async {
    setState(() {
      _textToSpeechEnabled = !_textToSpeechEnabled;
    });
    if (_textToSpeechEnabled) {
      await _flutterTts.speak('Text-to-Speech enabled.');
    } else {
      await _flutterTts.stop();
    }
    _savePreferences();
  }

  void _toggleColorblindMode() {
    setState(() {
      _colorblindModeEnabled = !_colorblindModeEnabled;
    });
    _savePreferences();
  }

  void _adjustFontSize(double newFontSize) {
    setState(() {
      _fontSize = newFontSize;
    });
    _savePreferences();
  }

  void _toggleDarkMode() {
    setState(() {
      _darkModeEnabled = !_darkModeEnabled;
    });
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    final defaultColors = {
      'primary': const Color(0xFF42A5F5),
      'background': const Color(0xFFF5F5F5),
      'text': Colors.black87,
    };

    final colorblindColors = {
      'primary': const Color(0xFF8B4513),
      'background': const Color(0xFFF5F5DC), 
      'text': Colors.black,
    };

    final darkColors = {
      'primary': Colors.black,
      'background': Colors.black,
      'text': Colors.white,
    };

    final activeColors = _darkModeEnabled
        ? darkColors
        : _colorblindModeEnabled
            ? colorblindColors
            : defaultColors;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: activeColors['primary'],
        scaffoldBackgroundColor: activeColors['background'],
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: _fontSize, color: activeColors['text']),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: activeColors['primary'],
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: activeColors['text'],
          ),
          iconTheme: IconThemeData(color: activeColors['text']),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Accessibility Settings'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildFontSizeAdjustment(),
              ),
              const SizedBox(height: 16),
              _buildAccessibilityOption(
                title: 'Text-to-Speech',
                description:
                    'Enable text-to-speech to have content read aloud for you.',
                icon: Icons.volume_up_outlined,
                toggleValue: _textToSpeechEnabled,
                onTap: _toggleTextToSpeech,
                color: activeColors['primary']!,
              ),
              const SizedBox(height: 16),
              _buildAccessibilityOption(
                title: 'Colorblind Mode',
                description:
                    'Activate colorblind-friendly mode to enhance visual accessibility.',
                icon: Icons.palette_outlined,
                toggleValue: _colorblindModeEnabled,
                onTap: _toggleColorblindMode,
                color: activeColors['primary']!,
              ),
              const SizedBox(height: 16),
              _buildAccessibilityOption(
                title: 'Dark Mode',
                description:
                    'Switch to dark mode for a comfortable viewing experience in low light.',
                icon: Icons.dark_mode_outlined,
                toggleValue: _darkModeEnabled,
                onTap: _toggleDarkMode,
                color: activeColors['primary']!,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessibilityOption({
    required String title,
    required String description,
    required IconData icon,
    required bool toggleValue,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 28,
              color: color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: toggleValue,
              onChanged: (value) => onTap(),
              activeColor: color,
              activeTrackColor: color.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeAdjustment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adjust Font Size',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _fontSize,
          min: 12.0,
          max: 24.0,
          divisions: 6,
          label: '${_fontSize.toInt()}',
          onChanged: _adjustFontSize,
          activeColor: Colors.blue[700]!,
          inactiveColor: Colors.grey,
        ),
        Text(
          'Preview Text',
          style: TextStyle(
            fontSize: _fontSize,
            fontFamily: 'Poppins',
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
