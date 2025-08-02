import 'dart:async';

import 'package:deped_reading_app_laravel/widgets/helpers/tts_helper.dart';
import 'package:flutter/material.dart';

class PenguinsPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const PenguinsPage({super.key, this.onCompleted});

  @override
  State<PenguinsPage> createState() => _PenguinsPageState();
}

class _PenguinsPageState extends State<PenguinsPage> {
  final TTSHelper _ttsHelper = TTSHelper();
  final ScrollController _scrollController = ScrollController();

  bool isReading = false;
  int _currentWordIndex = -1;

  final String _storyText =
      "I am a bird, but I do not fly. "
      "I am not a fish, but I can swim. "
      "What do you think I am? "
      "I am black and white and live in the cold. "
      "In the snow, I walk on my feet. "
      "In the water, I find fish to eat. "
      "Do you know what I am? "
      "I love the water! "
      "I play with my friends under the water. "
      "I can stay in the water for a long time. "
      "I am very cool! What am I?";

  late List<String> _words;

  @override
  void initState() {
    super.initState();
    _words = _storyText.replaceAll('\n', ' \n ').split(' ');
  }

  Future<void> _startReading() async {
    if (isReading) return;

    setState(() {
      isReading = true;
    });

    await _ttsHelper.speakList(
      _words,
      onHighlight: (index) {
        setState(() {
          _currentWordIndex = index;
        });
        _scrollToCurrentWord(index);
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

  void _stopReading() {
    _ttsHelper.stop();
    setState(() {
      isReading = false;
      _currentWordIndex = -1;
    });
  }

  void _scrollToCurrentWord(int index) {
    double targetOffset =
        (index / _words.length) * _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildStoryText() {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 4,
      runSpacing: 8,
      children: List.generate(_words.length, (index) {
        if (_words[index] == '\n') {
          return const SizedBox(width: double.infinity, height: 0);
        }
        return Text(
          _words[index],
          style: TextStyle(
            fontSize: 18,
            height: 1.5,
            color: index == _currentWordIndex ? Colors.red : Colors.black,
            fontWeight:
                index == _currentWordIndex
                    ? FontWeight.bold
                    : FontWeight.normal,
          ),
        );
      }),
    );
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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Penguins",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 30),
                Flexible(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 60),
                            child: _buildStoryText(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(flex: 1, child: SizedBox()),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Positioned(
            bottom: 90,
            right: 20,
            child: Image.asset(
              "assets/activity_images/penguin.png",
              height: 120,
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, size: 100),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 30,
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
