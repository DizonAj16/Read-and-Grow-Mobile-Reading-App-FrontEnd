import 'dart:async';

import 'package:deped_reading_app_laravel/widgets/helpers/tts_helper.dart';
import 'package:flutter/material.dart';

class IcfsReadingPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const IcfsReadingPage({super.key, this.onCompleted});

  @override
  State<IcfsReadingPage> createState() => _IcfsReadingPageState();
}

class _IcfsReadingPageState extends State<IcfsReadingPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  bool isReading = false;
  bool showNextButton = false;
  bool _hasCompleted = false;

  int currentParagraphIndex = -1;
  int currentWordIndex = -1;

  late AnimationController _iconController;
  final TTSHelper _ttsHelper = TTSHelper();

  final List<String> paragraphs = [
    '"Cling! Cling! Cling!" Benito and his sister Nelia raced out the door.',
    'He took some coins from his pocket and counted them. "I can have two scoops," he thought.',
    'But then his little sister Nelia asked, "Can I have an ice cream?"',
    'Benito looked at his coins again. "May I have two cones?" he asked. The vendor nodded.',
    'Benito and Nelia left with a smile.',
  ];

  late List<String> allWords;
  late List<MapEntry<int, int>> wordMap;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _ttsHelper.init(); // Initialize TTS
    _prepareWords();
  }

  void _prepareWords() {
    allWords = [];
    wordMap = [];

    for (int p = 0; p < paragraphs.length; p++) {
      final words = paragraphs[p].split(RegExp(r'\s+'));
      for (int w = 0; w < words.length; w++) {
        allWords.add(words[w]);
        wordMap.add(MapEntry(p, w));
      }
    }
  }

  Future<void> _readAloud() async {
    if (isReading) {
      await _ttsHelper.stop();
      setState(() {
        isReading = false;
        currentParagraphIndex = -1;
        currentWordIndex = -1;
        showNextButton = false;
      });
      _iconController.reverse();
      return;
    }

    _hasCompleted = false;

    setState(() {
      isReading = true;
      showNextButton = false;
      currentParagraphIndex = -1;
      currentWordIndex = -1;
    });
    _iconController.forward();

    await _ttsHelper.speakList(
      allWords,
      onHighlight: (index) {
        if (index < wordMap.length) {
          final map = wordMap[index];
          if (!mounted) return;
          setState(() {
            currentParagraphIndex = map.key;
            currentWordIndex = map.value;
          });
          _scrollToParagraph(map.key);
        }
      },
      onComplete: () {
        if (_hasCompleted || !mounted) return;
        _hasCompleted = true;

        setState(() {
          isReading = false;
          showNextButton = true;
          currentParagraphIndex = -1;
          currentWordIndex = -1;
        });

        _iconController.reverse();
        widget.onCompleted?.call();
      },
    );
  }

  void _scrollToParagraph(int index) {
    final offset = index * 110.0;
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _ttsHelper.dispose();
    _iconController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _readAloud,
        child: AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: _iconController,
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Ice Cream for Sale'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.lightBlue[50],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 6,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Text(
              'Read the story carefully. Answer the questions on the next page.',
              style: TextStyle(fontSize: 18, height: 1.5),
              textAlign: TextAlign.justify,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(paragraphs.length, (pIndex) {
                      final words = paragraphs[pIndex].split(RegExp(r'\s+'));

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: RichText(
                          textAlign: TextAlign.justify,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.8,
                              color: Colors.black,
                            ),
                            children: [
                              for (
                                int wIndex = 0;
                                wIndex < words.length;
                                wIndex++
                              )
                                TextSpan(
                                  text: '${words[wIndex]} ',
                                  style: TextStyle(
                                    color:
                                        (pIndex == currentParagraphIndex &&
                                                wIndex == currentWordIndex)
                                            ? Colors.red
                                            : Colors.black,
                                    fontWeight:
                                        (pIndex == currentParagraphIndex &&
                                                wIndex == currentWordIndex)
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          if (showNextButton)
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: widget.onCompleted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 20),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '© K5 Learning 2019',
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
