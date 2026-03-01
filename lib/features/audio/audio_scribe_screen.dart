import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';

class AudioScribeScreen extends StatefulWidget {
  const AudioScribeScreen({super.key});

  @override
  State<AudioScribeScreen> createState() => _AudioScribeScreenState();
}

class _AudioScribeScreenState extends State<AudioScribeScreen> {
  final _record = AudioRecorder();
  bool _isRecording = false;
  String _transcript = "Press record to start transcribing audio.";

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _record.stop();
      setState(() {
        _isRecording = false;
        _transcript = "Transcribing locally...";
      });

      // Simulate transcription
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _transcript = "Transcription: \"The quick brown fox jumps over the lazy dog. This transcription was generated using an on-device Whisper model.\"";
      });
    } else {
      if (await _record.hasPermission()) {
        await _record.start(const RecordConfig(), path: 'audio.m4a');
        setState(() {
          _isRecording = true;
          _transcript = "Listening...";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Scribe')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Pulse(
                infinite: _isRecording,
                child: GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.redAccent.withOpacity(0.2) : Colors.teal.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isRecording ? Colors.redAccent : Colors.teal,
                        width: 4,
                      ),
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      size: 80,
                      color: _isRecording ? Colors.redAccent : Colors.teal,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                _isRecording ? 'Recording...' : 'Tap Mic to Start',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              FadeIn(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    _transcript,
                    style: GoogleFonts.outfit(fontSize: 18, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
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
