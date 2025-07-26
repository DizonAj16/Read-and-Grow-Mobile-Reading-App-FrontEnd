import 'package:deped_reading_app_laravel/widgets/helpers/tts_helper.dart';
import 'package:flutter/material.dart';

class TheBirdPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const TheBirdPage({super.key, this.onCompleted});

  @override
  State<TheBirdPage> createState() => _TheBirdPageState();
}

class _TheBirdPageState extends State<TheBirdPage> {
  final TTSHelper _ttsHelper = TTSHelper();

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
    _ttsHelper.init();
  }

  Future<void> _speakWordList() async {
    await _ttsHelper.stop();
    await _ttsHelper.speak(_wordList);
  }

  Future<void> _startReading() async {
    if (isReading) return;

    setState(() {
      isReading = true;
    });

    await _ttsHelper.speakList(
      _words.map(_cleanWord).toList(),
      onHighlight: (index) {
        setState(() {
          _currentWordIndex = index;
        });
      },
      onComplete: () {
        setState(() {
          isReading = false;
          _currentWordIndex = -1;
        });
        widget.onCompleted?.call();
      },
    );
  }

  Future<void> _stopReading() async {
    await _ttsHelper.stop();
    setState(() {
      isReading = false;
    });
  }

  String _cleanWord(String word) {
    return word.replaceAll(RegExp(r'[^\w\s]'), '');
  }

  Widget _buildStoryText() {
    return Wrap(
      alignment: WrapAlignment.start,
      children:
          _words.asMap().entries.map((entry) {
            int i = entry.key;
            String word = entry.value;
            bool isHighlighted = i == _currentWordIndex;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                word,
                style: TextStyle(
                  color: isHighlighted ? Colors.red : Colors.black,
                  fontSize: 20,
                  fontWeight:
                      isHighlighted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
    );
  }

  @override
  void dispose() {
    _ttsHelper.stop();
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

                const SizedBox(height: 30),

                // Story Text and Image
                Flexible(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 60),
                            child: _buildStoryText(),
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
                  height: 120,
                  child: Image.asset(
                    "assets/activity_images/tree.png",
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported, size: 100),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // Word List Box
          Positioned(
            top: 50,
            right: 5,
            child: Container(
              width: 200,
              height: 80,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      "bird  fly  tree  sings\nwings  sky",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      softWrap: true,
                    ),
                  ),
                  FloatingActionButton(
                    heroTag: "wordListButton",
                    onPressed: _speakWordList,
                    child: const Icon(Icons.volume_up, size: 20),
                    mini: true,
                  ),
                ],
              ),
            ),
          ),

          // Guide text
          Positioned(
            bottom: 130,
            right: 20,
            child: const Text(
              "Tap this sound button to hear the story.",
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
          ),

          // Play/Pause Story Button
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
