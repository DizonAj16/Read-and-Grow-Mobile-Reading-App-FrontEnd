import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class MatchWordsToPicturesPage extends StatefulWidget {
  const MatchWordsToPicturesPage({super.key});

  @override
  State<MatchWordsToPicturesPage> createState() =>
      _MatchWordsToPicturesPageState();
}

class _MatchWordsToPicturesPageState extends State<MatchWordsToPicturesPage> {
  final List<Map<String, String>> allItems = [
    {"word": "rag", "image": "assets/activity_images/rag.jpg"},
    {"word": "wag", "image": "assets/activity_images/wag.jpg"},
    {"word": "tag", "image": "assets/activity_images/tag.jpg"},
    {"word": "bag", "image": "assets/activity_images/bag.jpg"},
  ];

  late List<String> shuffledWords;
  late Map<int, String?> matchedWords;
  late Map<int, Color> borderColors;

  @override
  void initState() {
    super.initState();

    final words = allItems.map((e) => e["word"]!).toList();
    shuffledWords = List.from(words)..shuffle();

    matchedWords = {for (int i = 0; i < allItems.length; i++) i: null};
    borderColors = {for (int i = 0; i < allItems.length; i++) i: Colors.grey};
  }

  void _showFeedbackDialog(bool isCorrect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Transparent background

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8), // Minimized padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  isCorrect
                      ? 'assets/animation/correct.json'
                      : 'assets/animation/wrong.json',
                  width: 250, // Enlarged Lottie
                  height: 250,
                  repeat: false,
                ),
                const SizedBox(height: 8),
                Text(
                  isCorrect ? "✅ Correct!" : "❌ Try again!",
                  style: TextStyle(
                    fontSize: 20,
                    color: isCorrect ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "-ag Word Family: Match the word with the correct picture.",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: allItems.length,
            itemBuilder: (context, index) {
              final expectedWord = allItems[index]["word"]!;
              final imagePath = allItems[index]["image"]!;
              final currentMatch = matchedWords[index];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Draggable words (shuffled)
                    Expanded(
                      flex: 1,
                      child: _buildDraggableWord(
                        shuffledWords[index],
                        currentMatch,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // DragTarget images (fixed order)
                    Expanded(
                      flex: 1,
                      child: DragTarget<String>(
                        onAccept: (receivedWord) {
                          final isCorrect = receivedWord == expectedWord;

                          setState(() {
                            matchedWords[index] = receivedWord;
                            borderColors[index] =
                                isCorrect ? Colors.green : Colors.red;
                          });

                          _showFeedbackDialog(isCorrect);

                          if (!isCorrect) {
                            Future.delayed(const Duration(seconds: 1), () {
                              setState(() {
                                matchedWords[index] = null;
                                borderColors[index] = Colors.grey;
                              });
                            });
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColors[index]!,
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    imagePath,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                if (matchedWords[index] != null)
                                  Positioned(
                                    bottom: 8,
                                    child: Stack(
                                      children: [
                                        // White stroke (outline)
                                        Text(
                                          matchedWords[index]!,
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            foreground:
                                                Paint()
                                                  ..style = PaintingStyle.stroke
                                                  ..strokeWidth = 4
                                                  ..color = Colors.white,
                                          ),
                                        ),
                                        // Black fill
                                        Text(
                                          matchedWords[index]!,
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Text(
            "© Live Work Sheets",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableWord(String word, String? currentMatch) {
    final isMatched = word == currentMatch;
    return Draggable<String>(
      data: word,
      feedback: Material(
        color: Colors.transparent,
        child: _buildWordCard(word, isMatched),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildWordCard(word, isMatched),
      ),
      child: _buildWordCard(word, isMatched),
    );
  }

  Widget _buildWordCard(String word, bool isMatched) {
    return Card(
      color: isMatched ? Colors.green : Colors.blue,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            word,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}
