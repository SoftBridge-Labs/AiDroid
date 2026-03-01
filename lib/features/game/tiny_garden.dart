import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum FlowerState { seed, sprout, flower, wilted }

class TinyGarden extends StatefulWidget {
  const TinyGarden({super.key});

  @override
  State<TinyGarden> createState() => _TinyGardenState();
}

class _TinyGardenState extends State<TinyGarden> {
  final List<FlowerState> _garden = List.filled(6, FlowerState.seed);
  final TextEditingController _commandController = TextEditingController();
  String _status = "Welcome to your AI Garden! Try saying 'plant some seeds' or 'water the flowers'.";

  void _handleCommand(String command) {
    setState(() {
      final cmd = command.toLowerCase();
      if (cmd.contains('plant')) {
        for (int i = 0; i < _garden.length; i++) {
          if (_garden[i] == FlowerState.seed) _garden[i] = FlowerState.sprout;
        }
        _status = "🌱 Seeds have sprouted!";
      } else if (cmd.contains('water')) {
        for (int i = 0; i < _garden.length; i++) {
          if (_garden[i] == FlowerState.sprout) _garden[i] = FlowerState.flower;
        }
        _status = "💧 The garden is blooming!";
      } else if (cmd.contains('harvest')) {
        for (int i = 0; i < _garden.length; i++) {
          if (_garden[i] == FlowerState.flower) _garden[i] = FlowerState.seed;
        }
        _status = "🧺 Harvest complete! Ready for new seeds.";
      } else {
        _status = "I didn't quite catch that. Try 'plant', 'water', or 'harvest'.";
      }
    });
    _commandController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tiny Garden')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 18),
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                ),
                itemCount: _garden.length,
                itemBuilder: (context, index) {
                  return _buildFlower(_garden[index], index);
                },
              ),
            ),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildFlower(FlowerState state, int index) {
    IconData icon;
    Color color;
    switch (state) {
      case FlowerState.seed:
        icon = Icons.grain;
        color = Colors.brown;
        break;
      case FlowerState.sprout:
        icon = Icons.eco;
        color = Colors.green;
        break;
      case FlowerState.flower:
        icon = Icons.local_florist;
        color = Colors.pinkAccent;
        break;
      case FlowerState.wilted:
        icon = Icons.dry;
        color = Colors.orange;
        break;
    }

    return ZoomIn(
      delay: Duration(milliseconds: index * 100),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Icon(icon, size: 40, color: color),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commandController,
              decoration: const InputDecoration(
                hintText: 'Talk to your garden...',
                border: InputBorder.none,
              ),
              onSubmitted: _handleCommand,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.greenAccent),
            onPressed: () => _handleCommand(_commandController.text),
          ),
        ],
      ),
    );
  }
}
