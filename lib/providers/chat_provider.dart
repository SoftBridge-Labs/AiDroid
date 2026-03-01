import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:llamadart/llamadart.dart';

enum ModelStatus { notDownloaded, downloading, ready, error }

class AiModel {
  final String id;
  final String name;
  final String description;
  final String url;
  final String fileName;

  const AiModel({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.fileName,
  });
}

const List<AiModel> availableModels = [
  AiModel(
    id: 'tinyllama_q2',
    name: 'TinyLlama 1.1B Chat (Q2_K)',
    description: 'Lightweight and efficient. Best for low memory devices (~480MB).',
    url: 'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q2_K.gguf',
    fileName: 'tinyllama_q2.gguf',
  ),
  AiModel(
    id: 'deepseek_coder_q2',
    name: 'Deepseek Coder 1.3B (Q2_K)',
    description: 'Great for coding tasks, very lightweight (~580MB).',
    url: 'https://huggingface.co/TheBloke/deepseek-coder-1.3b-instruct-GGUF/resolve/main/deepseek-coder-1.3b-instruct.Q2_K.gguf',
    fileName: 'deepseek_coder_q2.gguf',
  ),
  AiModel(
    id: 'phi2_q2',
    name: 'Phi-2 (Q2_K)',
    description: 'Better reasoning, slower (~1.1GB).',
    url: 'https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q2_K.gguf',
    fileName: 'phi2_q2.gguf',
  ),
];

class ChatState {
  final List<Message> messages;
  final String activeModelId;
  final Map<String, ModelStatus> modelStatuses;
  final Map<String, double> downloadProgresses;
  final String errorMessage;
  final String usageStats;
  /// Live token/s during generation; empty when idle.
  final String liveStats;
  /// CPU usage string e.g. "CPU 34%"
  final String cpuUsage;

  ChatState({
    required this.messages,
    this.activeModelId = 'tinyllama_q2',
    this.modelStatuses = const {},
    this.downloadProgresses = const {},
    this.errorMessage = '',
    this.usageStats = '',
    this.liveStats = '',
    this.cpuUsage = '',
  });

  ModelStatus get activeModelStatus => modelStatuses[activeModelId] ?? ModelStatus.notDownloaded;
  double get activeDownloadProgress => downloadProgresses[activeModelId] ?? 0.0;

  ChatState copyWith({
    List<Message>? messages,
    String? activeModelId,
    Map<String, ModelStatus>? modelStatuses,
    Map<String, double>? downloadProgresses,
    String? errorMessage,
    String? usageStats,
    String? liveStats,
    String? cpuUsage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      activeModelId: activeModelId ?? this.activeModelId,
      modelStatuses: modelStatuses ?? this.modelStatuses,
      downloadProgresses: downloadProgresses ?? this.downloadProgresses,
      errorMessage: errorMessage ?? this.errorMessage,
      usageStats: usageStats ?? this.usageStats,
      liveStats: liveStats ?? this.liveStats,
      cpuUsage: cpuUsage ?? this.cpuUsage,
    );
  }
}

class Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({required this.id, required this.text, required this.isUser, required this.timestamp});
  
  Message copyWith({String? id, String? text, bool? isUser, DateTime? timestamp}) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  final Dio _dio = Dio();
  late LlamaEngine _engine;
  ChatSession? _session;
  bool _isGenerating = false;
  bool _stopRequested = false;
  Timer? _cpuTimer;
  List<int>? _lastCpuTimes;

  @override
  ChatState build() {
    _engine = LlamaEngine(LlamaBackend());
    ref.onDispose(() {
      _engine.dispose();
      _cpuTimer?.cancel();
    });
    _checkModelsExist();
    _startCpuMonitor();
    return ChatState(
      messages: [],
      activeModelId: availableModels.first.id,
      modelStatuses: {for (var m in availableModels) m.id: ModelStatus.notDownloaded},
      downloadProgresses: {for (var m in availableModels) m.id: 0.0},
    );
  }

  Future<void> _checkModelsExist() async {
    final dir = await getApplicationDocumentsDirectory();
    final Map<String, ModelStatus> statuses = Map.from(state.modelStatuses);
    for (var model in availableModels) {
      final file = File('${dir.path}/${model.fileName}');
      statuses[model.id] = await file.exists() ? ModelStatus.ready : ModelStatus.notDownloaded;
    }
    state = state.copyWith(modelStatuses: statuses);
    if (statuses[state.activeModelId] == ModelStatus.ready) {
      final activeModel = availableModels.firstWhere((m) => m.id == state.activeModelId);
      await _initModel('${(await getApplicationDocumentsDirectory()).path}/${activeModel.fileName}', state.activeModelId);
    }
  }

  Future<void> setActiveModel(String modelId) async {
    if (state.activeModelId == modelId || _isGenerating) return;
    state = state.copyWith(activeModelId: modelId, errorMessage: '', usageStats: '', liveStats: '');
    if (state.modelStatuses[modelId] == ModelStatus.ready) {
      final model = availableModels.firstWhere((m) => m.id == modelId);
      final dir = await getApplicationDocumentsDirectory();
      await _initModel('${dir.path}/${model.fileName}', modelId);
    } else {
      _session = null;
    }
  }

  Future<void> _initModel(String path, String modelId) async {
    try {
      _engine.dispose();
      _engine = LlamaEngine(LlamaBackend());
      await _engine.loadModel(path, modelParams: const ModelParams(gpuLayers: 0, preferredBackend: GpuBackend.cpu));
      // Few-shot system prompt so TinyLlama actually follows the behaviour
      // instead of explaining or demonstrating it.
      _session = ChatSession(
        _engine,
        systemPrompt:
            "<|system|>\n"
            "A chat between a curious user and an AI assistant. "
            "The assistant gives SHORT, direct answers. "
            "Examples:\n"
            "User: hi\nAssistant: Hey! How can I help you?\n"
            "User: how are you?\nAssistant: Doing great, thanks! What's up?\n"
            "User: what is 2+2?\nAssistant: 4.\n"
            "User: explain gravity\nAssistant: Gravity is the force that attracts objects with mass toward each other. On Earth it pulls things downward at 9.8 m/s².\n"
            "</s>",
      );
      final statuses = Map<String, ModelStatus>.from(state.modelStatuses)..[modelId] = ModelStatus.ready;
      state = state.copyWith(modelStatuses: statuses);
    } catch (e) {
      try { await File(path).delete(); } catch (_) {}
      final statuses = Map<String, ModelStatus>.from(state.modelStatuses)..[modelId] = ModelStatus.error;
      state = state.copyWith(modelStatuses: statuses, errorMessage: "Failed to load model. File may be corrupted — please re-download. ($e)");
      _session = null;
    }
  }

  Future<void> downloadModel(String modelId) async {
    if (state.modelStatuses[modelId] == ModelStatus.downloading) return;
    final statuses = Map<String, ModelStatus>.from(state.modelStatuses)..[modelId] = ModelStatus.downloading;
    final progresses = Map<String, double>.from(state.downloadProgresses)..[modelId] = 0.0;
    state = state.copyWith(modelStatuses: statuses, downloadProgresses: progresses);
    try {
      final model = availableModels.firstWhere((m) => m.id == modelId);
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${model.fileName}';
      await _dio.download(model.url, savePath, onReceiveProgress: (received, total) {
        if (total != -1) {
          final p = Map<String, double>.from(state.downloadProgresses)..[modelId] = received / total;
          state = state.copyWith(downloadProgresses: p);
        }
      });
      final finalStatuses = Map<String, ModelStatus>.from(state.modelStatuses)..[modelId] = ModelStatus.ready;
      state = state.copyWith(modelStatuses: finalStatuses);
      if (state.activeModelId == modelId) await _initModel(savePath, modelId);
    } catch (e) {
      final s = Map<String, ModelStatus>.from(state.modelStatuses)..[modelId] = ModelStatus.error;
      state = state.copyWith(modelStatuses: s, errorMessage: "Download failed: $e");
    }
  }

  Future<void> deleteModel(String modelId) async {
    final model = availableModels.firstWhere((m) => m.id == modelId);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${model.fileName}');
    if (await file.exists()) await file.delete();
    final statuses = Map<String, ModelStatus>.from(state.modelStatuses)..[modelId] = ModelStatus.notDownloaded;
    state = state.copyWith(modelStatuses: statuses);
    if (state.activeModelId == modelId) _session = null;
  }

  void stopGeneration() {
    if (_isGenerating) _stopRequested = true;
  }

  void sendMessage(String text) async {
    if (state.activeModelStatus != ModelStatus.ready || _isGenerating || _session == null) return;

    _stopRequested = false;
    final userMessage = Message(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text, isUser: true, timestamp: DateTime.now());
    final botMessageId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    final initialBotMessage = Message(id: botMessageId, text: '', isUser: false, timestamp: DateTime.now());

    state = state.copyWith(
      messages: [...state.messages, userMessage, initialBotMessage],
      liveStats: '0.0 tok/s',
      usageStats: '',
    );

    _isGenerating = true;
    bool stopped = false;

    try {
      String currentText = '';
      final startTime = DateTime.now();
      int tokenCount = 0;

      await for (final chunk in _session!.create([LlamaTextContent(text)])) {
        if (_stopRequested) {
          stopped = true;
          break;
        }
        final content = chunk.choices.first.delta.content;
        if (content != null) {
          currentText += content;
          tokenCount++;
          final elapsed = DateTime.now().difference(startTime).inMilliseconds / 1000.0;
          final tps = elapsed > 0 ? tokenCount / elapsed : 0.0;
          final messages = state.messages.map((m) => m.id == botMessageId ? m.copyWith(text: currentText) : m).toList();
          state = state.copyWith(messages: messages, liveStats: '${tps.toStringAsFixed(1)} tok/s');
        }
      }

      final diffSeconds = DateTime.now().difference(startTime).inMilliseconds / 1000.0;
      final tps = diffSeconds > 0 ? (tokenCount / diffSeconds).toStringAsFixed(1) : '0.0';
      state = state.copyWith(
        usageStats: stopped
            ? '$tps tok/s • $tokenCount tokens • stopped'
            : '$tps tok/s • $tokenCount tokens • ${diffSeconds.toStringAsFixed(1)}s',
        liveStats: '',
      );
    } catch (e) {
      final messages = state.messages.map((m) => m.id == botMessageId ? m.copyWith(text: 'Error: $e') : m).toList();
      state = state.copyWith(messages: messages, liveStats: '', usageStats: 'Inference error');
    } finally {
      _isGenerating = false;
      _stopRequested = false;
    }
  }

  // ── CPU monitoring (reads /proc/stat, Android / Linux only) ────────────────
  void _startCpuMonitor() {
    _cpuTimer = Timer.periodic(const Duration(seconds: 2), (_) => _readCpuUsage());
  }

  Future<void> _readCpuUsage() async {
    try {
      final lines = await File('/proc/stat').readAsLines();
      final cpuLine = lines.firstWhere((l) => l.startsWith('cpu '), orElse: () => '');
      if (cpuLine.isEmpty) return;

      final parts = cpuLine.split(RegExp(r'\s+'));
      // user, nice, system, idle, iowait, irq, softirq
      final times = parts.skip(1).take(7).map(int.parse).toList();
      final idle = times[3] + times[4]; // idle + iowait
      final total = times.fold(0, (a, b) => a + b);

      if (_lastCpuTimes != null) {
        final prevTotal = _lastCpuTimes!.fold(0, (a, b) => a + b);
        final prevIdle = _lastCpuTimes![3] + _lastCpuTimes![4];
        final dTotal = total - prevTotal;
        final dIdle = idle - prevIdle;
        final usage = dTotal > 0 ? ((dTotal - dIdle) / dTotal * 100).round() : 0;
        state = state.copyWith(cpuUsage: 'CPU $usage%');
      }
      _lastCpuTimes = times;
    } catch (_) {
      // /proc/stat not available on this platform — silently ignore
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
