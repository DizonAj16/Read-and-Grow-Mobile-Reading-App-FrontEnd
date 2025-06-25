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

  late List<String> _words;
  int _currentWordIndex = -1;
  bool isReading = false;

  @override
  void initState() {
    super.initState();
    _words =
        _storyText
            .split(' ')
            .map((word) => word.trim())
            .where((word) => word.isNotEmpty)
            .toList();
    _setupTts();
  }

  void _setupTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() async {
      if (isReading) {
        await Future.delayed(const Duration(milliseconds: 300));
        _readNextWord();
      }
    });
  }

  Future<void> _speakWordList() async {
    await _flutterTts.stop();
    await _flutterTts.speak(_wordList);
  }

  Future<void> _startReading() async {
    if (_currentWordIndex == -1 || _currentWordIndex >= _words.length) {
      setState(() {
        _currentWordIndex = 0;
        isReading = true;
      });
      await _flutterTts.speak(_cleanWord(_words[_currentWordIndex]));
    } else {
      setState(() {
        isReading = true;
      });
      await _flutterTts.speak(_cleanWord(_words[_currentWordIndex]));
    }
  }

  Future<void> _readNextWord() async {
    if (!isReading) return;

    setState(() {
      _currentWordIndex++;
    });

    if (_currentWordIndex < _words.length) {
      await _flutterTts.speak(_cleanWord(_words[_currentWordIndex]));
    } else {
      setState(() {
        isReading = false;
        _currentWordIndex = -1;
      });
    }
  }

  String _cleanWord(String word) {
    return word.replaceAll(RegExp(r'[^\w\s]'), '');
  }

  Future<void> _stopReading() async {
    await _flutterTts.stop();
    setState(() {
      isReading = false;
    });
  }

  Widget _buildStoryText() {
    List<Widget> wordWidgets = [];

    for (int i = 0; i < _words.length; i++) {
      bool isHighlighted = i == _currentWordIndex;

      wordWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            _words[i],
            style: TextStyle(
              color: isHighlighted ? Colors.red : Colors.black,
              fontSize: 20,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return Wrap(alignment: WrapAlignment.start, children: wordWidgets);
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

                const SizedBox(height: 50), // Reduced spacing
                // Story Text and Image
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(child: _buildStoryText()),
                      ),
                      const SizedBox(width: 50),
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
              backgroundColor: Colors.green,
              onPressed: isReading ? _stopReading : _startReading,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  isReading ? Icons.pause : Icons.play_arrow,
                  key: ValueKey(isReading),
                  size: 20,
                ),
              ),
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
