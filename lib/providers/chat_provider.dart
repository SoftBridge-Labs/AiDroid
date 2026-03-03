import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:llamadart/llamadart.dart';

enum ModelStatus { notDownloaded, downloading, ready, error }

class AiModel {
  final String id;
  final String name;
  final String description;
  final String url;
  final String fileName;

  final String weight; // 'Light', 'Medium', 'High'

  const AiModel({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.fileName,
    required this.weight,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'url': url,
    'fileName': fileName,
    'weight': weight,
  };

  factory AiModel.fromJson(Map<String, dynamic> json) => AiModel(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    url: json['url'],
    fileName: json['fileName'],
    weight: json['weight'] ?? 'Medium',
  );
}

const List<AiModel> defaultModels = [
  AiModel(
    id: 'tinyllama_q2',
    name: 'TinyLlama 1.1B Chat (Q2_K)',
    description: 'Fast and efficient. Best for low memory devices (~480MB).',
    url: 'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q2_K.gguf',
    fileName: 'tinyllama_q2.gguf',
    weight: 'Light',
  ),
  AiModel(
    id: 'deepseek_coder_q2',
    name: 'Deepseek Coder 1.3B (Q2_K)',
    description: 'Great for coding tasks, very lightweight (~580MB).',
    url: 'https://huggingface.co/TheBloke/deepseek-coder-1.3b-instruct-GGUF/resolve/main/deepseek-coder-1.3b-instruct.Q2_K.gguf',
    fileName: 'deepseek_coder_q2.gguf',
    weight: 'Light',
  ),
  AiModel(
    id: 'phi2_q2',
    name: 'Phi-2 (Q2_K)',
    description: 'Better reasoning, moderate speed (~1.1GB).',
    url: 'https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q2_K.gguf',
    fileName: 'phi2_q2.gguf',
    weight: 'Medium',
  ),
  AiModel(
    id: 'orca_mini_3b_q2',
    name: 'Orca Mini 3B (Q2_K)',
    description: 'Fast and lightweight reasoning model (~1.4GB).',
    url: 'https://huggingface.co/TheBloke/orca_mini_3B-GGUF/resolve/main/orca_mini_3b.q2_K.gguf',
    fileName: 'orca_mini_3b_q2.gguf',
    weight: 'Medium',
  ),
  AiModel(
    id: 'mistral_7b_q2',
    name: 'Mistral 7B Instruct (Q2_K)',
    description: 'Excellent instruction following and reasoning from Mistral AI (~3.0GB).',
    url: 'https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.1-GGUF/resolve/main/mistral-7b-instruct-v0.1.Q2_K.gguf',
    fileName: 'mistral_7b_q2.gguf',
    weight: 'High',
  ),
  AiModel(
    id: 'openhermes_2_5_q2',
    name: 'OpenHermes 2.5 Mistral 7B (Q2_K)',
    description: 'Highly capable model fine-tuned on diverse datasets (~3.0GB).',
    url: 'https://huggingface.co/TheBloke/OpenHermes-2.5-Mistral-7B-GGUF/resolve/main/openhermes-2.5-mistral-7b.Q2_K.gguf',
    fileName: 'openhermes_2_5_q2.gguf',
    weight: 'High',
  ),
];

class ChatState {
  final List<Message> messages;
  final List<AiModel> models;
  final String activeModelId;
  final Map<String, ModelStatus> modelStatuses;
  final Map<String, double> downloadProgresses;
  final String errorMessage;
  final String usageStats;
  /// Live token/s during generation; empty when idle.
  final String liveStats;
  /// CPU usage string e.g. "CPU 34%"
  final String cpuUsage;
  final String systemInstruction;

  ChatState({
    required this.messages,
    this.models = defaultModels,
    this.activeModelId = 'tinyllama_q2',
    this.modelStatuses = const {},
    this.downloadProgresses = const {},
    this.errorMessage = '',
    this.usageStats = '',
    this.liveStats = '',
    this.cpuUsage = '',
    this.systemInstruction = '',
  });

  ModelStatus get activeModelStatus => modelStatuses[activeModelId] ?? ModelStatus.notDownloaded;
  double get activeDownloadProgress => downloadProgresses[activeModelId] ?? 0.0;

  ChatState copyWith({
    List<Message>? messages,
    List<AiModel>? models,
    String? activeModelId,
    Map<String, ModelStatus>? modelStatuses,
    Map<String, double>? downloadProgresses,
    String? errorMessage,
    String? usageStats,
    String? liveStats,
    String? cpuUsage,
    String? systemInstruction,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      models: models ?? this.models,
      activeModelId: activeModelId ?? this.activeModelId,
      modelStatuses: modelStatuses ?? this.modelStatuses,
      downloadProgresses: downloadProgresses ?? this.downloadProgresses,
      errorMessage: errorMessage ?? this.errorMessage,
      usageStats: usageStats ?? this.usageStats,
      liveStats: liveStats ?? this.liveStats,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      systemInstruction: systemInstruction ?? this.systemInstruction,
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
  late LlamaEngine _engine;
  ChatSession? _session;
  bool _isGenerating = false;
  bool _stopRequested = false;
  Timer? _cpuTimer;
  List<int>? _lastCpuTimes;
  
  bool get isGenerating => _isGenerating;
  bool get isSessionLoading => _session == null && state.activeModelStatus == ModelStatus.ready;

  @override
  ChatState build() {
    _engine = LlamaEngine(LlamaBackend());
    ref.onDispose(() {
      _engine.dispose();
      _cpuTimer?.cancel();
    });
    // Sync init the state
    final initialModels = defaultModels;
    _startCpuMonitor();
    
    // Async load from disk
    Future.microtask(() => _initData());
    
    return ChatState(
      messages: [],
      models: initialModels,
      activeModelId: initialModels.first.id,
      modelStatuses: {for (var m in initialModels) m.id: ModelStatus.notDownloaded},
      downloadProgresses: {for (var m in initialModels) m.id: 0.0},
      systemInstruction: '',
    );
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    List<AiModel> loadedModels = List.from(defaultModels);
    
    final customModelsJson = prefs.getString('custom_models');
    if (customModelsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(customModelsJson);
        for (var m in decoded) {
          loadedModels.add(AiModel.fromJson(m));
        }
      } catch (e) {
        // failed to parse customs
      }
    }

    final savedActiveModelId = prefs.getString('active_model_id') ?? defaultModels.first.id;
    final activeId = loadedModels.any((m) => m.id == savedActiveModelId) 
        ? savedActiveModelId 
        : defaultModels.first.id;

    final savedSystemInstruction = prefs.getString('system_instruction') ?? 
        'You are a helpful AI assistant. Always respond concisely and politely. For short greetings like "hi", "hello", or "how are you", respond with a friendly but brief greeting. Maintain a conversational and intelligent tone.';

    final dir = await getApplicationDocumentsDirectory();
    final statuses = Map<String, ModelStatus>.from(state.modelStatuses);
    final progresses = Map<String, double>.from(state.downloadProgresses);

    for (var model in loadedModels) {
      final file = File('${dir.path}/${model.fileName}');
      statuses[model.id] = await file.exists() ? ModelStatus.ready : ModelStatus.notDownloaded;
      progresses[model.id] = 0.0;
    }

    state = state.copyWith(
      models: loadedModels,
      activeModelId: activeId,
      modelStatuses: statuses,
      downloadProgresses: progresses,
      systemInstruction: savedSystemInstruction,
    );

    if (statuses[activeId] == ModelStatus.ready) {
      final activeModel = loadedModels.firstWhere((m) => m.id == activeId);
      await _initModel('${dir.path}/${activeModel.fileName}', activeId);
    }
  }

  Future<void> setSystemInstruction(String instruction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('system_instruction', instruction);
    state = state.copyWith(systemInstruction: instruction);
    
    // Recreate session with new instruction if model is ready
    if (state.activeModelStatus == ModelStatus.ready && _session != null) {
      _session = ChatSession(_engine, systemPrompt: instruction);
    }
  }

  Future<void> addCustomModel(String name, String description, String url) async {
    final prefs = await SharedPreferences.getInstance();
    String newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    String fileName = '$newId.gguf';
    final model = AiModel(
      id: newId,
      name: name,
      description: description,
      url: url,
      fileName: fileName,
      weight: 'Custom',
    );
    final newModels = [...state.models, model];
    
    final customModels = newModels.where((m) => !defaultModels.any((dm) => dm.id == m.id)).toList();
    await prefs.setString('custom_models', jsonEncode(customModels.map((m) => m.toJson()).toList()));
    
    final statuses = Map<String, ModelStatus>.from(state.modelStatuses)..[newId] = ModelStatus.notDownloaded;
    final progresses = Map<String, double>.from(state.downloadProgresses)..[newId] = 0.0;
    
    state = state.copyWith(models: newModels, modelStatuses: statuses, downloadProgresses: progresses);
  }

  Future<void> setActiveModel(String modelId) async {
    if (state.activeModelId == modelId || _isGenerating) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_model_id', modelId);
    
    state = state.copyWith(activeModelId: modelId, errorMessage: '', usageStats: '', liveStats: '');
    if (state.modelStatuses[modelId] == ModelStatus.ready) {
      final model = state.models.firstWhere((m) => m.id == modelId);
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
      
      // Optimization: Fine-tune context and hardware usage
      await _engine.loadModel(
        path,
        modelParams: ModelParams(
          // Metal/Vulkan work great on Apple devices and desktops, but Vulkan on Android 
          // often causes OOM or driver crashes when loading models. Default to CPU for Android.
          gpuLayers: Platform.isAndroid ? 0 : 99, 
          preferredBackend: Platform.isAndroid ? GpuBackend.cpu : GpuBackend.auto,
          contextSize: 1024, // Smaller context for significantly faster prompt processing on mobile
          batchSize: 512, // Standard batch size
          numberOfThreads: Platform.numberOfProcessors > 4 ? 4 : Platform.numberOfProcessors, // Don't use all cores to avoid heat/throttling
        ),
      );
      
      String sysPrompt = state.systemInstruction;

      _session = ChatSession(_engine, systemPrompt: sysPrompt);

      final statuses = Map<String, ModelStatus>.from(state.modelStatuses)..[modelId] = ModelStatus.ready;
      state = state.copyWith(modelStatuses: statuses);
    } catch (e) {
      try { await File(path).delete(); } catch (_) {}
      final statuses = Map<String, ModelStatus>.from(state.modelStatuses)..[modelId] = ModelStatus.error;
      state = state.copyWith(modelStatuses: statuses, errorMessage: "Failed to load model. File may be corrupted — please re-download. ($e)");
    }
  }

  Future<void> downloadModel(String modelId) async {
    if (state.modelStatuses[modelId] == ModelStatus.downloading) return;
    final statuses = Map<String, ModelStatus>.from(state.modelStatuses)..[modelId] = ModelStatus.downloading;
    final progresses = Map<String, double>.from(state.downloadProgresses)..[modelId] = 0.0;
    state = state.copyWith(modelStatuses: statuses, downloadProgresses: progresses);
    try {
      final model = state.models.firstWhere((m) => m.id == modelId);
      final task = DownloadTask(
        url: model.url,
        filename: model.fileName,
        baseDirectory: BaseDirectory.applicationDocuments,
        updates: Updates.statusAndProgress,
        retries: 3,
        allowPause: true,
      );

      await FileDownloader().download(
        task,
        onProgress: (progress) {
          if (progress >= 0.0) {
            final p = Map<String, double>.from(state.downloadProgresses)..[modelId] = progress.clamp(0.0, 1.0);
            state = state.copyWith(downloadProgresses: p);
          }
        },
        onStatus: (status) async {
          if (status == TaskStatus.complete) {
            // Use task.filePath() — the single source of truth for where the file was saved
            final savedPath = await task.filePath();
            final finalStatuses = Map<String, ModelStatus>.from(state.modelStatuses)..[modelId] = ModelStatus.ready;
            state = state.copyWith(modelStatuses: finalStatuses);
            if (state.activeModelId == modelId) await _initModel(savedPath, modelId);
          } else if (status == TaskStatus.failed || status == TaskStatus.canceled) {
            final s = Map<String, ModelStatus>.from(state.modelStatuses)..[modelId] = ModelStatus.error;
            state = state.copyWith(modelStatuses: s, errorMessage: 'Download failed or was canceled. Please try again.');
          }
        },
      );
    } catch (e) {
      final s = Map<String, ModelStatus>.from(state.modelStatuses)..[modelId] = ModelStatus.error;
      state = state.copyWith(modelStatuses: s, errorMessage: "Download failed: $e");
    }
  }

  Future<void> deleteModel(String modelId) async {
    final model = state.models.firstWhere((m) => m.id == modelId);
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

  /// Streams a raw prompt completion; used by Prompt Lab, Game Maker, etc.
  /// Creates a fresh ChatSession so no context bleeds into chat history.
  Stream<String> streamPrompt(String prompt) async* {
    if (state.activeModelStatus != ModelStatus.ready) return;
    final session = ChatSession(_engine, systemPrompt: '');
    await for (final chunk in session.create([LlamaTextContent(prompt)])) {
      final content = chunk.choices.first.delta.content;
      if (content != null && content.isNotEmpty) yield content;
    }
  }

  bool sendMessage(String text) {
    if (state.activeModelStatus != ModelStatus.ready || _isGenerating || _session == null) return false;

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
    _runGeneration(text, botMessageId);
    return true;
  }

  Future<void> _runGeneration(String text, String botMessageId) async {
    bool stopped = false;

    try {
      String currentText = '';
      final startTime = DateTime.now();
      int tokenCount = 0;

      // Use the persistent ChatSession for memory history
      await for (final chunk in _session!.create([LlamaTextContent(text)])) {
        if (_stopRequested) {
          stopped = true;
          break;
        }
        final content = chunk.choices.first.delta.content;
        if (content != null && content.isNotEmpty) {
          currentText += content;
          tokenCount++;
          
          // Optimization: Update state only every few tokens or at the end to maximize generation speed
          if (tokenCount % 3 == 0 || chunk.choices.first.finishReason != null) {
            final elapsed = DateTime.now().difference(startTime).inMilliseconds / 1000.0;
            final tps = elapsed > 0 ? tokenCount / elapsed : 0.0;
            final messages = state.messages.map((m) => m.id == botMessageId ? m.copyWith(text: currentText) : m).toList();
            state = state.copyWith(messages: messages, liveStats: '${tps.toStringAsFixed(1)} tok/s');
          }
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

  void _startCpuMonitor() {
    _cpuTimer = Timer.periodic(const Duration(seconds: 2), (_) => _readCpuUsage());
  }

  Future<void> _readCpuUsage() async {
    try {
      final lines = await File('/proc/stat').readAsLines();
      final cpuLine = lines.firstWhere((l) => l.startsWith('cpu '), orElse: () => '');
      if (cpuLine.isEmpty) return;

      final parts = cpuLine.split(RegExp(r'\s+'));
      final times = parts.skip(1).take(7).map(int.parse).toList();
      final idle = times[3] + times[4];
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
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
