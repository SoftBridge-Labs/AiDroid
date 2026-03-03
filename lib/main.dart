import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/app_theme.dart';
import 'features/chat/chat_screen.dart';
import 'features/home/welcome_screen.dart';
import 'package:background_downloader/background_downloader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Permission.notification.request();

  FileDownloader().configureNotification(
    running: const TaskNotification(
      'Downloading AI Model',
      'Download: {progress}%',
    ),
    complete: const TaskNotification(
      'Model is Ready',
      'The AI model has been successfully downloaded.',
    ),
    error: const TaskNotification(
      'Download Failed',
      'Failed to download the model.',
    ),
    paused: const TaskNotification(
      'Download Paused',
      'Your download is currently paused.',
    ),
    progressBar: true,
  );
  final prefs = await SharedPreferences.getInstance();
  final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;

  runApp(ProviderScope(child: AiDroidApp(hasSeenWelcome: hasSeenWelcome)));
}

class AiDroidApp extends StatelessWidget {
  final bool hasSeenWelcome;

  const AiDroidApp({super.key, required this.hasSeenWelcome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AiDroid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: hasSeenWelcome ? const ChatScreen() : const WelcomeScreen(),
    );
  }
}
