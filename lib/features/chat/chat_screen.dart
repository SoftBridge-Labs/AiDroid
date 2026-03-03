import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/chat_provider.dart';
import '../audio/audio_scribe_screen.dart';
import '../home/model_manager_screen.dart';
import '../text/prompt_lab_screen.dart';
import '../vision/ask_image_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _scanTextFromImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      await textRecognizer.close();

      if (recognizedText.text.trim().isNotEmpty) {
        setState(() {
          _controller.text =
              _controller.text +
              (_controller.text.isEmpty ? '' : '\n') +
              recognizedText.text;
        });
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No text found in image.')),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error scanning text: $e')));
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    final success = ref
        .read(chatProvider.notifier)
        .sendMessage(_controller.text.trim());
    if (success) {
      _controller.clear();
      Future.delayed(const Duration(milliseconds: 80), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      if (ref.read(chatProvider).activeModelStatus == ModelStatus.ready &&
          ref.read(chatProvider.notifier).isSessionLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Model engine is loading, please wait a moment...'),
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showSystemInstructionDialog() {
    final systemInstruction = ref.read(chatProvider).systemInstruction;
    final TextEditingController instController = TextEditingController(
      text: systemInstruction,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C28),
          title: Text(
            'System Instruction',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          content: TextField(
            controller: instController,
            style: GoogleFonts.outfit(color: Colors.white),
            maxLines: 5,
            minLines: 2,
            decoration: InputDecoration(
              hintText: 'Enter custom instructions for the AI...',
              hintStyle: GoogleFonts.outfit(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF13131C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
              ),
              onPressed: () {
                ref
                    .read(chatProvider.notifier)
                    .setSystemInstruction(instController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('System instruction updated')),
                );
              },
              child: Text(
                'Save',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;
    final isReady = chatState.activeModelStatus == ModelStatus.ready;
    final activeModel = chatState.models.firstWhere(
      (m) => m.id == chatState.activeModelId,
      orElse: () => chatState.models.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      drawer: Drawer(
        backgroundColor: const Color(0xFF13131C),
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.android,
                      size: 48,
                      color: Color(0xFF6C63FF),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AiDroid',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerSection('AI Features'),
                  _buildDrawerItem(
                    Icons.image_search,
                    'Vision Assistant',
                    const Color(0xFF00C9FF),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AskImageScreen()),
                    ),
                  ),

                  _buildDrawerItem(
                    Icons.science_outlined,
                    'Prompt Lab',
                    const Color(0xFFFFB75E),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PromptLabScreen(),
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                    Icons.mic_none_rounded,
                    'Audio Scribe',
                    const Color(0xFFF093FB),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AudioScribeScreen(),
                      ),
                    ),
                  ),

                  const Divider(color: Colors.white12, height: 32),

                  _buildDrawerSection('Settings'),
                  _buildDrawerItem(
                    Icons.psychology_outlined,
                    'System Instruction',
                    Colors.amberAccent,
                    _showSystemInstructionDialog,
                  ),

                  const Divider(color: Colors.white12, height: 32),

                  _buildDrawerSection('Community'),
                  _buildDrawerItem(
                    Icons.favorite,
                    'Sponsor Project',
                    Colors.pinkAccent,
                    () => _launchUrl(
                      'https://github.com/sponsors/PrakharDoneria',
                    ),
                  ),
                  _buildDrawerItem(
                    Icons.star_outline_rounded,
                    'Star on GitHub',
                    Colors.amberAccent,
                    () => _launchUrl(
                      'https://github.com/SoftBridge-Labs/AiDroid',
                    ),
                  ),
                  _buildDrawerItem(
                    Icons.code_rounded,
                    'Source Code',
                    Colors.greenAccent,
                    () => _launchUrl(
                      'https://github.com/SoftBridge-Labs/AiDroid',
                    ),
                  ),
                  _buildDrawerItem(
                    Icons.info_outline,
                    'About',
                    Colors.blueAccent,
                    () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'AiDroid',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© SoftBridge Labs',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E14),
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AiDroid',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              activeModel.name,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: isReady ? const Color(0xFF6C63FF) : Colors.white38,
              ),
            ),
          ],
        ),
        actions: [
          // CPU usage chip (always visible when available)
          if (chatState.cpuUsage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  chatState.cpuUsage,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
          // Live tok/s badge + stop button during generation
          if (chatState.liveStats.isNotEmpty) ...[
            GestureDetector(
              onTap: () => ref.read(chatProvider.notifier).stopGeneration(),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 8,
                      height: 8,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chatState.liveStats,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF6C63FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.stop_rounded,
                      size: 12,
                      color: Color(0xFF6C63FF),
                    ),
                  ],
                ),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              color: Colors.white54,
              size: 22,
            ),
            tooltip: 'Manage Models',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ModelManagerScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Thin divider below appbar
          Container(height: 0.5, color: Colors.white12),

          // Model not ready banner
          if (chatState.activeModelStatus != ModelStatus.ready)
            _buildStatusBanner(chatState),

          // Stats row (after generation done)
          if (chatState.usageStats.isNotEmpty && chatState.liveStats.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: const Color(0xFF13131C),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 13,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    chatState.usageStats,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.greenAccent.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(isReady)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessageBubble(messages[index]),
                  ),
          ),

          // Input + copyright
          _buildInputArea(chatState),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isReady) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 12),
          Text(
            isReady ? 'Start a conversation' : 'Download a model to begin',
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return FadeIn(
      duration: const Duration(milliseconds: 200),
      child: Align(
        alignment: message.isUser
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: message.text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Message copied to clipboard'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            decoration: BoxDecoration(
              color: message.isUser
                  ? const Color(0xFF6C63FF)
                  : const Color(0xFF1C1C28),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                bottomRight: Radius.circular(message.isUser ? 4 : 18),
              ),
            ),
            child: message.text.isEmpty
                ? const SizedBox(width: 20, height: 14, child: _TypingDots())
                : message.isUser
                ? Text(
                    message.text,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      height: 1.45,
                      color: Colors.white,
                    ),
                  )
                : MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.outfit(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      code: GoogleFonts.sourceCodePro(
                        fontSize: 13,
                        color: Colors.cyanAccent,
                        backgroundColor: Colors.black45,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: const Color(0xFF0E0E14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      h1: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      h2: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      h3: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      strong: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      em: const TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                      listBullet: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(ChatState chatState) {
    final isDownloading =
        chatState.activeModelStatus == ModelStatus.downloading;
    final isError = chatState.activeModelStatus == ModelStatus.error;

    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError
              ? Colors.redAccent.withValues(alpha: 0.4)
              : const Color(0xFF6C63FF).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.download_rounded,
                color: isError ? Colors.redAccent : const Color(0xFF6C63FF),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isError ? 'Model Error' : 'Model not downloaded',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (isError) ...[
            const SizedBox(height: 6),
            Text(
              chatState.errorMessage,
              style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12),
            ),
          ],
          if (!isDownloading) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref
                  .read(chatProvider.notifier)
                  .downloadModel(chatState.activeModelId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                textStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Download Model'),
            ),
          ] else ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: chatState.activeDownloadProgress,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF6C63FF),
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(chatState.activeDownloadProgress * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatState chatState) {
    final isReady = chatState.activeModelStatus == ModelStatus.ready;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF13131C),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
                  enabled: isReady,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: isReady ? 'Message...' : 'Download a model first',
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.white24,
                      fontSize: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    isDense: true,
                    suffixIcon: isReady
                        ? IconButton(
                            icon: const Icon(
                              Icons.document_scanner_outlined,
                              color: Colors.white54,
                            ),
                            tooltip: 'Scan text from image',
                            onPressed: _scanTextFromImage,
                          )
                        : null,
                  ),
                  onSubmitted: isReady ? (_) => _sendMessage() : null,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isReady
                    ? (chatState.liveStats.isNotEmpty
                          ? () =>
                                ref.read(chatProvider.notifier).stopGeneration()
                          : _sendMessage)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isReady
                        ? (chatState.liveStats.isNotEmpty
                              ? Colors.redAccent.withValues(alpha: 0.85)
                              : const Color(0xFF6C63FF))
                        : Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    chatState.liveStats.isNotEmpty
                        ? Icons.stop_rounded
                        : Icons.arrow_upward_rounded,
                    color: isReady ? Colors.white : Colors.white24,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Copyright footer
        Container(
          color: const Color(0xFF13131C),
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            '© SoftBridge Labs',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.07),
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          color: Colors.white38,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color.withOpacity(0.8), size: 22),
      title: Text(
        title,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

/// Animated three-dot typing indicator
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context2, child2) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final opacity = (offset < 0.5 ? offset * 2 : (1.0 - offset) * 2)
                .clamp(0.25, 1.0);
            return Container(
              margin: const EdgeInsets.only(right: 3),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}
