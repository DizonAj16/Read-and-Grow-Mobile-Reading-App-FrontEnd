import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class DragTheWordToPicturePage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const DragTheWordToPicturePage({super.key, this.onCompleted});

  @override
  State<DragTheWordToPicturePage> createState() =>
      _DragTheWordToPicturePageState();
}

class _DragTheWordToPicturePageState extends State<DragTheWordToPicturePage> {
  final List<Map<String, String>> items = [
    {"word": "fish", "image": "assets/activity_images/bluefish.jpg"},
    {"word": "water", "image": "assets/activity_images/water2.jpg"},
    {"word": "penguin", "image": "assets/activity_images/penguin.png"},
    {"word": "bird", "image": "assets/activity_images/bird.jpg"},
    {"word": "snow", "image": "assets/activity_images/snow.jpg"},
  ];

  late List<String> shuffledWords;

  final Map<String, bool> matched = {};
  int wrongAnswers = 0;
  int totalTime = 60;
  int remainingTime = 60;
  bool isCompleted = false;
  Timer? timer;

  final double itemHeight = 50;

  @override
  void initState() {
    super.initState();
    for (var item in items) {
      matched[item["word"]!] = false;
    }
    shuffledWords = items.map((item) => item["word"]!).toList();
    shuffledWords.shuffle(Random());
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingTime == 0) {
        t.cancel();
        _showScorePage();
      } else {
        setState(() {
          remainingTime--;
        });
      }
    });
  }

  void _showScorePage() {
    timer?.cancel();
    setState(() {
      isCompleted = true;
    });
    widget.onCompleted?.call();
  }

  int _calculateScore() {
    int baseScore = 100;
    int wrongPenalty = wrongAnswers * 20;
    int timePenalty = totalTime - remainingTime;
    int score = baseScore - wrongPenalty - timePenalty;
    return score < 0 ? 0 : score;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void checkCompletion() {
    if (matched.values.every((v) => v)) {
      Future.delayed(Duration.zero, _showScorePage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: isCompleted ? _buildScorePage() : _buildGamePage());
  }

  Widget _buildGamePage() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Match the Words to the Correct Pictures',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Drag each word to the correct image before time runs out!',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Time Left: $remainingTime s',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(thickness: 2, color: Colors.grey),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: SingleChildScrollView(
                      child: Column(
                        children:
                            shuffledWords
                                .where((word) => matched[word] == false)
                                .map((word) {
                                  return Container(
                                    height: itemHeight,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Draggable<String>(
                                      data: word,
                                      feedback: Material(
                                        color: Colors.transparent,
                                        child: _buildDraggableWord(word),
                                      ),
                                      childWhenDragging: Opacity(
                                        opacity: 0.3,
                                        child: _buildDraggableWord(word),
                                      ),
                                      child: _buildDraggableWord(word),
                                    ),
                                  );
                                })
                                .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children:
                            items.map((item) {
                              String word = item["word"]!;
                              String image = item["image"]!;
                              return Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: DragTarget<String>(
                                  builder: (
                                    context,
                                    candidateData,
                                    rejectedData,
                                  ) {
                                    return Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child:
                                            matched[word]!
                                                ? Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Image.asset(
                                                      image,
                                                      height: 60,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      word,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                                : Image.asset(
                                                  image,
                                                  height: 80,
                                                ),
                                      ),
                                    );
                                  },
                                  onAccept: (data) {
                                    setState(() {
                                      if (data == word) {
                                        matched[word] = true;
                                      } else {
                                        wrongAnswers++;
                                      }
                                      checkCompletion();
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableWord(String word) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        word,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildScorePage() {
    int finalScore = _calculateScore();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              finalScore >= 80 ? Icons.emoji_events : Icons.sentiment_satisfied,
              size: 80,
              color: finalScore >= 80 ? Colors.amber : Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              finalScore >= 80 ? "Great Job!" : "Keep Going!",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text("Score: $finalScore", style: const TextStyle(fontSize: 20)),
            Text(
              "Wrong Answers: $wrongAnswers",
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              "Time Remaining: $remainingTime seconds",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  matched.updateAll((key, value) => false);
                  isCompleted = false;
                  wrongAnswers = 0;
                  remainingTime = totalTime;
                  shuffledWords = items.map((item) => item["word"]!).toList();
                  shuffledWords.shuffle(Random());
                  startTimer();
                });
              },
              child: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }
}
