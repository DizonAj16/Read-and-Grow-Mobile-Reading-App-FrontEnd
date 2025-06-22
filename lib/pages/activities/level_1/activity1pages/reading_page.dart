import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key});

  @override
  _ReadingPageState createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  final List<String> sentences = [
    "The bag is on the cab.",
    "Gab is on the cab.",
    "Gab's bag has a jam.",
    "Gab's bag has a jam and a cam.",
  ];

  final FlutterTts _flutterTts = FlutterTts();

  Future<void> _speakAllSentences() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.3); // Slow speech rate for kids
    await _flutterTts.speak(sentences.join(" "));
  }

  Future<void> _speakSingleSentence(String sentence) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.3);
    await _flutterTts.speak(sentence);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Read the sentences below:",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: sentences.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _speakSingleSentence(sentences[index]),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              sentences[index],
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 120,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Tap the sound button to hear\nthe sentences.",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              right: 20,
              child: FloatingActionButton(
                onPressed: _speakAllSentences,
                tooltip: 'Play All Sentences',
                child: const Icon(Icons.volume_up, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Optional: Reusable word card widget
class WordCard extends StatelessWidget {
  final String word;

  const WordCard({super.key, required this.word});

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    return colors[Random().nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: _getRandomColor(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            word,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
