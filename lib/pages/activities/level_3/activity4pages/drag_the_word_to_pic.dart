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
  final List<Map<String, String>> matchItems = [
    {"word": "frog", "image": "assets/activity_images/frog.jpg"},
    {"word": "log", "image": "assets/activity_images/gol.jpg"},
    {"word": "pond", "image": "assets/activity_images/pond.jpg"},
    {"word": "lily pads", "image": "assets/activity_images/lily.jpg"},
  ];

  Map<int, String> matchedWords = {};
  Timer? _timer;
  int remainingTime = 60;
  int correctCount = 0;
  int wrongCount = 0;
  bool showScore = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime == 0) {
        _checkAllAnswers();
      } else {
        setState(() {
          remainingTime--;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _checkAllAnswers() {
    _stopTimer();
    correctCount = 0;
    wrongCount = 0;

    for (int i = 0; i < matchItems.length; i++) {
      if (matchedWords[i] == matchItems[i]['word']) {
        correctCount++;
      } else {
        wrongCount++;
      }
    }

    setState(() {
      showScore = true;
    });

    widget.onCompleted?.call();
  }

  void _resetGame() {
    setState(() {
      matchedWords.clear();
      remainingTime = 60;
      correctCount = 0;
      wrongCount = 0;
      showScore = false;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        "Match the Word to the Picture",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Drag each word to the picture it matches. Score is based on correct matches, wrong answers, and remaining time.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Time Left: $remainingTime seconds",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Words
                          Expanded(
                            child: Column(
                              children:
                                  matchItems.map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Draggable<String>(
                                        data: item['word']!,
                                        feedback: Material(
                                          color: Colors.transparent,
                                          child: Text(
                                            item['word']!,
                                            style: const TextStyle(
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),
                                        childWhenDragging: Opacity(
                                          opacity: 0.3,
                                          child: Text(
                                            item['word']!,
                                            style: const TextStyle(
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          item['word']!,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                          // Images
                          Expanded(
                            child: Column(
                              children: List.generate(matchItems.length, (
                                index,
                              ) {
                                return Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: DragTarget<String>(
                                    builder: (
                                      context,
                                      candidateData,
                                      rejectedData,
                                    ) {
                                      return Container(
                                        height: 100,
                                        width: 100,
                                        color: Colors.grey[300],
                                        child:
                                            matchedWords[index] != null
                                                ? Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Image.asset(
                                                      matchItems[index]['image']!,
                                                      height: 50,
                                                    ),
                                                    Text(
                                                      matchedWords[index]!,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                                : Image.asset(
                                                  matchItems[index]['image']!,
                                                  height: 80,
                                                ),
                                      );
                                    },
                                    onAccept: (word) {
                                      setState(() {
                                        matchedWords[index] = word;
                                      });

                                      if (matchedWords.length ==
                                          matchItems.length) {
                                        Future.delayed(
                                          const Duration(milliseconds: 300),
                                          _checkAllAnswers,
                                        );
                                      }
                                    },
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Full-screen Score Page
          if (showScore)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (correctCount * 10 + remainingTime - wrongCount * 5) >= 30
                          ? "Great Job!"
                          : "Keep Trying!",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Correct: $correctCount",
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      "Wrong: $wrongCount",
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      "Time Left: $remainingTime",
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Final Score: ${correctCount * 10 + remainingTime - wrongCount * 5}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _resetGame,
                      child: const Text("Try Again"),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
