import 'package:deped_reading_app_laravel/widgets/helpers/tts_helper.dart';
import 'package:flutter/material.dart';

class BirdInstructionPage extends StatefulWidget {
  final VoidCallback onCompleted;

  const BirdInstructionPage({super.key, required this.onCompleted});

  @override
  State<BirdInstructionPage> createState() => _BirdInstructionPageState();
}

class _BirdInstructionPageState extends State<BirdInstructionPage> {
  final TTSHelper _ttsHelper = TTSHelper();

  final List<Map<String, String>> instructions = [
    {
      'title': '🐤 Bird Word List',
      'description':
          'Tap on each word and listen carefully. Try to say the word out loud, too!',
    },
    {
      'title': '📖 The Bird Story',
      'description':
          'Read the story or listen to it. Watch the words light up as they are read.',
    },
    {
      'title': '❓ Answer the Questions',
      'description':
          'Pick the best answer for each question about the story. Try your best!',
    },
    {
      'title': '🖼️ Match Word to Picture',
      'description':
          'Look at the word. Drag it to the picture it matches. Let’s see how many you get right!',
    },
    {
      'title': '✏️ Fill in the Blanks',
      'description':
          'Drag the right word into the blank to finish the sentence. You can listen to the sentence if you need help.',
    },
  ];

  @override
  void dispose() {
    _ttsHelper.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Let\'s Learn About the Bird!')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: instructions.length,
                itemBuilder: (context, index) {
                  final item = instructions[index];
                  return InstructionCard(
                    title: item['title']!,
                    description: item['description']!,
                    ttsHelper: _ttsHelper,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onCompleted,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Activity'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InstructionCard extends StatefulWidget {
  final String title;
  final String description;
  final TTSHelper ttsHelper;

  const InstructionCard({
    super.key,
    required this.title,
    required this.description,
    required this.ttsHelper,
  });

  @override
  State<InstructionCard> createState() => _InstructionCardState();
}

class _InstructionCardState extends State<InstructionCard> {
  String _currentWord = '';
  bool _isSpeaking = false;

  void _speakWithHighlight() async {
    if (_isSpeaking) return;

    setState(() => _isSpeaking = true);

    final words = widget.description.split(' ');

    await widget.ttsHelper.speakList(
      words,
      onHighlight: (index) {
        if (index == -1) {
          setState(() {
            _currentWord = '';
            _isSpeaking = false;
          });
          return;
        }

        final clean = words[index].replaceAll(RegExp(r'[^\w\s]'), '');
        setState(() => _currentWord = clean);
      },
      onComplete: () {
        setState(() {
          _currentWord = '';
          _isSpeaking = false;
        });
      },
    );
  }

  List<InlineSpan> _buildHighlightedText() {
    final words = widget.description.split(' ');

    return words.map((word) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');
      final isHighlighted =
          cleanWord.toLowerCase() == _currentWord.toLowerCase();

      return TextSpan(
        text: '$word ',
        style: TextStyle(
          color: isHighlighted ? Colors.deepPurple : Colors.black,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    widget.ttsHelper.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: _buildHighlightedText(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _speakWithHighlight,
              icon: const Icon(Icons.volume_up),
              label: const Text('Read Aloud'),
            ),
          ],
        ),
      ),
    );
  }
}
