import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:animate_do/animate_do.dart';

class AudioScribeScreen extends StatefulWidget {
  const AudioScribeScreen({super.key});

  @override
  State<AudioScribeScreen> createState() => _AudioScribeScreenState();
}

class _AudioScribeScreenState extends State<AudioScribeScreen> with SingleTickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _transcript = '';
  String _statusMessage = 'Initializing speech recognition...';
  double _soundLevel = 0.0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _initSpeech();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) => setState(() => _statusMessage = 'Error: ${error.errorMsg}'),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    if (mounted) {
      setState(() {
        _statusMessage = _speechEnabled
            ? 'Tap the mic to start transcribing'
            : 'Speech recognition not available on this device';
      });
    }
  }

  void _toggleListening() async {
    if (!_speechEnabled) {
      setState(() => _statusMessage = 'Speech recognition not available');
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      setState(() {
        _isListening = true;
        _statusMessage = 'Listening...';
      });
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _transcript = result.recognizedWords;
          });
        },
        onSoundLevelChange: (level) {
          setState(() => _soundLevel = (level + 10) / 20); // normalize
        },
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 5),
        localeId: 'en_US',
      );
    }
  }

  void _clearTranscript() {
    setState(() => _transcript = '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      appBar: AppBar(
        title: Text('Audio Scribe', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0E0E14),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_transcript.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white54),
              tooltip: 'Copy transcript',
              onPressed: () => Clipboard.setData(ClipboardData(text: _transcript)),
            ),
          if (_transcript.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
              tooltip: 'Clear',
              onPressed: _clearTranscript,
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated mic button
              GestureDetector(
                onTap: _toggleListening,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isListening)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) => Container(
                          width: 160 + (_soundLevel * 40),
                          height: 160 + (_soundLevel * 40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.pinkAccent.withValues(alpha: 0.08 * _pulseController.value),
                          ),
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? Colors.redAccent.withValues(alpha: 0.15)
                            : const Color(0xFF6C63FF).withValues(alpha: 0.15),
                        border: Border.all(
                          color: _isListening ? Colors.redAccent : const Color(0xFF6C63FF),
                          width: 2.5,
                        ),
                      ),
                      child: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 52,
                        color: _isListening ? Colors.redAccent : const Color(0xFF6C63FF),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                _isListening ? 'Listening... tap to stop' : 'Tap to start',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isListening ? Colors.redAccent : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              if (_transcript.isEmpty && !_isListening)
                FadeIn(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.record_voice_over_outlined, size: 40, color: Colors.white24),
                        const SizedBox(height: 12),
                        Text(
                          'Speak clearly in English.\nYour words will appear here in real time.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: FadeInUp(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C28),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _transcript.isEmpty ? 'Waiting for speech...' : _transcript,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            color: _transcript.isEmpty ? Colors.white24 : Colors.white.withValues(alpha: 0.88),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
