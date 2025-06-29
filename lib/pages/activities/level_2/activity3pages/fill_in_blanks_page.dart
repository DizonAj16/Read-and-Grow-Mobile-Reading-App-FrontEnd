import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FillInTheBlanksPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const FillInTheBlanksPage({super.key, this.onCompleted});

  @override
  State<FillInTheBlanksPage> createState() => _FillInTheBlanksPageState();
}

class _FillInTheBlanksPageState extends State<FillInTheBlanksPage> {
  final List<Map<String, dynamic>> questions = [
    {"template": "The bird ____ loudly.", "answer": "sings"},
    {"template": "It flies in the ___.", "answer": "sky"},
    {"template": "The bird is in a ___.", "answer": "nest"},
  ];

  int currentIndex = 0;
  int totalScore = 0;
  int wrongAnswers = 0;

  final TextEditingController _controller = TextEditingController();
  bool? isCorrect;
  bool isFinished = false;

  Timer? timer;
  int remainingTime = 60;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    remainingTime = 60;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        t.cancel();
        handleTimeout();
      }
    });
  }

  void stopTimer() {
    timer?.cancel();
  }

  void handleTimeout() {
    wrongAnswers++;
    _showFeedbackDialog(
      isCorrect: false,
      title: "Time's up!",
      message: "Press OK to continue.",
      animation: 'assets/animation/wrong.json',
    );
  }

  void checkAnswer() {
    stopTimer();
    String userAnswer = _controller.text.trim().toLowerCase();
    String correctAnswer = questions[currentIndex]['answer'];

    setState(() {
      isCorrect = userAnswer == correctAnswer;
      if (isCorrect!) {
        totalScore += remainingTime;
      } else {
        wrongAnswers++;
      }
    });

    _showFeedbackDialog(
      isCorrect: isCorrect!,
      title: isCorrect! ? 'Correct!' : 'Wrong!',
      message: 'Press OK to continue.',
      animation:
          isCorrect!
              ? 'assets/animation/correct.json'
              : 'assets/animation/wrong.json',
    );
  }

  void _showFeedbackDialog({
    required bool isCorrect,
    required String title,
    required String message,
    required String animation,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            contentPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: Lottie.asset(animation, repeat: false),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                Text(message),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (currentIndex < questions.length - 1) {
                    setState(() {
                      currentIndex++;
                      _controller.clear();
                      this.isCorrect = null;
                    });
                    startTimer();
                  } else {
                    setState(() {
                      isFinished = true;
                    });
                    widget.onCompleted?.call();
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void resetQuiz() {
    setState(() {
      currentIndex = 0;
      totalScore = 0;
      wrongAnswers = 0;
      isCorrect = null;
      isFinished = false;
      _controller.clear();
    });
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Widget _buildScorePage() {
    int finalScore = 30 - (wrongAnswers * 10);
    if (finalScore < 0) finalScore = 0;

    return SafeArea(
      child: Container(
        color: Colors.deepPurple.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
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
                    "You completed the quiz!",
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Correct: ${questions.length - wrongAnswers} / ${questions.length}",
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Wrong: $wrongAnswers",
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Final Score: $finalScore",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => resetQuiz(),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Try Again"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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

  @override
  Widget build(BuildContext context) {
    if (isFinished) return _buildScorePage();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Fill in the Blanks",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Type the correct word to complete the sentence before time runs out!",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text(
              "Time Left: $remainingTime sec",
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 24),
            Text(
              questions[currentIndex]["template"],
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Type your answer here...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: checkAnswer,
                child: const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
