import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DragTheWordToPicturePage extends StatefulWidget {
  const DragTheWordToPicturePage({super.key});

  @override
  State<DragTheWordToPicturePage> createState() =>
      _DragTheWordToPicturePageState();
}

class _DragTheWordToPicturePageState extends State<DragTheWordToPicturePage> {
  final List<Map<String, String>> matchItems = [
    {"word": "fish", "image": "assets/activity_images/bluefish.jpg"},
    {"word": "water", "image": "assets/activity_images/water2.jpg"},
    {"word": "penguin", "image": "assets/activity_images/penguin.png"},
    {"word": "bird", "image": "assets/activity_images/bird.jpg"},
    {"word": "snow", "image": "assets/activity_images/snow.jpg"},
  ];

  late List<String> shuffledWords;
  Map<int, String> matchedWords = {};
  Map<int, bool> matchResults = {};

  double opacityLevel = 1.0;
  bool showFeedback = false;
  bool isCorrectFeedback = true;

  Timer? timer;
  int maxTime = 60;
  int remainingTime = 60;

  int totalCorrectAnswers = 0;
  double totalScore = 0;
  bool isFinished = false;

  @override
  void initState() {
    super.initState();
    _shuffleWords();
    _startTimer();
  }

  void _shuffleWords() {
    shuffledWords = matchItems.map((item) => item['word']!).toList()..shuffle();
  }

  void _startTimer() {
    remainingTime = maxTime;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        t.cancel();
        _checkAllAnswers();
      }
    });
  }

  void _stopTimer() {
    timer?.cancel();
  }

  void _animatedReset() async {
    setState(() {
      opacityLevel = 0.0;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      matchedWords.clear();
      matchResults.clear();
      _shuffleWords();
    });

    await Future.delayed(const Duration(milliseconds: 150));

    setState(() {
      opacityLevel = 1.0;
    });

    _startTimer();
  }

  void _checkAllAnswers() {
    _stopTimer();
    int correctCount = 0;
    for (int i = 0; i < matchItems.length; i++) {
      if (matchedWords[i] == matchItems[i]['word']) {
        correctCount++;
      }
    }

    totalCorrectAnswers += correctCount;
    totalScore += remainingTime;

    if (correctCount >= 3) {
      _showPassDialog(correctCount);
    } else {
      _showTryAgainDialog(correctCount);
    }
  }

  void _showPassDialog(int correctCount) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Good Job!'),
            content: Text(
              'You got $correctCount out of ${matchItems.length} correct.\nRemaining Time: $remainingTime s',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _animatedReset();
                },
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    isFinished = true;
                  });
                },
                child: const Text('Finish'),
              ),
            ],
          ),
    );
  }

  void _showTryAgainDialog(int correctCount) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Try Again'),
            content: Text(
              'You only got $correctCount correct.\nDo you want to retry?\nRemaining Time: $remainingTime s',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _animatedReset();
                },
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    isFinished = true;
                  });
                },
                child: const Text('Finish'),
              ),
            ],
          ),
    );
  }

  void _showFeedback(bool isCorrect) {
    setState(() {
      showFeedback = true;
      isCorrectFeedback = isCorrect;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        showFeedback = false;
      });
    });
  }

  void _resetGame() {
    setState(() {
      matchedWords.clear();
      matchResults.clear();
      totalCorrectAnswers = 0;
      totalScore = 0;
      isFinished = false;
    });
    _shuffleWords();
    _startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isFinished) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Final Score'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Activity Completed!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                'Total Correct Answers: $totalCorrectAnswers',
                style: const TextStyle(fontSize: 22),
              ),
              Text(
                'Total Score: ${totalScore.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _resetGame,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("Matching Exercise"),
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: AnimatedOpacity(
                          opacity: opacityLevel,
                          duration: const Duration(milliseconds: 400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      "Drag each word to match the correct picture.",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  Text(
                                    "Time Left: $remainingTime s",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    flex: 1,
                                    child: Column(
                                      children:
                                          shuffledWords.map((word) {
                                            final isUsed = matchedWords
                                                .containsValue(word);
                                            Widget wordTile = Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.lightBlue.shade100,
                                                border: Border.all(
                                                  color: Colors.blue.shade700,
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                word,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );

                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6.0,
                                                  ),
                                              child: Draggable<String>(
                                                data: word,
                                                feedback: Material(
                                                  color: Colors.transparent,
                                                  child: wordTile,
                                                ),
                                                childWhenDragging: Opacity(
                                                  opacity: 0.3,
                                                  child: wordTile,
                                                ),
                                                child:
                                                    isUsed
                                                        ? Opacity(
                                                          opacity: 0.4,
                                                          child: wordTile,
                                                        )
                                                        : wordTile,
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 40,
                                  ), // more space between word and images
                                  Flexible(
                                    flex: 3,
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: List.generate(matchItems.length, (
                                          index,
                                        ) {
                                          final image =
                                              matchItems[index]['image']!;
                                          final matchedWord =
                                              matchedWords[index];
                                          final result = matchResults[index];

                                          Color borderColor;
                                          if (result == true) {
                                            borderColor = Colors.green;
                                          } else if (result == false) {
                                            borderColor = Colors.red;
                                          } else {
                                            borderColor = Colors.grey;
                                          }

                                          return DragTarget<String>(
                                            builder: (
                                              context,
                                              candidateData,
                                              rejectedData,
                                            ) {
                                              return Container(
                                                width: 100,
                                                height: 100,
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: borderColor,
                                                    width: 3,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: Colors.grey.shade200,
                                                ),
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Image.asset(
                                                      image,
                                                      fit: BoxFit.contain,
                                                      width: 80,
                                                      height: 80,
                                                    ),
                                                    if (matchedWord != null)
                                                      Positioned(
                                                        bottom: 4,
                                                        child: Container(
                                                          color: Colors.white70,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                          child: Text(
                                                            matchedWord,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              );
                                            },
                                            onWillAccept:
                                                (data) =>
                                                    !matchedWords.containsValue(
                                                      data,
                                                    ),
                                            onAccept: (data) {
                                              setState(() {
                                                matchedWords[index] = data;
                                                bool isCorrect =
                                                    data ==
                                                    matchItems[index]['word'];
                                                matchResults[index] = isCorrect;

                                                _showFeedback(isCorrect);
                                              });

                                              if (matchedWords.length ==
                                                  matchItems.length) {
                                                Future.delayed(
                                                  const Duration(
                                                    milliseconds: 400,
                                                  ),
                                                  () => _checkAllAnswers(),
                                                );
                                              }
                                            },
                                          );
                                        }),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "© K5 Learning 2019",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (showFeedback)
          Center(
            child: SizedBox(
              width: 150,
              height: 150,
              child: Lottie.asset(
                isCorrectFeedback
                    ? 'assets/animation/correct.json'
                    : 'assets/animation/wrong.json',
              ),
            ),
          ),
      ],
    );
  }
}
