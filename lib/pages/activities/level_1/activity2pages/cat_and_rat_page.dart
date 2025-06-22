import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class CatAndRatPage extends StatefulWidget {
  const CatAndRatPage({super.key});

  @override
  _CatAndRatPageState createState() => _CatAndRatPageState();
}

class _CatAndRatPageState extends State<CatAndRatPage> {
  final String _storyText =
      "A cat sat. "
      "He sat on a hat. "
      "It was red. "
      "The hat was on the mat. "
      "That cat sat and sat. "
      "He saw a rat. "
      "That cat ran!";

  final String _wordList = "cat, mat, hat, sat, rat, ran";

  final FlutterTts _flutterTts = FlutterTts();

  Future<void> _speakWordList() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.4); // Adjust speech rate for kids
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
        // Main content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Cat and Rat",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    _storyText,
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Image.asset(
                    "assets/activity_images/cat.jpg",
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Image.asset(
              "assets/activity_images/rat.jpg",
              height: 150,
              fit: BoxFit.contain,
            ),
          ],
        ),
        // Word list positioned in the upper right
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
              children: [
                Row(
                  children: [
                    Text(
                      "cat   mat   hat",
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
                      "sat   rat   ran",
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
        // TTS button for word list at the top left
        Positioned(
          top: 60,
          left: 140,
          child: FloatingActionButton(
            heroTag: "wordListButton", // Unique heroTag for this button
            onPressed: _speakWordList,
            child: Icon(Icons.volume_up, size: 30),
            mini: true,
          ),
        ),
        // Guide text above the text-to-speech button
        Positioned(
          bottom: 120,
          right: 20,
          child: Text(
            "Tap this sound button to hear the story.",
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
        // Text-to-speech button
        Positioned(
          bottom: 50,
          right: 20,
          child: FloatingActionButton(
            heroTag: "storyButton", // Unique heroTag for this button
            onPressed: _speakStory,
            child: Icon(Icons.volume_up, size: 30),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Text(
            "© K5 Learning 2019",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
