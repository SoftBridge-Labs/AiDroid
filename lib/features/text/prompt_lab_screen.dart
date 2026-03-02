import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/chat_provider.dart';

class PromptLabScreen extends ConsumerStatefulWidget {
  const PromptLabScreen({super.key});

  @override
  ConsumerState<PromptLabScreen> createState() => _PromptLabScreenState();
}

class _PromptLabScreenState extends ConsumerState<PromptLabScreen> {
  final _inputController = TextEditingController();
  String _result = '';
  bool _isRunning = false;
  String _selectedTask = 'Summarize';

  final List<Map<String, String>> _tasks = [
    {'label': 'Summarize', 'prefix': 'Summarize the following text concisely:\n\n'},
    {'label': 'Rewrite', 'prefix': 'Rewrite the following text more clearly and professionally:\n\n'},
    {'label': 'Generate Code', 'prefix': 'Write clean, well-commented code for the following requirement:\n\n'},
    {'label': 'Brainstorm', 'prefix': 'Brainstorm creative ideas for the following topic:\n\n'},
    {'label': 'Explain', 'prefix': 'Explain the following in simple, clear terms:\n\n'},
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _runTask() async {
    if (_inputController.text.trim().isEmpty) return;
    final chatState = ref.read(chatProvider);
    if (chatState.activeModelStatus != ModelStatus.ready) {
      setState(() => _result = '⚠ No model is ready. Please download a model first.');
      return;
    }

    final task = _tasks.firstWhere((t) => t['label'] == _selectedTask);
    final prompt = task['prefix']! + _inputController.text.trim();

    setState(() {
      _isRunning = true;
      _result = '';
    });

    try {
      await for (final chunk in ref.read(chatProvider.notifier).streamPrompt(prompt)) {
        if (mounted) setState(() => _result += chunk);
      }
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isReady = chatState.activeModelStatus == ModelStatus.ready;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      appBar: AppBar(
        title: Text('Prompt Lab', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0E0E14),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Model status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isReady ? const Color(0xFF1A2A1A) : const Color(0xFF2A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, color: isReady ? Colors.greenAccent : Colors.redAccent, size: 10),
                  const SizedBox(width: 10),
                  Text(
                    isReady ? 'Model ready: ${chatState.models.firstWhere((m) => m.id == chatState.activeModelId).name}' : 'No model ready — go download one first',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Task chips
            Text('Task', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _tasks.map((task) {
                  final selected = _selectedTask == task['label'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTask = task['label']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? const Color(0xFF6C63FF) : Colors.white24, width: 1),
                        ),
                        child: Text(task['label']!, style: GoogleFonts.outfit(color: Colors.white, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Input
            Text('Input', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            TextField(
              controller: _inputController,
              maxLines: 6,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Enter your text or prompt here...',
                hintStyle: GoogleFonts.outfit(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1C1C28),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),

            // Run button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isRunning || !isReady ? null : _runTask,
                icon: _isRunning
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(
                  _isRunning ? 'Processing...' : 'Run with Local AI',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),

            // Output
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Output', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                    onPressed: () => Clipboard.setData(ClipboardData(text: _result)),
                    tooltip: 'Copy',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C28),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: MarkdownBody(
                  data: _result,
                  styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.6),
                    code: GoogleFonts.sourceCodePro(color: Colors.cyanAccent, fontSize: 13, backgroundColor: Colors.black38),
                    codeblockDecoration: BoxDecoration(color: const Color(0xFF0E0E14), borderRadius: BorderRadius.circular(10)),
                    h1: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    h2: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    h3: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 15),
                    strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    em: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                    listBullet: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
