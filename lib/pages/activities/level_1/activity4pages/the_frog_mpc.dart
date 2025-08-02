import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class GreenFrogMultipleChoicePage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const GreenFrogMultipleChoicePage({super.key, this.onCompleted});

  @override
  State<GreenFrogMultipleChoicePage> createState() =>
      _GreenFrogMultipleChoicePageState();
}

class _GreenFrogMultipleChoicePageState
    extends State<GreenFrogMultipleChoicePage>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'What color is the frog?',
      'options': ['brown', 'purple', 'yellow', 'green'],
      'answer': 'green',
    },
    {
      'question': 'Where does the frog live?',
      'options': ['in the ocean', 'in a puddle', 'in a pond', 'in the river'],
      'answer': 'in a pond',
    },
    {
      'question': 'What does the frog eat?',
      'options': ['flowers', 'flies', 'crickets', 'fish'],
      'answer': 'flies',
    },
  ];

  int currentIndex = 0;
  int correctCount = 0;
  int wrongCount = 0;
  bool finished = false;

  Timer? timer;
  int maxTimePerQuestion = 75;
  int remainingTime = 75;

  int totalScore = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    for (var question in questions) {
      question['options'].shuffle();
    }

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    startTimer();
  }

  void startTimer() {
    remainingTime = maxTimePerQuestion;
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
    wrongCount++;
    totalScore -= 10;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            contentPadding: const EdgeInsets.all(16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Lottie.asset(
                    'assets/animation/wrong.json',
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Time\'s up!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pop();
      if (currentIndex < questions.length - 1) {
        setState(() {
          currentIndex++;
        });
        startTimer();
      } else {
        setState(() {
          finished = true;
        });
        widget.onCompleted?.call();
      }
    });
  }

  void selectOption(String option) {
    stopTimer();

    final correctAnswer = questions[currentIndex]['answer'];
    final isCorrect = option == correctAnswer;

    if (isCorrect) {
      correctCount++;
      totalScore += 10;
    } else {
      wrongCount++;
      totalScore -= 10;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            contentPadding: const EdgeInsets.all(16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Lottie.asset(
                    isCorrect
                        ? 'assets/animation/correct.json'
                        : 'assets/animation/wrong.json',
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isCorrect ? 'Correct!' : 'Wrong!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pop();
      if (currentIndex < questions.length - 1) {
        setState(() {
          currentIndex++;
        });
        startTimer();
      } else {
        setState(() {
          finished = true;
        });
        widget.onCompleted?.call();
      }
    });
  }

  void resetQuiz() {
    setState(() {
      currentIndex = 0;
      correctCount = 0;
      wrongCount = 0;
      finished = false;
      totalScore = 0;
    });
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Quiz Finished!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                'Correct Answers: $correctCount',
                style: const TextStyle(fontSize: 20, color: Colors.green),
              ),
              const SizedBox(height: 8),
              Text(
                'Wrong Answers: $wrongCount',
                style: const TextStyle(fontSize: 20, color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text(
                'Score: $totalScore / 30',
                style: const TextStyle(fontSize: 20, color: Colors.blue),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: resetQuiz,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.deepPurple,
                ),
                child: const Text('Try Again', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      );
    }

    final questionData = questions[currentIndex];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (currentIndex + 1) / questions.length,
              backgroundColor: Colors.grey.shade300,
              color: Colors.deepPurple,
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${currentIndex + 1} of ${questions.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                remainingTime <= 10
                    ? ScaleTransition(
                      scale: _pulseAnimation,
                      child: const Icon(Icons.access_time, color: Colors.red),
                    )
                    : const Icon(Icons.access_time, color: Colors.green),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child:
                  remainingTime <= 10
                      ? ScaleTransition(
                        scale: _pulseAnimation,
                        child: Text(
                          'Time: $remainingTime s',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                      : Text(
                        'Time: $remainingTime s',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
            const SizedBox(height: 8),
            Text(
              questionData['question'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3,
                children:
                    questionData['options'].map<Widget>((option) {
                      return ElevatedButton(
                        onPressed: () => selectOption(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                child: Text(
                  "© K5 Learning 2019",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
