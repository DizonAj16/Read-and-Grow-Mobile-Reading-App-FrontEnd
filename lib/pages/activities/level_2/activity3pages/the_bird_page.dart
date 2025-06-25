import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TheBirdPage extends StatefulWidget {
  const TheBirdPage({super.key});

  @override
  State<TheBirdPage> createState() => _TheBirdPageState();
}

class _TheBirdPageState extends State<TheBirdPage> {
  final FlutterTts _flutterTts = FlutterTts();

  final String _storyText =
      "A bird can fly. "
      "It can flap its wings. "
      "It sits on a tree. "
      "The bird sings a song. "
      "The sky is blue. "
      "The bird is happy.";

  final String _wordList = "bird, fly, tree, sings, wings, sky";

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
    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "The Bird",
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30), // Reduced spacing
                // Story Text and Image
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          _storyText,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: Image.asset(
                          "assets/activity_images/mordicai.jpg",
                          height: 150,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.image_not_supported,
                                size: 100,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Second Image
                SizedBox(
                  height: 120, // Limited height to prevent overflow
                  child: Image.asset(
                    "assets/activity_images/tree.png",
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported, size: 100),
                  ),
                ),

                const SizedBox(height: 10), // Added some space at the bottom
              ],
            ),
          ),

          // Word list at upper right
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "bird   fly   tree",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                  SizedBox(height: 4),
                  Text(
                    "sings   wings   sky",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
          ),

          // Word list speaker button at top left
          Positioned(
            top: 60,
            left: 140,
            child: FloatingActionButton(
              heroTag: "wordListButton",
              onPressed: _speakWordList,
              child: const Icon(Icons.volume_up, size: 30),
              mini: true,
            ),
          ),

          // Guide text for story speaker button
          Positioned(
            bottom: 130,
            right: 20,
            child: const Text(
              "Tap this sound button to hear the story.",
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
          ),

          // Story speaker button
          Positioned(
            bottom: 50,
            right: 20,
            child: FloatingActionButton(
              heroTag: "storyButton",
              onPressed: _speakStory,
              child: const Icon(Icons.volume_up, size: 20),
              mini: true,
            ),
          ),

          // Copyright
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
              child: Text(
                "© K5 Learning 2019",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
