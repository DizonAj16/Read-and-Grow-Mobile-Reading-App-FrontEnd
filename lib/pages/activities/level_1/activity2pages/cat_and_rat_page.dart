import 'package:deped_reading_app_laravel/widgets/helpers/tts_helper.dart';
import 'package:flutter/material.dart';

class CatAndRatPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const CatAndRatPage({super.key, this.onCompleted});

  @override
  State<CatAndRatPage> createState() => _CatAndRatPageState();
}

class _CatAndRatPageState extends State<CatAndRatPage> {
  final TTSHelper _ttsHelper = TTSHelper();

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

    _ttsHelper.init();
  }

  Future<void> _speakWordList() async {
    await _ttsHelper.speak(_wordList);
  }

  Future<void> _startReading() async {
    setState(() {
      isReading = true;
      _currentWordIndex = 0;
    });

    await _ttsHelper.speakList(
      _words.map(_cleanWord).toList(),
      onHighlight: (index) {
        setState(() {
          _currentWordIndex = index;
        });
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

  Future<void> _stopReading() async {
    await _ttsHelper.stop();
    setState(() {
      isReading = false;
      _currentWordIndex = -1;
    });
  }

  String _cleanWord(String word) {
    return word.replaceAll(RegExp(r'[^\w\s]'), '');
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
    _ttsHelper.stop();
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
