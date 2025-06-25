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

  int _currentSentenceIndex = 0;
  int _currentWordIndex = 0;

  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _setupTts();
  }

  void _setupTts() async {
    await _flutterTts.setLanguage("en-PH");
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setPitch(1.2);
  }

  Future<void> _togglePlayPause() async {
    if (isPlaying) {
      setState(() => isPlaying = false);
      await _flutterTts.stop();
    } else {
      setState(() {
        isPlaying = true;
        _currentSentenceIndex = 0;
        _currentWordIndex = 0;
      });
      _readAllSentences();
    }
  }

  Future<void> _readAllSentences() async {
    while (isPlaying && _currentSentenceIndex < sentences.length) {
      List<String> words = sentences[_currentSentenceIndex].split(' ');
      while (isPlaying && _currentWordIndex < words.length) {
        String currentWord = words[_currentWordIndex].replaceAll(
          RegExp(r'[^\w\s]'),
          '',
        );
        setState(() {});
        await _flutterTts.speak(currentWord);
        await Future.delayed(const Duration(seconds: 1));
        if (!isPlaying) return;
        _currentWordIndex++;
      }
      _currentSentenceIndex++;
      _currentWordIndex = 0;
    }
    setState(() => isPlaying = false);
  }

  Widget _buildSentence(int index) {
    List<String> words = sentences[index].split(' ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children:
            words.asMap().entries.map((entry) {
              int wordIndex = entry.key;
              String word = entry.value;

              bool isHighlighted =
                  index == _currentSentenceIndex &&
                  wordIndex == _currentWordIndex;

              return Text(
                word,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                  color: isHighlighted ? Colors.red : Colors.black,
                ),
              );
            }).toList(),
      ),
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
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Press play to read aloud.",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: sentences.length,
                      itemBuilder: (context, index) {
                        return _buildSentence(index);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 50,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.green,
                onPressed: _togglePlayPause,
                tooltip: isPlaying ? 'Pause' : 'Play',
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    key: ValueKey(isPlaying),
                    size: 32,
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
