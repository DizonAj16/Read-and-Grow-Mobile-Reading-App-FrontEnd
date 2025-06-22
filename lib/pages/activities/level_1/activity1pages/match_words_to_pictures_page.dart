import 'package:flutter/material.dart';

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

    // Always keep "rag" first
    final first = allItems[0];
    final rest = allItems.sublist(1)..shuffle();
    allItems
      ..clear()
      ..add(first)
      ..addAll(rest);

    final words = allItems.map((e) => e["word"]!).toList();
    shuffledWords = [words.first, ...words.sublist(1)..shuffle()];

    matchedWords = {for (int i = 0; i < allItems.length; i++) i: null};

    borderColors = {for (int i = 0; i < allItems.length; i++) i: Colors.grey};
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
                          if (receivedWord == expectedWord) {
                            setState(() {
                              matchedWords[index] = receivedWord;
                              borderColors[index] = Colors.green;
                            });
                          } else {
                            setState(() {
                              borderColors[index] = Colors.red;
                            });
                            Future.delayed(const Duration(seconds: 1), () {
                              setState(() {
                                borderColors[index] = Colors.grey;
                              });
                            });
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColors[index]!,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                imagePath,
                                fit: BoxFit.contain,
                              ),
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
