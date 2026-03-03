import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../chat/chat_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _deviceModel = 'your device';
  String _performanceNote = 'Loading device info...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDevice();
  }

  Future<void> _checkDevice() async {
    final deviceInfo = DeviceInfoPlugin();
    String perf = 'Running AI models locally requires a very powerful processor and plenty of RAM. Please be patient while generating responses.';
    String model = 'your device';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        model = '${androidInfo.manufacturer} ${androidInfo.model}';
        
        // Basic heuristic: check if it's a known flagship string or standard device
        // Real memory requires MethodChannels, so we rely on device model strings typically
        perf = 'Local AI inference is heavily dependent on hardware. High-end devices (Snapdragon 8+ series, massive RAM) will run TinyLlama decently fast (5-10 tokens/s). On mid-range devices like $model, please expect slower generation times and potential device heating. Keep the app open while generating.';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        model = iosInfo.utsname.machine;
        perf = 'Local AI requires newer A-series or M-series chips for good performance. On $model, expect slower generation on complex tasks.';
      } else if (Platform.isWindows) {
        model = 'Windows PC';
        perf = 'On PCs, generation will heavily utilize your CPU since we are running LLaMA on GpuBackend.auto with CPU fallback. Expect decent speeds depending on your core count.';
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _deviceModel = model;
        _performanceNote = perf;
        _isLoading = false;
      });
    }
  }

  Future<void> _continue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
            : Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeInDown(
                      child: const Icon(Icons.science_outlined, size: 80, color: Color(0xFF6C63FF)),
                    ),
                    const SizedBox(height: 24),
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'Local AI Assistant',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeIn(
                      delay: const Duration(milliseconds: 400),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C28),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 32),
                            const SizedBox(height: 12),
                            Text(
                              'AiDroid runs 100% locally. No data is sent to the cloud. Because you are compiling responses directly on $_deviceModel, here is what you need to know:\n\n$_performanceNote',
                              textAlign: TextAlign.justify,
                              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _continue,
                        child: Text(
                          'I Understand, Let\'s Go',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
