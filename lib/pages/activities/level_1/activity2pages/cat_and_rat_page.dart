import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class CatAndRatPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const CatAndRatPage({super.key, this.onCompleted});

  @override
  State<CatAndRatPage> createState() => _CatAndRatPageState();
}

class _CatAndRatPageState extends State<CatAndRatPage> {
  final FlutterTts _flutterTts = FlutterTts();
  final String _storyText =
      "A cat sat. He sat on a hat. It was red. The hat was on the mat. That cat sat and sat. He saw a rat. That cat ran!";
  final String _wordList = "cat, mat, hat, sat, rat, ran";

  late final List<String> _words;
  int _currentWordIndex = -1;
  bool isReading = false;

  @override
  void initState() {
    super.initState();
    _words =
        _storyText
            .split(' ')
            .map((w) => w.trim())
            .where((w) => w.isNotEmpty)
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
    await _flutterTts.stop();
    setState(() {
      _currentWordIndex = 0;
      isReading = true;
    });
    await _flutterTts.speak(_cleanWord(_words[_currentWordIndex]));
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
      widget.onCompleted?.call();
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
    return Wrap(
      alignment: WrapAlignment.start,
      children: List.generate(_words.length, (i) {
        final isHighlighted = i == _currentWordIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            _words[i],
            style: TextStyle(
              fontSize: 20,
              color: isHighlighted ? Colors.red : Colors.black,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      "Cat and Rat",
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "cat   mat   hat",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "sat   rat   ran",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        heroTag: "wordListButton",
                        onPressed: _speakWordList,
                        mini: true,
                        child: const Icon(Icons.volume_up, size: 30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(flex: 2, child: _buildStoryText()),
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
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 150,
              right: 20,
              child: const Text(
                "",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            Positioned(
              bottom: 50,
              right: 20,
              child: FloatingActionButton(
                heroTag: "storyButton",
                backgroundColor: Colors.green,
                onPressed: isReading ? _stopReading : _startReading,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    isReading ? Icons.pause : Icons.play_arrow,
                    key: ValueKey(isReading),
                    size: 30,
                  ),
                ),
              ),
            ),
            const Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8, right: 8),
                child: Text(
                  "© K5 Learning 2019",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
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
