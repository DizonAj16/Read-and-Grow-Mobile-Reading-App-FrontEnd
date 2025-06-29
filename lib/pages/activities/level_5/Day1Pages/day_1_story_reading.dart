import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DayOneStoryPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const DayOneStoryPage({super.key, this.onCompleted});

  @override
  State<DayOneStoryPage> createState() => _DayOneStoryPageState();
}

class _DayOneStoryPageState extends State<DayOneStoryPage> {
  final FlutterTts _flutterTts = FlutterTts();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> wordKeys = {};

  bool isPlaying = false;
  int currentWordIndex = -1;
  List<String> allWords = [];

  final List<String> storyText = [
    'Ever since he was six years old, Nick had wanted to get a puppy. His parents always refused. They said he wasn’t capable of taking care of a puppy. “You have no idea how much work a puppy is,” Dad said. “You would have to housebreak the puppy, train the puppy to obey you, and groom it, too.”',
    '“And then there’s taking the puppy to the vet, playing with it, and feeding it,” Mom added. “It’s not that I’m against having a puppy. But a puppy takes up a lot of time.”',
    'Nick couldn’t think of a way that he could convince his parents that he was ready for a puppy. Then, he got an idea. “If I volunteer at the animal shelter,” he thought, “I’ll bet Mom and Dad will see that I’m ready to take care of a puppy!”',
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
      widget.onCompleted?.call();
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
  void dispose() {
    _flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Nick and the Puppy'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
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
