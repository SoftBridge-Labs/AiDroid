import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PromptLabScreen extends StatefulWidget {
  const PromptLabScreen({super.key});

  @override
  State<PromptLabScreen> createState() => _PromptLabScreenState();
}

class _PromptLabScreenState extends State<PromptLabScreen> {
  final _inputController = TextEditingController();
  String _result = "Result will appear here.";
  String _selectedTask = "Summarize";

  final List<String> _tasks = ["Summarize", "Rewrite", "Generate Code", "Brainstorm"];

  void _runTask() async {
    if (_inputController.text.trim().isEmpty) return;

    setState(() {
      _result = "Processing with on-device model...";
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      switch (_selectedTask) {
        case "Summarize":
          _result = "Summary: The user is exploring on-device AI capabilities using the Prompt Lab. This tool allows for private, offline data processing.";
          break;
        case "Rewrite":
          _result = "Rewritten: \"I'm currently testing the local AI tools in the Prompt Lab, which enables secure and disconnected data management.\"";
          break;
        case "Generate Code":
          _result = "```dart\nvoid main() {\n  print('Hello from on-device AI!');\n}\n```";
          break;
        default:
          _result = "Insights: 1. Privacy focus. 2. Low latency. 3. Cost effective.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prompt Lab')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select AI Task', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  final isSelected = _selectedTask == task;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(task),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _selectedTask = task),
                      selectedColor: const Color(0xFF6C63FF),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _inputController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter text to process...',
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _runTask,
                child: const Text('Process Locally'),
              ),
            ),
            const SizedBox(height: 32),
            Text('Output', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FadeInContainer(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF25263B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _result,
                  style: GoogleFonts.jetBrainsMono(fontSize: 14, color: Colors.cyanAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FadeInContainer extends StatelessWidget {
  final Widget child;
  const FadeInContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeIn(child: child);
  }
}
