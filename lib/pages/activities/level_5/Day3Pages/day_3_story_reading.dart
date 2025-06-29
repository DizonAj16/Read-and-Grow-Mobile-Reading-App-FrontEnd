import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DayThreeStoryPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const DayThreeStoryPage({super.key, this.onCompleted});

  @override
  State<DayThreeStoryPage> createState() => _DayThreeStoryPageState();
}

class _DayThreeStoryPageState extends State<DayThreeStoryPage> {
  final FlutterTts _flutterTts = FlutterTts();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> wordKeys = {};

  bool isPlaying = false;
  int currentWordIndex = -1;
  List<String> allWords = [];

  final List<String> storyText = [
    "Nick volunteered at the animal shelter for three months. He learned a great deal about raising puppies and training them. Every time he learned something new, he practiced it. He also told his parents about what he was learning. He wanted to persuade them that he could be trusted with a puppy of his own.",
    "One afternoon, Dad picked Nick up from volunteering and asked him how the day went.\n\n“Oh, it went great,” Nick answered enthusiastically. “They even let me help introduce the dogs to people who want to adopt them!”\n\n“That’s terrific!” Dad answered with a grin. “I’m so glad you’re getting this experience. You’ll need it for our new puppy!”\n\n“We’re getting a puppy?” Nick practically shouted. “That’s awesome! I can’t wait!”",
  ];

  @override
  void initState() {
    super.initState();
    _prepareWords();
    _flutterTts.setCompletionHandler(() {
      _speakNextWord();
    });
  }

  void _prepareWords() {
    allWords = storyText.join(' ').split(RegExp(r'\s+'));
    for (int i = 0; i < allWords.length; i++) {
      wordKeys[i] = GlobalKey();
    }
  }

  Future<void> _speakNextWord() async {
    currentWordIndex++;
    if (currentWordIndex < allWords.length) {
      setState(() {});
      await _flutterTts.speak(allWords[currentWordIndex]);
      _scrollToCurrentWord();
      await Future.delayed(const Duration(milliseconds: 200));
    } else {
      setState(() {
        isPlaying = false;
        currentWordIndex = -1;
      });
      await _flutterTts.stop();
      widget.onCompleted?.call(); // ✅ Trigger callback when done
    }
  }

  Future<void> _startReading() async {
    setState(() {
      isPlaying = true;
      currentWordIndex = -1;
    });
    await _speakNextWord();
  }

  Future<void> _stopReading() async {
    await _flutterTts.stop();
    setState(() {
      isPlaying = false;
      currentWordIndex = -1;
    });
  }

  void _scrollToCurrentWord() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = wordKeys[currentWordIndex];
      if (key != null && key.currentContext != null) {
        final box = key.currentContext!.findRenderObject() as RenderBox;
        final position = box.localToGlobal(
          Offset.zero,
          ancestor: context.findRenderObject(),
        );
        _scrollController.animateTo(
          _scrollController.offset + position.dy - 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildStoryText() {
    List<InlineSpan> spans = [];
    int wordCounter = 0;

    for (String paragraph in storyText) {
      final words = paragraph.split(RegExp(r'\s+'));
      for (String word in words) {
        final isHighlighted = wordCounter == currentWordIndex;
        spans.add(
          WidgetSpan(
            child: Container(
              key: wordKeys[wordCounter],
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              decoration: BoxDecoration(
                color: isHighlighted ? Colors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$word ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      isHighlighted ? FontWeight.bold : FontWeight.normal,
                  color: isHighlighted ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        );
        wordCounter++;
      }
      spans.add(const TextSpan(text: '\n\n'));
    }

    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Nick and the Animal Shelter'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Instruction Box
              Container(
                padding: const EdgeInsets.all(20.0),
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.lightBlue[50],
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  'Read the text and then answer the questions.',
                  style: TextStyle(fontSize: 18, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),

              // Story Box
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: _buildStoryText(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 70),
            ],
          ),

          // Floating Action Button
          Positioned(
            bottom: 16,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: FloatingActionButton(
                key: ValueKey(isPlaying),
                onPressed: isPlaying ? _stopReading : _startReading,
                backgroundColor: Colors.red,
                child: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
              ),
            ),
          ),

          // Footer
          Positioned(
            bottom: 20,
            left: 16,
            child: Text(
              "© K5 Learning 2019",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
    );
  }
}
