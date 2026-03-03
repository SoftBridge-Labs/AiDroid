import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AskImageScreen extends StatefulWidget {
  const AskImageScreen({super.key});

  @override
  State<AskImageScreen> createState() => _AskImageScreenState();
}

class _AskImageScreenState extends State<AskImageScreen> {
  File? _image;
  final _picker = ImagePicker();
  String _analysis =
      "Upload an image and provide a Gemini API Key to start analysis.";
  bool _isAnalyzing = false;

  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _promptController = TextEditingController(
    text: "Analyze this image in detail.",
  );

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('gemini_api_key') ?? '';
      if (_apiKeyController.text.isNotEmpty) {
        _analysis = "API Key loaded. Upload an image to start.";
      }
    });
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) {
      setState(() {
        _analysis = "Please select an image first.";
      });
      return;
    }

    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _analysis = "Please provide a Gemini API Key.";
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysis = "Image uploaded. Analyzing with Gemini API...";
    });

    _saveApiKey(apiKey);

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

      final imageBytes = await _image!.readAsBytes();
      final prompt = _promptController.text.trim().isEmpty
          ? "Analyze this image in detail."
          : _promptController.text.trim();

      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      final response = await model.generateContent(content);

      setState(() {
        _isAnalyzing = false;
        _analysis = response.text ?? "No result generated.";
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _analysis = "Analysis Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      appBar: AppBar(
        title: Text(
          'Ask Image',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0E0E14),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _apiKeyController,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Enter Gemini API Key',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  icon: Icon(Icons.vpn_key, color: Colors.amber),
                ),
                obscureText: true,
                onChanged: (val) => _saveApiKey(val.trim()),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00C9FF).withOpacity(0.5),
                  ),
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo_outlined,
                            size: 54,
                            color: Color(0xFF00C9FF),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to select image',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _promptController,
                style: GoogleFonts.outfit(color: Colors.white),
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Ask something about the image...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  icon: Icon(Icons.chat, color: Color(0xFF92FE9D)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isAnalyzing ? null : _analyzeImage,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(
                  _isAnalyzing ? 'Analyzing...' : 'Analyze Image',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_analysis.isNotEmpty)
              FadeInUp(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1E33),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: Colors.yellowAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Insights',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        _analysis,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
