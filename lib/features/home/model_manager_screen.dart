import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/chat_provider.dart';

class ModelManagerScreen extends ConsumerWidget {
  const ModelManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Models')),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: availableModels.length,
        itemBuilder: (context, index) {
          final model = availableModels[index];
          return _buildModelCard(context, ref, chatState, model);
        },
      ),
    );
  }

  Widget _buildModelCard(BuildContext context, WidgetRef ref, ChatState state, AiModel model) {
    final status = state.modelStatuses[model.id] ?? ModelStatus.notDownloaded;
    final progress = state.downloadProgresses[model.id] ?? 0.0;
    final isActive = state.activeModelId == model.id;
    final isDownloaded = status == ModelStatus.ready;
    final isDownloading = status == ModelStatus.downloading;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isActive ? Colors.white.withOpacity(0.15) : Colors.white10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isActive ? const Color(0xFF6C63FF) : Colors.transparent, 
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            value: model.id,
            groupValue: state.activeModelId,
            onChanged: (val) {
              if (val != null) {
                ref.read(chatProvider.notifier).setActiveModel(val);
              }
            },
            title: Text(model.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(model.description, style: GoogleFonts.outfit(color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!isDownloaded && !isDownloading)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFF6C63FF),
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                           textStyle: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          ref.read(chatProvider.notifier).downloadModel(model.id);
                        },
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download'),
                      ),
                    if (isDownloaded)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.redAccent.withOpacity(0.2),
                           foregroundColor: Colors.redAccent,
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                           textStyle: const TextStyle(fontSize: 12),
                           elevation: 0,
                        ),
                        onPressed: () {
                          ref.read(chatProvider.notifier).deleteModel(model.id);
                        },
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Delete'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (isDownloading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  LinearProgressIndicator(value: progress, color: const Color(0xFF6C63FF)),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).toStringAsFixed(1)}%', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
