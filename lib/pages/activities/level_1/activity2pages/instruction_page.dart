import 'package:deped_reading_app_laravel/widgets/helpers/tts_helper.dart';
import 'package:flutter/material.dart';

class CatInstructionPage extends StatefulWidget {
  final VoidCallback onCompleted;

  const CatInstructionPage({
    super.key,
    required this.onCompleted,
    required TTSHelper ttsHelper,
  });

  @override
  State<CatInstructionPage> createState() => _CatInstructionPageState();
}

class _CatInstructionPageState extends State<CatInstructionPage> {
  final TTSHelper _ttsHelper = TTSHelper();

  final List<Map<String, String>> instructions = [
    {
      'title': '🔤 Cat And Rat',
      'description':
          'Tap the word that goes with the picture. Say the word out loud!',
    },
    {
      'title': '🔤 Cat And Rat Story',
      'description': 'Drag each word to the matching picture on the right!',
    },
    {
      'title': '✏️ Fill in the Blanks',
      'description':
          'Look at the picture and fill in the missing letter or word to complete each word. Tap the blank to choose the correct answer.',
    },
    {
      'title': '✏️ Fill in the Blanks',
      'description':
          'Listen to the sentence. Drag the right word into the blank.',
    },
    {
      'title': '📖 Let\'s Read Together',
      'description': 'Listen to the story. Watch the words as they light up.',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Let\'s Learn About Cat and Rat Words!'),
            const SizedBox(height: 16),
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
            const SizedBox(height: 20),
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
