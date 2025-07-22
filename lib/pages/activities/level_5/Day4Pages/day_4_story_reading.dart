import 'dart:async';

import 'package:deped_reading_app_laravel/widgets/helpers/tts_helper.dart';
import 'package:flutter/material.dart';

class DayFourStoryPage extends StatefulWidget {
  final VoidCallback onCompleted;

  const DayFourStoryPage({super.key, required this.onCompleted});

  @override
  State<DayFourStoryPage> createState() => _DayFourStoryPageState();
}

class _DayFourStoryPageState extends State<DayFourStoryPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> wordKeys = {};
  final TTSHelper _ttsHelper = TTSHelper();

  bool isPlaying = false;
  int currentWordIndex = -1;
  List<String> allWords = [];

  final List<String> storyText = [
    "Nick's parents had finally given him permission to get a puppy. Nick was so excited about it that he could hardly wait to bring his puppy home. The family had decided that they would adopt a shelter puppy, so one Saturday, Nick and his parents visited the shelter where Nick volunteered. When they arrived, Nick told the shelter manager why they were there.",
    '"That\'s wonderful!" said the manager. "We have two litters of puppies that are waiting for good homes. One is a litter of dalmatians, and the other is a litter of corgis."',
    'Nick and his parents looked at one another for a moment. Then, Nick said, "I\'m pretty sure we don\'t have enough room in our home for a dalmatian. Could we look at the corgi puppies?"',
    '"That sounds sensible," Mom said. "I like corgis, and I\'ve heard that they\'re good family pets."',
    'The manager escorted Nick and his parents to the room where the puppies lived. Within a moment, Nick had found the corgi puppy he wanted. "Look," he pointed. "That\'s the one I want!" Everyone looked at the puppy Nick had found. He was the smallest of the litter, but he looked healthy and friendly. The manager let Nick and his family cuddle the puppy and play with him for a few minutes. Then Nick said, "I\'m absolutely sure about him, Mom and Dad."',
    'Mom and Dad agreed that he was a good choice. Dad asked, "What\'s his name going to be?"',
    '"How about Tucker? He looks like a Tucker, doesn\'t he?" Nick asked.',
    '"Tucker it is," said the manager as she printed out the adoption papers. Mom and Dad signed the papers, and then the manager handed Nick and his parents a leash, a bag of food, and three dog toys. "Here are some important things you\'ll need," she said, handing Nick a list.',
    'Nick looked at the list. They would need a kennel or crate, food and water dishes, and a lot more. "We\'ll have to go to the pet-supply store next," he told his parents.',
  ];

  @override
  void initState() {
    super.initState();
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
        setState(() => currentWordIndex = index);
        _scrollToCurrentWord();
      },
      onComplete: () {
        setState(() {
          isPlaying = false;
          currentWordIndex = -1;
        });
        widget.onCompleted();
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

  @override
  void dispose() {
    _ttsHelper.stop();
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
        title: const Text('A New Friend for Nick'),
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

          // Play / Stop Button
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: isPlaying ? _stopReading : _startReading,
              backgroundColor: Colors.red,
              child: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
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
