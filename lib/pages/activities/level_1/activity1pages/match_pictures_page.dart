import 'dart:math';

import 'package:flutter/material.dart';

class MatchPicturesPage extends StatefulWidget {
  const MatchPicturesPage({super.key});

  @override
  State<MatchPicturesPage> createState() => _MatchPicturesPageState();
}

class _MatchPicturesPageState extends State<MatchPicturesPage> {
  final List<Map<String, String>> originalItems = [
    {"image": "assets/activity_images/tag.jpg", "word": "tag"},
    {"image": "assets/activity_images/bag.jpg", "word": "bag"},
    {"image": "assets/activity_images/wag.jpg", "word": "wag"},
    {"image": "assets/activity_images/rag.jpg", "word": "rag"},
    {"image": "assets/activity_images/nag.png", "word": "nag"},
  ];

  late List<Map<String, String>> shuffledItems;
  int currentIndex = 0;
  bool showFeedback = false;
  bool isCorrect = false;

  @override
  void initState() {
    super.initState();
    shuffledItems = List<Map<String, String>>.from(originalItems);
    shuffledItems.shuffle(Random());
  }

  void checkAnswer(String selectedWord) {
    final correctWord = shuffledItems[currentIndex]["word"];
    setState(() {
      isCorrect = selectedWord == correctWord;
      showFeedback = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        showFeedback = false;
        if (isCorrect) {
          currentIndex++;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentIndex >= shuffledItems.length) {
      return const Center(
        child: Text(
          "🎉 Great job! You matched all the words.",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    }

    final currentItem = shuffledItems[currentIndex];
    final allWords = originalItems.map((item) => item["word"]!).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Tap the correct word for the picture.",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(currentItem["image"]!, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  allWords.map((word) {
                    return ElevatedButton(
                      onPressed: showFeedback ? null : () => checkAnswer(word),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      child: Text(word, style: const TextStyle(fontSize: 18)),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 24),
            if (showFeedback)
              AnimatedOpacity(
                opacity: showFeedback ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  isCorrect ? "✅ Correct!" : "❌ Try again!",
                  style: TextStyle(
                    fontSize: 20,
                    color: isCorrect ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
