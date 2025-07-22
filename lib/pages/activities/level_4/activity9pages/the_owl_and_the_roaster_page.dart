import 'package:deped_reading_app_laravel/widgets/helpers/tts_helper.dart';
import 'package:flutter/material.dart';

class TheOwlAndTheRoosterPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const TheOwlAndTheRoosterPage({super.key, this.onCompleted});

  @override
  State<TheOwlAndTheRoosterPage> createState() =>
      _TheOwlAndTheRoosterPageState();
}

class _TheOwlAndTheRoosterPageState extends State<TheOwlAndTheRoosterPage> {
  late TTSHelper _ttsHelper;

  final List<String> _sentences = [
    'While the other owls slept in the daytime, Hootie slept at night.',
    'She always yawned and fell asleep when her friends asked her to hoot with them.',
    'This made her sad because she liked hooting a lot.',
    'One day, she met a rooster who could not wake up in the morning.',
    'He could not awaken the villagers. This made the rooster unhappy.',
    'Hootie said, "I know how to help you. I\'ll hoot in the morning so you can wake up to do your job!"',
  ];

  int _currentSentenceIndex = 0;
  int _currentWordIndex = -1;
  bool _isPlaying = false;
  List<String> _currentWords = [];

  @override
  void initState() {
    super.initState();
    _ttsHelper = TTSHelper();
  }

  Future<void> _startReading() async {
    setState(() {
      _isPlaying = true;
      _currentSentenceIndex = 0;
      _currentWordIndex = -1;
    });

    for (int s = 0; s < _sentences.length; s++) {
      if (!_isPlaying) return;

      final sentence = _sentences[s];
      final words = sentence.split(' ');
      _currentWords = words;

      setState(() {
        _currentSentenceIndex = s;
      });

      await _ttsHelper.speakList(
        words,
        onHighlight: (int w) {
          setState(() {
            _currentWordIndex = w;
          });
        },
        onComplete: () async {
          await Future.delayed(const Duration(milliseconds: 800));
        },
      );
    }

    setState(() {
      _isPlaying = false;
      _currentWordIndex = -1;
      _currentSentenceIndex = 0;
    });

    widget.onCompleted?.call();
  }

  Future<void> _stopReading() async {
    await _ttsHelper.stop();
    setState(() {
      _isPlaying = false;
      _currentWordIndex = -1;
      _currentSentenceIndex = 0;
    });
  }

  void _toggleTts() {
    if (_isPlaying) {
      _stopReading();
    } else {
      _startReading();
    }
  }

  Widget _buildRichStory() {
    List<Widget> sentenceWidgets = [];

    for (int s = 0; s < _sentences.length; s++) {
      final words = _sentences[s].split(' ');
      List<TextSpan> spans = [];

      for (int w = 0; w < words.length; w++) {
        final isHighlighted =
            _isPlaying && s == _currentSentenceIndex && w == _currentWordIndex;

        spans.add(
          TextSpan(
            text: words[w] + ' ',
            style: TextStyle(
              fontSize: 18,
              height: 1.8,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.deepPurple : Colors.black,
            ),
          ),
        );
      }

      sentenceWidgets.add(
        RichText(textAlign: TextAlign.justify, text: TextSpan(children: spans)),
      );

      sentenceWidgets.add(const SizedBox(height: 16));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sentenceWidgets,
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('The Owl and The Rooster'),
      ),
      backgroundColor: Colors.grey[200],
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleTts,
        backgroundColor: Colors.deepPurple,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            key: ValueKey<bool>(_isPlaying),
            size: 30,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instruction box
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
              'Read the story carefully. Answer the questions on the next page.',
              style: TextStyle(fontSize: 18, height: 1.5),
              textAlign: TextAlign.justify,
            ),
          ),

          // Story area
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
                child: SingleChildScrollView(child: _buildRichStory()),
              ),
            ),
          ),

          // Footer
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
    );
  }
}
