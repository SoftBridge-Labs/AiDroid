import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';

class AskImageScreen extends StatefulWidget {
  const AskImageScreen({super.key});

  @override
  State<AskImageScreen> createState() => _AskImageScreenState();
}

class _AskImageScreenState extends State<AskImageScreen> {
  File? _image;
  final _picker = ImagePicker();
  String _analysis = "Upload an image to start analysis.";
  bool _isAnalyzing = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _analysis = "Image uploaded. Analyzing...";
        _isAnalyzing = true;
      });

      // Simulate on-device multimodal analysis
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isAnalyzing = false;
        _analysis = "Analysis Result: This image contains objects that look like electronic components on a desk. I can see a smartphone, a keyboard, and some cables. This was processed using a local multimodal vision model.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask Image')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined, size: 64, color: Colors.blueAccent),
                          const SizedBox(height: 16),
                          Text('Tap to select image', style: GoogleFonts.outfit(fontSize: 18)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            if (_isAnalyzing)
              const CircularProgressIndicator()
            else
              FadeInUp(
                child: Container(
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
                          const Icon(Icons.lightbulb_outline, color: Colors.yellowAccent),
                          const SizedBox(width: 8),
                          Text('AI Insights', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _analysis,
                        style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
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
