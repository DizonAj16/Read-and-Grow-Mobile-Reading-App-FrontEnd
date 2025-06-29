import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ReadingPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const ReadingPage({super.key, this.onCompleted});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
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

  Future<void> _setupTts() async {
    await _flutterTts.setLanguage("en-PH");
    await _flutterTts.setSpeechRate(0.25); // Slow
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
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
        String word = words[_currentWordIndex].replaceAll(
          RegExp(r'[^\w\s]'),
          '',
        );
        setState(() {});
        await _flutterTts.speak(word);
        await Future.delayed(const Duration(seconds: 2));
        if (!isPlaying) return;
        _currentWordIndex++;
      }

      _currentSentenceIndex++;
      _currentWordIndex = 0;
    }

    setState(() => isPlaying = false);

    if (widget.onCompleted != null) {
      widget.onCompleted!();
    }
  }

  Widget _buildSentence(int index) {
    List<String> words = sentences[index].split(' ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text.rich(
        TextSpan(
          children:
              words.asMap().entries.map((entry) {
                int wordIndex = entry.key;
                String word = entry.value;

                bool isHighlighted =
                    index == _currentSentenceIndex &&
                    wordIndex == _currentWordIndex;

                return TextSpan(
                  text: '$word ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: isHighlighted ? Colors.red : Colors.black87,
                  ),
                );
              }).toList(),
        ),
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Listen and follow along",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
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
              Positioned(
                bottom: 30,
                right: 30,
                child: FloatingActionButton(
                  backgroundColor: Colors.green.shade600,
                  onPressed: _togglePlayPause,
                  tooltip: isPlaying ? 'Pause Reading' : 'Start Reading',
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      key: ValueKey<bool>(isPlaying),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
