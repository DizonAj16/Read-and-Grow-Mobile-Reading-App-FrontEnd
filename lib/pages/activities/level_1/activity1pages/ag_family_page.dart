import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AgFamilyPage extends StatefulWidget {
  const AgFamilyPage({super.key});

  @override
  _AgFamilyPageState createState() => _AgFamilyPageState();
}

class _AgFamilyPageState extends State<AgFamilyPage> {
  final List<String> agFamilyWords = [
    'bag',
    'jag',
    'tag',
    'nag',
    'sag',
    'dag',
    'mag',
    'rag',
    'lag',
    'wag',
  ];

  final Map<String, String> wordImages = {
    'bag': 'assets/activity_images/bag.jpg',
    'jag': 'assets/activity_images/jag.jpg',
    'tag': 'assets/activity_images/tag.jpg',
    'nag': 'assets/activity_images/nag.png',
    'sag': 'assets/activity_images/sag.jpg',
    'dag': 'assets/activity_images/dag.jpg',
    'mag': 'assets/activity_images/mag.jpg',
    'rag': 'assets/activity_images/rag.jpg',
    'lag': 'assets/activity_images/lag.png',
    'wag': 'assets/activity_images/wag.jpg',
  };

  final FlutterTts _flutterTts = FlutterTts();
  int _highlightIndex = -1;
  final ScrollController _scrollController = ScrollController();

  Future<void> _speakWords() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.3);

    for (int i = 0; i < agFamilyWords.length; i++) {
      setState(() {
        _highlightIndex = i;
      });

      await _flutterTts.speak(agFamilyWords[i]);

      final position = (i ~/ 2) * 210.0;
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      await Future.delayed(const Duration(seconds: 2));
    }

    setState(() {
      _highlightIndex = -1;
    });
  }

  void _showWordCard(String word) async {
    final imagePath = wordImages[word] ?? 'assets/placeholder.jpg';

    // Speak the word
    await _flutterTts.speak(word);

    // Show Dialog
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: 200,
                    height: 200,
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      "assets/activity_images/ag-family.png",
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
                      itemCount: agFamilyWords.length,
                      itemBuilder: (context, index) {
                        final word = agFamilyWords[index];
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
                                            ? Colors.deepPurple
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
                child: const Icon(Icons.volume_up, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
