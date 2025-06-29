import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class MatchPicturesPage extends StatefulWidget {
  final VoidCallback? onCompleted;
  const MatchPicturesPage({super.key, this.onCompleted});

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

  List<Map<String, String>> shuffledItems = [];
  List<String> remainingWords = [];
  int currentIndex = 0;
  int correctAnswers = 0;
  int wrongAnswers = 0;
  int remainingTime = 60;
  Timer? timer;

  bool _completedQuiz = false;
  bool _showScorePage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetGame();
    });
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        t.cancel();
        _handleTimeout();
      }
    });
  }

  void stopTimer() {
    timer?.cancel();
  }

  void _handleTimeout() {
    wrongAnswers++;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildFeedbackDialog(false, timeout: true),
    ).then((_) => _nextStep());
  }

  void _checkAnswer(String selectedWord) {
    final correctWord = shuffledItems[currentIndex]["word"];
    final isCorrect = selectedWord == correctWord;

    if (isCorrect) {
      correctAnswers++;
      setState(() {
        remainingWords.remove(selectedWord);
      });
    } else {
      wrongAnswers++;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildFeedbackDialog(isCorrect),
    ).then((_) => _nextStep());
  }

  void _nextStep() {
    if (currentIndex < shuffledItems.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      _showFinalScorePage();
    }
  }

  Widget _buildFeedbackDialog(bool isCorrect, {bool timeout = false}) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 150,
            width: 150,
            child: Lottie.asset(
              isCorrect
                  ? 'assets/animation/correct.json'
                  : 'assets/animation/wrong.json',
              repeat: false,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            timeout ? "Time's up!" : (isCorrect ? "Correct!" : "Wrong!"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          const Text('Press OK to continue.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    );
  }

  void _showFinalScorePage() {
    if (_completedQuiz) return;
    stopTimer();
    setState(() {
      _completedQuiz = true;
      _showScorePage = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      widget.onCompleted?.call();
    });
  }

  void _resetGame() {
    timer?.cancel();
    setState(() {
      shuffledItems = List<Map<String, String>>.from(originalItems)..shuffle();
      remainingWords = originalItems.map((e) => e['word']!).toList();
      currentIndex = 0;
      correctAnswers = 0;
      wrongAnswers = 0;
      remainingTime = 60;
      _completedQuiz = false;
      _showScorePage = false;
    });
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showScorePage) {
      int score =
          ((remainingTime / 60) * 100 - wrongAnswers * 10)
              .clamp(0, 100)
              .round();

      return Scaffold(
        backgroundColor: Colors.deepPurple.shade50,
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "🎉 Great Job!",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "You completed the activity!",
                      style: TextStyle(fontSize: 20, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.shade100,
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildScoreRow("Final Score", "$score / 100"),
                          const SizedBox(height: 12),
                          _buildScoreRow("Wrong Answers", "$wrongAnswers"),
                          const SizedBox(height: 12),
                          _buildScoreRow("Time Left", "$remainingTime s"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _resetGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                        ),
                        child: const Text(
                          "🔁 Try Again",
                          style: TextStyle(fontSize: 18, color: Colors.white),
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
    }

    if (shuffledItems.isEmpty || currentIndex >= shuffledItems.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentItem = shuffledItems[currentIndex];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '⏰ Time: $remainingTime s',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Tap the correct word for the picture.",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                  child: Image.asset(
                    currentItem["image"] ?? '',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children:
                    remainingWords
                        .map(
                          (word) => ElevatedButton(
                            onPressed: () => _checkAnswer(word),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                            child: Text(
                              word,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        )
                        .toList(),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildScoreRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 18, color: Colors.black87)),
      Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    ],
  );
}
