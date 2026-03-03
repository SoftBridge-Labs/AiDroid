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
      backgroundColor: const Color(0xFF0E0E14),
      appBar: AppBar(
        title: const Text('Manage Models'),
        backgroundColor: const Color(0xFF0E0E14),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: chatState.models.length,
        itemBuilder: (context, index) {
          final model = chatState.models[index];
          return _buildModelCard(context, ref, chatState, model);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Custom Model',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () => _showAddDialog(context, ref),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF13131C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Add Custom Model',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Must be a HuggingFace .gguf file URL',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _field(nameCtrl, 'Model Name', Icons.tag, false),
            const SizedBox(height: 14),
            _field(descCtrl, 'Description (optional)', Icons.notes, false),
            const SizedBox(height: 14),
            _field(
              urlCtrl,
              'https://huggingface.co/.../model.gguf',
              Icons.link,
              false,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Add Model',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onPressed: () {
                  final url = urlCtrl.text.trim();
                  final name = nameCtrl.text.trim();
                  if (name.isNotEmpty &&
                      url.isNotEmpty &&
                      url.contains('huggingface.co') &&
                      url.endsWith('.gguf')) {
                    ref
                        .read(chatProvider.notifier)
                        .addCustomModel(name, descCtrl.text.trim(), url);
                    Navigator.pop(ctx);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Enter a valid HuggingFace .gguf URL',
                          style: GoogleFonts.outfit(),
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    bool obscure,
  ) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildModelCard(
    BuildContext context,
    WidgetRef ref,
    ChatState state,
    AiModel model,
  ) {
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
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    model.name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getWeightColor(model.weight).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getWeightColor(model.weight).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    model.weight,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getWeightColor(model.weight),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  model.description,
                  style: GoogleFonts.outfit(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!isDownloaded && !isDownloading)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          ref
                              .read(chatProvider.notifier)
                              .downloadModel(model.id);
                        },
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download'),
                      ),
                    if (isDownloaded)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.2),
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
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
                  LinearProgressIndicator(
                    value: progress,
                    color: const Color(0xFF6C63FF),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getWeightColor(String weight) {
    switch (weight) {
      case 'Light':
        return Colors.greenAccent;
      case 'Medium':
        return Colors.orangeAccent;
      case 'High':
        return Colors.redAccent;
      default:
        return Colors.blueAccent;
    }
  }
}
