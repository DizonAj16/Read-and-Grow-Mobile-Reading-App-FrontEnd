import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AtLastReadingPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const AtLastReadingPage({super.key, this.onCompleted});

  @override
  State<AtLastReadingPage> createState() => _AtLastReadingPageState();
}

class _AtLastReadingPageState extends State<AtLastReadingPage>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  bool isReading = false;
  List<String> words = [];
  int currentWordIndex = 0;
  late AnimationController _iconAnimationController;

  final String fullText = '''
The spotted egg finally hatched. Out came a little bird who was afraid.
The tree where his mother built their nest was just too tall.
I don\'t know how to fly," he thought. He looked around for his mother, but she was not there.
Where could she be? He looked down and felt his legs shake.
He started to get dizzy and fell out of his nest. He quickly flapped his wings.
''';

  @override
  void initState() {
    super.initState();
    words = fullText.replaceAll('\n', ' ').split(' ');
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _readWordsOneByOne() async {
    if (isReading) {
      await flutterTts.stop();
      setState(() {
        isReading = false;
      });
      _iconAnimationController.reverse();
      return;
    }

    setState(() {
      isReading = true;
      currentWordIndex = 0;
    });
    _iconAnimationController.forward();

    for (int i = 0; i < words.length; i++) {
      if (!mounted || !isReading) return;

      String word = words[i];
      setState(() {
        currentWordIndex = i;
      });

      await flutterTts.speak(word);
      await Future.delayed(const Duration(milliseconds: 600));
    }

    setState(() {
      isReading = false;
    });
    _iconAnimationController.reverse();

    widget.onCompleted?.call();
  }

  TextSpan _buildHighlightedText(String text) {
    final wordList = text.split(' ');
    List<TextSpan> spans = [];

    for (int i = 0; i < wordList.length; i++) {
      final isCurrent = i == currentWordIndex;
      spans.add(
        TextSpan(
          text: '${wordList[i]} ',
          style: TextStyle(
            fontSize: 20,
            color: isCurrent ? Colors.blueAccent : Colors.black,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    return TextSpan(children: spans);
  }

  @override
  void dispose() {
    flutterTts.stop();
    _iconAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _readWordsOneByOne,
        child: AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: _iconAnimationController,
          size: 28,
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('At Last'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              margin: const EdgeInsets.only(bottom: 20.0),
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
                'Read the story carefully. Answer the questions on the next page.',
                style: TextStyle(fontSize: 18, height: 1.5),
                textAlign: TextAlign.justify,
              ),
            ),
            Container(
              constraints: const BoxConstraints(minHeight: 300),
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
              child: RichText(
                text: _buildHighlightedText(fullText),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0, bottom: 20.0),
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
      ),
    );
  }
}
