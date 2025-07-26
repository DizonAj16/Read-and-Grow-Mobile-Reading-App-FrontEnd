import 'package:deped_reading_app_laravel/widgets/helpers/tts_helper.dart';
import 'package:flutter/material.dart';

class TheGreenFrogReadingPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const TheGreenFrogReadingPage({super.key, this.onCompleted});

  @override
  State<TheGreenFrogReadingPage> createState() =>
      _TheGreenFrogReadingPageState();
}

class _TheGreenFrogReadingPageState extends State<TheGreenFrogReadingPage> {
  final TTSHelper _ttsHelper = TTSHelper();
  final ScrollController _scrollController = ScrollController();

  bool isReading = false;
  int _currentWordIndex = -1;

  final String _storyText =
      'Do you see the green frog?\n'
      'The green frog can jump!\n'
      'The frog jumps into the pond.\n'
      'Its arms move in the water.\n'
      'Its legs move in the water.\n'
      'The frog swims in the pond.\n'
      'The frog plays in the pond.\n'
      'Do you see the fly?\n'
      'It buzzes all around.\n'
      'It buzzes near the frog.\n'
      'The frog sees the fly.\n'
      'The frog eats the fly!';

  final String _wordList = 'frog arms legs water swims pond fly jump';
  List<String> _words = [];

  @override
  void initState() {
    super.initState();
    _ttsHelper.init();
    _words = _storyText.replaceAll('\n', ' \n ').split(' ');
  }

  Future<void> _speakWordList() async {
    if (isReading) return;
    await _ttsHelper.stop();
    await _ttsHelper.speak(_wordList);
  }

  Future<void> _startReading() async {
    if (isReading) return;

    setState(() {
      isReading = true;
    });

    await _ttsHelper.stop();

    await _ttsHelper.speakList(
      _words,
      onHighlight: (index) {
        if (!mounted) return;
        setState(() => _currentWordIndex = index);
        _scrollToCurrentWord(index);
      },
      onComplete: () {
        if (!mounted) return;
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
            color: index == _currentWordIndex ? Colors.green : Colors.black,
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
      appBar: AppBar(
        title: const Text('The Green Frog'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed Word List
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'frog   arms   legs   water\nswims   pond   fly   jump',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
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

            const SizedBox(height: 20),

            // Scrollable story content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStoryText(),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Image.asset(
                        'assets/activity_images/frog.png',
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.image_not_supported,
                              size: 100,
                            ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating TTS control
      floatingActionButton: FloatingActionButton(
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
    );
  }
}
