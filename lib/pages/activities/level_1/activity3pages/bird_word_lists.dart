import 'package:deped_reading_app_laravel/widgets/helpers/tts_helper.dart';
import 'package:flutter/material.dart';

class BirdWordListPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const BirdWordListPage({super.key, this.onCompleted});

  @override
  _BirdWordListPageState createState() => _BirdWordListPageState();
}

class _BirdWordListPageState extends State<BirdWordListPage> {
  bool _completed = false;
  int _highlightIndex = -1;
  final ScrollController _scrollController = ScrollController();

  final List<String> birdWordList = [
    'bird',
    'flies',
    'tree',
    'sings',
    'nest',
    'sky',
    'loudly',
  ];

  final Map<String, String> wordImages = {
    'bird': 'assets/activity_images/bird_blue.jpg',
    'flies': 'assets/activity_images/flies.png',
    'tree': 'assets/activity_images/tree.png',
    'sings': 'assets/activity_images/sings.png',
    'nest': 'assets/activity_images/nest.jpg',
    'sky': 'assets/activity_images/sky.jpg',
    'loudly': 'assets/activity_images/loudly.jpg',
  };

  late TTSHelper _ttsHelper;

  @override
  void initState() {
    super.initState();
    _ttsHelper = TTSHelper();
    _ttsHelper.init();
  }

  Future<void> _speakWords() async {
    await _ttsHelper.speakList(
      birdWordList,
      onHighlight: (index) {
        setState(() {
          _highlightIndex = index;
        });

        if (index >= 0) {
          final position = (index ~/ 2) * 210.0;
          _scrollController.animateTo(
            position,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      onComplete: () {
        setState(() {
          _highlightIndex = -1;
          _completed = true;
        });
        widget.onCompleted?.call();
      },
    );
  }

  void _showWordCard(String word) async {
    final imagePath = wordImages[word] ?? 'assets/placeholder.jpg';
    await _ttsHelper.speak(word);

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imagePath,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    word,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  void dispose() {
    _ttsHelper.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Image.asset(
                      "assets/activity_images/the_bird.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: GridView.builder(
                      controller: _scrollController,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10.0,
                            mainAxisSpacing: 10.0,
                            childAspectRatio: 0.9,
                          ),
                      itemCount: birdWordList.length,
                      itemBuilder: (context, index) {
                        final word = birdWordList[index];
                        final isHighlighted = _highlightIndex == index;
                        final imagePath =
                            wordImages[word] ?? 'assets/placeholder.jpg';

                        return GestureDetector(
                          onTap: () => _showWordCard(word),
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isHighlighted
                                      ? Colors.deepPurple.withOpacity(0.1)
                                      : Colors.grey[200],
                              border: Border.all(
                                color:
                                    isHighlighted
                                        ? Colors.deepPurple
                                        : Colors.grey,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      imagePath,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  word,
                                  style: TextStyle(
                                    color:
                                        isHighlighted
                                            ? Colors.red
                                            : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 10,
              right: 10,
              child: FloatingActionButton(
                onPressed: _speakWords,
                tooltip: 'Read all words',
                child: const Icon(Icons.volume_up, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
