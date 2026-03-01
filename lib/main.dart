import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';
import 'features/chat/chat_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AiDroidApp(),
    ),
  );
}

class AiDroidApp extends StatelessWidget {
  const AiDroidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AiDroid Gallery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ChatScreen(),
    );
  }
}
