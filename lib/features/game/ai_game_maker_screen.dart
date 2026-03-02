import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../providers/chat_provider.dart';

class AiGameMakerScreen extends ConsumerStatefulWidget {
  const AiGameMakerScreen({super.key});

  @override
  ConsumerState<AiGameMakerScreen> createState() => _AiGameMakerScreenState();
}

class _AiGameMakerScreenState extends ConsumerState<AiGameMakerScreen> {
  final _promptController = TextEditingController();
  String _generatedHtml = '';
  String _rawOutput = '';
  bool _isGenerating = false;
  bool _showPreview = false;
  late WebViewController _webController;

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0E0E14));
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateGame() async {
    if (_promptController.text.trim().isEmpty) return;
    final chatState = ref.read(chatProvider);
    if (chatState.activeModelStatus != ModelStatus.ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No model ready. Please download a model first.', style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _rawOutput = '';
      _generatedHtml = '';
      _showPreview = false;
    });

    final systemPrompt = '''You are an expert HTML5 game developer. The user will describe a simple game and you MUST output ONLY a complete, self-contained HTML file with embedded CSS and JavaScript that implements that game. 
Rules:
- Output ONLY raw HTML starting with <!DOCTYPE html> — no markdown, no code fences, no explanation
- The game must be fully functional and playable in a browser
- Use a dark background (#0e0e14) with vibrant neon colors
- Use canvas or DOM elements — keep it simple and fun
- Include a score counter if applicable
- Make controls work on mobile (touch events) AND desktop (keyboard/mouse)''';

    final prompt = '$systemPrompt\n\nCreate this game: ${_promptController.text.trim()}';

    try {
      await for (final chunk in ref.read(chatProvider.notifier).streamPrompt(prompt)) {
        if (mounted) setState(() => _rawOutput += chunk);
      }

      // Extract HTML from output (strip any code fences if model added them)
      String html = _rawOutput;
      final htmlMatch = RegExp(r'<!DOCTYPE html>.*', dotAll: true, caseSensitive: false).firstMatch(html);
      if (htmlMatch != null) {
        html = htmlMatch.group(0)!;
      }
      // Strip trailing ``` if any
      html = html.replaceAll(RegExp(r'```\s*$'), '').trim();

      setState(() {
        _generatedHtml = html;
        _isGenerating = false;
      });

      if (html.isNotEmpty) {
        _webController.loadHtmlString(html);
        setState(() => _showPreview = true);
      }
    } catch (e) {
      setState(() {
        _rawOutput = 'Error generating game: $e';
        _isGenerating = false;
      });
    }
  }

  void _copyHtml() {
    Clipboard.setData(ClipboardData(text: _generatedHtml));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('HTML copied!', style: GoogleFonts.outfit()), backgroundColor: const Color(0xFF6C63FF)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isReady = chatState.activeModelStatus == ModelStatus.ready;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      appBar: AppBar(
        title: Text('AI Game Maker', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0E0E14),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_generatedHtml.isNotEmpty)
            IconButton(icon: const Icon(Icons.copy, color: Colors.white54), onPressed: _copyHtml, tooltip: 'Copy HTML'),
          if (_generatedHtml.isNotEmpty)
            IconButton(
              icon: Icon(_showPreview ? Icons.code : Icons.play_circle_outline, color: const Color(0xFF6C63FF)),
              tooltip: _showPreview ? 'Show Code' : 'Preview Game',
              onPressed: () => setState(() => _showPreview = !_showPreview),
            ),
        ],
      ),
      body: Column(
        children: [
          // Status
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isReady ? const Color(0xFF1A2A1A) : const Color(0xFF2A1A1A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, color: isReady ? Colors.greenAccent : Colors.redAccent, size: 9),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isReady
                        ? '${chatState.models.firstWhere((m) => m.id == chatState.activeModelId).name}'
                        : 'No model ready — download one first',
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Input area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _promptController,
                  maxLines: 3,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Describe your game, e.g. "A snake game where the snake grows when eating apples"',
                    hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFF1C1C28),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF43E97B),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isGenerating || !isReady ? null : _generateGame,
                    icon: _isGenerating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Icon(Icons.gamepad_rounded),
                    label: Text(
                      _isGenerating ? 'Generating game...' : 'Generate Game',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Preview or code output
          if (_isGenerating || _rawOutput.isNotEmpty || _generatedHtml.isNotEmpty)
            Expanded(
              child: _showPreview && _generatedHtml.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                      child: WebViewWidget(controller: _webController),
                    )
                  : Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C28),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _isGenerating && _rawOutput.isEmpty ? 'Generating...' : _rawOutput,
                          style: GoogleFonts.sourceCodePro(color: Colors.cyanAccent, fontSize: 12, height: 1.5),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
