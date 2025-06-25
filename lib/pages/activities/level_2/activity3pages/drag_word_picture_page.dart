import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DragTheWordToPicturePage extends StatefulWidget {
  const DragTheWordToPicturePage({super.key});

  @override
  State<DragTheWordToPicturePage> createState() =>
      _DragTheWordToPicturePageState();
}

class _DragTheWordToPicturePageState extends State<DragTheWordToPicturePage>
    with SingleTickerProviderStateMixin {
  final List<Map<String, String>> matchItems = [
    {"word": "sky", "image": "assets/activity_images/sky.jpg"},
    {"word": "bird", "image": "assets/activity_images/mordicai.jpg"},
    {"word": "tree", "image": "assets/activity_images/tree.png"},
    {"word": "nest", "image": "assets/activity_images/nest.png"},
  ];

  late List<String> shuffledWords;
  Map<int, String> matchedWords = {};
  Map<int, bool> matchResults = {};

  double opacityLevel = 1.0;

  // Lottie feedback
  bool showFeedback = false;
  bool isCorrectFeedback = true;

  @override
  void initState() {
    super.initState();
    _shuffleWords();
  }

  void _shuffleWords() {
    shuffledWords = matchItems.map((item) => item['word']!).toList()..shuffle();
  }

  void _animatedReset() async {
    setState(() {
      opacityLevel = 0.0;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      matchedWords.clear();
      matchResults.clear();
      _shuffleWords(); // Shuffle words every reset
    });

    await Future.delayed(const Duration(milliseconds: 150));

    setState(() {
      opacityLevel = 1.0;
    });
  }

  void _checkAllAnswers() {
    int correctCount = 0;

    for (int i = 0; i < matchItems.length; i++) {
      if (matchedWords[i] == matchItems[i]['word']) {
        correctCount++;
      }
    }

    if (correctCount >= 2) {
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
              'You got $correctCount out of ${matchItems.length} correct.',
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
                },
                child: const Text('OK'),
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
              'You only got $correctCount correct. Do you want to retry?',
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
                },
                child: const Text('OK'),
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text("Matching Exercise")),
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
                          duration: const Duration(milliseconds: 400),
                          opacity: opacityLevel,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "1. Drag the word to the matching picture.",
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Draggable Words
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children:
                                          shuffledWords.map((word) {
                                            final isUsed = matchedWords
                                                .containsValue(word);

                                            Widget wordTile = Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
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
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );

                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8.0,
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

                                  const SizedBox(width: 40),

                                  // Drop Targets with Images
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: List.generate(matchItems.length, (
                                        index,
                                      ) {
                                        final image =
                                            matchItems[index]['image']!;
                                        final matchedWord = matchedWords[index];
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
                                              height: 140,
                                              padding: const EdgeInsets.all(8),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
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
                                                    height: 100,
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
                                                                fontSize: 16,
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

                                              // Show feedback animation
                                              _showFeedback(isCorrect);
                                            });

                                            if (matchedWords.length ==
                                                matchItems.length) {
                                              Future.delayed(
                                                const Duration(
                                                  milliseconds: 400,
                                                ),
                                                () {
                                                  _checkAllAnswers();
                                                },
                                              );
                                            }
                                          },
                                        );
                                      }),
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

        // Lottie Feedback Overlay
        if (showFeedback)
          Center(
            child: Container(
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
