import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Activity2Page extends StatefulWidget {
  const Activity2Page({super.key});

  @override
  _Activity2PageState createState() => _Activity2PageState();
}

class _Activity2PageState extends State<Activity2Page> {
  int _currentPage = 0;

  final List<Widget> _pages = [
    const CatAndRatPage(), // First page with the provided image
    const MatchingExercisePage(), // Second page with the matching exercise
    const FillInTheBlanksPage(), // Third page with fill-in-the-blank and drawing
  ];

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(child: _pages[_currentPage]),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.arrow_back_ios_new_sharp, size: 50),
                  ),
                ),
                Text(
                  "Page ${_currentPage + 1} of ${_pages.length}",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                ElevatedButton(
                  onPressed:
                      _currentPage < _pages.length - 1 ? _goToNextPage : null,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.arrow_forward_ios_sharp, size: 50),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CatAndRatPage extends StatefulWidget {
  const CatAndRatPage({super.key});

  @override
  _CatAndRatPageState createState() => _CatAndRatPageState();
}

class _CatAndRatPageState extends State<CatAndRatPage> {
  final String _storyText = "A cat sat. "
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

class MatchingExercisePage extends StatelessWidget {
  const MatchingExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            "Cat and Rat (exercises)",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "1. Draw a line to match the word and picture.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                // Words column
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("cat", style: TextStyle(fontSize: 20)),
                      Text("hat", style: TextStyle(fontSize: 20)),
                      Text("mat", style: TextStyle(fontSize: 20)),
                      Text("rat", style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
                // Images column
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Image.asset(
                        "assets/activity_images/rat.jpg",
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      Image.asset(
                        "assets/activity_images/cat.jpg",
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      Image.asset(
                        "assets/activity_images/hat.png",
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      Image.asset(
                        "assets/activity_images/mat.png",
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ],
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
      ),
    );
  }
}

class FillInTheBlanksPage extends StatelessWidget {
  const FillInTheBlanksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "2. Fill in the blanks.",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 22, color: Colors.black),
              children: [
                const TextSpan(text: "The cat sat on a red "),
                WidgetSpan(
                  child: SizedBox(
                    height: 30,
                    width: 100,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ".\nThe cat saw a "),
                WidgetSpan(
                  child: SizedBox(
                    height: 30,
                    width: 100,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ".\nThen he "),
                WidgetSpan(
                  child: SizedBox(
                    height: 30,
                    width: 100,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: "!"),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            "3. Draw the two animals from the story.",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              "© K5 Learning 2019",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
