import 'dart:async';

import 'package:deped_reading_app_laravel/widgets/helpers/tts_helper.dart';
import 'package:flutter/material.dart';

class Day2StoryPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const Day2StoryPage({super.key, this.onCompleted});

  @override
  State<Day2StoryPage> createState() => _Day2StoryPageState();
}

class _Day2StoryPageState extends State<Day2StoryPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> wordKeys = {};
  late TTSHelper _ttsHelper;

  bool isPlaying = false;
  int currentWordIndex = -1;
  List<String> allWords = [];

  final List<String> storyText = [
    "Nick wanted a puppy, so he decided to become a volunteer at the animal shelter. "
        "He was hoping to convince his parents that he was ready to take care of a puppy. "
        "He volunteered at the shelter twice each week, on Tuesdays after school and on Saturdays.",
    "While he was there, Nick did several things. He walked the dogs and washed and brushed them. "
        "Grooming the long-haired dogs took a long time! He cleaned up the dogs’ kennels, too. "
        "He also played with the puppies to help get them used to people. Sometimes he gave them baths as well. "
        "Once in a while, Nick spent time with the kittens and cats, but he preferred working with the dogs. "
        "There was always plenty to do at the shelter, so Nick was never bored.",
  ];

  @override
  void initState() {
    super.initState();
    _ttsHelper = TTSHelper();
    _prepareWords();
  }

  void _prepareWords() {
    allWords = storyText.join(' ').split(RegExp(r'\s+'));
    for (int i = 0; i < allWords.length; i++) {
      wordKeys[i] = GlobalKey();
    }
  }

  Future<void> _startReading() async {
    setState(() {
      isPlaying = true;
      currentWordIndex = -1;
    });

    await _ttsHelper.speakList(
      allWords,
      onHighlight: (index) {
        setState(() {
          currentWordIndex = index;
        });
        _scrollToCurrentWord();
      },
      onComplete: () {
        setState(() {
          isPlaying = false;
          currentWordIndex = -1;
        });
        widget.onCompleted?.call();
      },
    );
  }

  Future<void> _stopReading() async {
    await _ttsHelper.stop();
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
    _ttsHelper.stop();
    _scrollController.dispose();
    super.dispose();
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
