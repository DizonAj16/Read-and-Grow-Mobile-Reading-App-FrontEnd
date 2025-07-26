import 'dart:async';

import 'package:flutter/material.dart';

class DragTheWordToPicturePage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const DragTheWordToPicturePage({super.key, this.onCompleted});

  @override
  State<DragTheWordToPicturePage> createState() =>
      _DragTheWordToPicturePageState();
}

class _DragTheWordToPicturePageState extends State<DragTheWordToPicturePage> {
  final List<Map<String, dynamic>> items = [
    {'word': 'penguin', 'image': 'assets/activity_images/penguin.png'},
    {'word': 'fish', 'image': 'assets/activity_images/bluefish.jpg'},
    {'word': 'snow', 'image': 'assets/activity_images/snow.jpg'},
    {'word': 'bird', 'image': 'assets/activity_images/bird.jpg'},
    {'word': 'water', 'image': 'assets/activity_images/water2.jpg'},
  ];

  late List<Map<String, dynamic>> shuffledItems;
  late List<String> shuffledWords;
  Map<int, String?> matchedWords = {};
  bool showScore = false;
  int score = 0;
  int remainingTime = 60;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    shuffledItems = List.from(items)..shuffle();
    shuffledWords =
        items.map((item) => item['word'] as String).toList()..shuffle();
    matchedWords = {};
    showScore = false;
    score = 0;
    remainingTime = 60;

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingTime > 0) {
        setState(() => remainingTime--);
      } else {
        endGame();
      }
    });
  }

  void endGame() {
    timer?.cancel();
    setState(() => showScore = true);
    widget.onCompleted?.call();
  }

  void handleDrop(String word, int index) {
    if (matchedWords[index] != null) return;

    final correctWord = shuffledItems[index]['word'];
    setState(() {
      matchedWords[index] = word;
      if (word == correctWord) {
        score++;
      }
    });

    if (matchedWords.length == items.length) {
      endGame();
    }
  }

  Widget _buildGamePage() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          "Match the Words to the Pictures",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Time Left: $remainingTime s",
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Word draggable list
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      shuffledWords.map((word) {
                        final isAlreadyUsed = matchedWords.containsValue(word);
                        return Draggable<String>(
                          data: word,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Chip(
                              label: Text(
                                word,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: Colors.blue,
                              elevation: 4,
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: Chip(label: Text(word)),
                          ),
                          child:
                              isAlreadyUsed
                                  ? Chip(
                                    label: Text(
                                      word,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                  : Chip(
                                    label: Text(
                                      word,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                        );
                      }).toList(),
                ),
              ),

              const VerticalDivider(width: 20),

              // Picture drop targets
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(shuffledItems.length, (index) {
                      final item = shuffledItems[index];
                      final matched = matchedWords[index];

                      return Column(
                        children: [
                          Container(
                            height: 120,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Image.asset(
                              item['image'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                          DragTarget<String>(
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                width: 140,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 16,
                                ),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color:
                                      matched == null
                                          ? Colors.grey.shade200
                                          : (matched == item['word']
                                              ? Colors.green.shade200
                                              : Colors.red.shade200),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  matched ?? "Drop Here",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              );
                            },
                            onWillAccept: (data) => true,
                            onAccept: (data) => handleDrop(data, index),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScorePage() {
    final int total = items.length;
    final int finalScore = (score * 100 ~/ total) - (60 - remainingTime);
    final bool passed = score >= (total / 2);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            passed ? Icons.emoji_events : Icons.mood,
            color: passed ? Colors.amber : Colors.orange,
            size: 100,
          ),
          const SizedBox(height: 20),
          Text(
            passed ? "Well Done!" : "Try Again!",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            "Correct Matches: $score / $total",
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 12),
          Text(
            "Final Score: $finalScore",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() => startGame()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text("Try Again", style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: showScore ? _buildScorePage() : _buildGamePage(),
        ),
      ),
    );
  }
}
