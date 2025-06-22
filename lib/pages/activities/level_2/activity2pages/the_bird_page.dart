import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TheBirdPage extends StatefulWidget {
  const TheBirdPage({super.key});

  @override
  State<TheBirdPage> createState() => _TheBirdPageState();
}

class _TheBirdPageState extends State<TheBirdPage> {
  final String _storyText =
      "A bird can fly. "
      "It can flap its wings. "
      "It sits on a tree. "
      "The bird sings a song. "
      "The sky is blue. "
      "The bird is happy.";

  final String _wordList = "bird, fly, tree, sings, wings, sky";

  final FlutterTts _flutterTts = FlutterTts();

  Future<void> _speakWordList() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.speak(_wordList);
  }

  Future<void> _speakStory() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.3);
    await _flutterTts.speak(_storyText);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "The Bird",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 100),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    _storyText,
                    style: const TextStyle(fontSize: 20, color: Colors.black),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Image.asset(
                    "assets/activity_images/bird.jpg",
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Image.asset(
              "assets/activity_images/tree.jpg",
              height: 150,
              fit: BoxFit.contain,
            ),
          ],
        ),
        Positioned(
          top: 50,
          right: 5,
          child: Container(
            width: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: const [
                Row(
                  children: [
                    Text(
                      "bird   fly   tree",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "sings   wings   sky",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 60,
          left: 140,
          child: FloatingActionButton(
            heroTag: "birdWordListButton",
            onPressed: _speakWordList,
            child: const Icon(Icons.volume_up, size: 30),
            mini: true,
          ),
        ),
        Positioned(
          bottom: 120,
          right: 20,
          child: Text(
            "Tap this sound button to hear the story.",
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
        Positioned(
          bottom: 50,
          right: 20,
          child: FloatingActionButton(
            heroTag: "birdStoryButton",
            onPressed: _speakStory,
            child: const Icon(Icons.volume_up, size: 30),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Text(
            "© K5 Learning 2019",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
