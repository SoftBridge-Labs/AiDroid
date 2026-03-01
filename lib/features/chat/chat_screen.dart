import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/chat_provider.dart';
import '../home/model_manager_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(_controller.text.trim());
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
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;
    final isReady = chatState.activeModelStatus == ModelStatus.ready;
    final activeModel = availableModels.firstWhere((m) => m.id == chatState.activeModelId);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E14),
        elevation: 0,
        titleSpacing: 20,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.4), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 8,
                      height: 8,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
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
                    const Icon(Icons.stop_rounded, size: 12, color: Color(0xFF6C63FF)),
                  ],
                ),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white54, size: 22),
            tooltip: 'Manage Models',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelManagerScreen()));
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
                  const Icon(Icons.bolt_rounded, size: 13, color: Colors.greenAccent),
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
                    itemBuilder: (context, index) => _buildMessageBubble(messages[index]),
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
        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
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
              ? const SizedBox(
                  width: 20,
                  height: 14,
                  child: _TypingDots(),
                )
              : Text(
                  message.text,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    height: 1.45,
                    color: message.isUser ? Colors.white : Colors.white.withValues(alpha: 0.9),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(ChatState chatState) {
    final isDownloading = chatState.activeModelStatus == ModelStatus.downloading;
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
            Text(chatState.errorMessage, style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12)),
          ],
          if (!isDownloading) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(chatProvider.notifier).downloadModel(chatState.activeModelId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                textStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
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
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
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
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
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
                    hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: isReady ? (_) => _sendMessage() : null,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isReady
                    ? (chatState.liveStats.isNotEmpty
                        ? () => ref.read(chatProvider.notifier).stopGeneration()
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
}

/// Animated three-dot typing indicator
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
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
            final opacity = (offset < 0.5 ? offset * 2 : (1.0 - offset) * 2).clamp(0.25, 1.0);
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
