import 'dart:async';

import 'package:flutter/material.dart';

class DragTheWordToPicturePage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const DragTheWordToPicturePage({super.key, this.onCompleted});

  @override
  State<DragTheWordToPicturePage> createState() =>
      DragTheWordToPicturePageState();
}

class DragTheWordToPicturePageState extends State<DragTheWordToPicturePage>
    with TickerProviderStateMixin {
  final List<Map<String, String>> allItems = [
    {"word": "sky", "image": "assets/activity_images/sky.jpg"},
    {"word": "bird", "image": "assets/activity_images/mordicai.jpg"},
    {"word": "tree", "image": "assets/activity_images/tree.png"},
    {"word": "nest", "image": "assets/activity_images/nest.png"},
  ];

  late List<Map<String, String>> shuffledItems;
  late List<String> shuffledWords;
  final List<String> matchedWords = [];
  final Map<int, Color> borderColors = {};
  Timer? timer;
  int timeLeft = 60;
  int wrongAnswers = 0;
  int score = 100;
  bool showScore = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed &&
          timeLeft <= 10 &&
          timeLeft > 0) {
        _pulseController.forward();
      }
    });

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startGame();
  }

  void _startGame() {
    shuffledItems = List.from(allItems)..shuffle();
    shuffledWords =
        shuffledItems.map((item) => item["word"]!).toList()..shuffle();
    matchedWords.clear();
    borderColors.clear();
    timeLeft = 60;
    wrongAnswers = 0;
    score = 100;
    showScore = false;

    _pulseController.reset();

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
          if (timeLeft == 10) {
            _pulseController.forward();
          }
        });
      } else {
        timer.cancel();
        _finishGame();
      }
    });
  }

  void _handleMatch(String word, int index) {
    final correctWord = shuffledItems[index]["word"];
    final isCorrect = word == correctWord;

    setState(() {
      borderColors[index] = isCorrect ? Colors.green : Colors.red;
      if (isCorrect && !matchedWords.contains(word)) {
        matchedWords.add(word);
      } else if (!isCorrect) {
        wrongAnswers++;
      }
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() => borderColors.remove(index));
      if (matchedWords.length == shuffledItems.length) {
        _finishGame();
      }
    });
  }

  void _finishGame() {
    timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    int correct = matchedWords.length;
    int baseScore = correct * 25;
    int timePenalty = 60 - timeLeft;
    int finalScore = baseScore - timePenalty;

    if (correct == 0 || finalScore < 0) {
      finalScore = 0;
    }

    setState(() {
      score = finalScore;
      showScore = true;
    });

    widget.onCompleted?.call();
  }

  Widget _buildWordCard(String word, bool matched) {
    return Container(
      constraints: const BoxConstraints(minWidth: 60, maxWidth: 100),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: matched ? Colors.grey.shade400 : Colors.deepPurple.shade100,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.shade100,
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Text(
        word,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildGamePage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Match the Words to the Pictures',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Drag each word to the matching picture on the right.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Pulsing Timer
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: (timeLeft <= 10) ? _pulseAnimation.value : 1.0,
                child: Text(
                  '⏰ Time Left: $timeLeft s',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: timeLeft <= 10 ? Colors.red : Colors.black,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children:
                            shuffledWords.map((word) {
                              final matched = matchedWords.contains(word);
                              return matched
                                  ? const SizedBox(height: 40)
                                  : Draggable<String>(
                                    data: word,
                                    feedback: Material(
                                      color: Colors.transparent,
                                      child: _buildWordCard(word, false),
                                    ),
                                    childWhenDragging: const SizedBox(
                                      height: 40,
                                    ),
                                    child: _buildWordCard(word, false),
                                  );
                            }).toList(),
                      ),
                    ),
                    const Spacer(flex: 1),
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(shuffledItems.length, (index) {
                          final item = shuffledItems[index];
                          final imagePath = item["image"]!;
                          final word = item["word"]!;
                          final matched = matchedWords.contains(word);

                          return DragTarget<String>(
                            onAccept: (data) => _handleMatch(data, index),
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        borderColors[index] ??
                                        Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset(
                                        imagePath,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                      if (matched)
                                        Positioned(
                                          bottom: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            color: Colors.white70,
                                            child: Text(
                                              word,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorePage() {
    return Container(
      color: Colors.deepPurple.shade50,
      width: double.infinity,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎉 Great Job!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You completed the activity!',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16),
              Text(
                '✅ Correct: ${matchedWords.length}\n❌ Wrong: $wrongAnswers',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              Text(
                'Your Score: $score',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Try Again', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: showScore ? _buildScorePage() : _buildGamePage());
  }
}
