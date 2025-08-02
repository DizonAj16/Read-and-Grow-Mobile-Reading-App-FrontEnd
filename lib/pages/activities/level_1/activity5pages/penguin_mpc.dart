import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PenguinMultipleChoicePage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const PenguinMultipleChoicePage({super.key, this.onCompleted});

  @override
  State<PenguinMultipleChoicePage> createState() =>
      _PenguinMultipleChoicePageState();
}

class _PenguinMultipleChoicePageState extends State<PenguinMultipleChoicePage> {
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'Where do penguins live?',
      'options': ['Africa', 'Antarctica', 'Asia', 'Australia'],
      'answer': 'Antarctica',
    },
    {
      'question': 'What do penguins eat?',
      'options': ['Bananas', 'Fish', 'Grass', 'Meat'],
      'answer': 'Fish',
    },
    {
      'question': 'Can penguins fly?',
      'options': ['Yes', 'No'],
      'answer': 'No',
    },
  ];

  int currentIndex = 0;
  int correctCount = 0;
  int wrongCount = 0;
  bool finished = false;

  Timer? timer;
  int maxTimePerQuestion = 15;
  int remainingTime = 15;

  double totalScore = 0;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    remainingTime = maxTimePerQuestion;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingTime > 0) {
        setState(() => remainingTime--);
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
                  "Time's up!",
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
      nextQuestion();
    });
  }

  void selectOption(String selected) {
    stopTimer();
    final correctAnswer = questions[currentIndex]['answer'];
    final isCorrect = selected == correctAnswer;

    if (isCorrect) {
      correctCount++;
      totalScore += remainingTime;
    } else {
      wrongCount++;
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
                  isCorrect ? "Correct!" : "Wrong!",
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
      nextQuestion();
    });
  }

  void nextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
      startTimer();
    } else {
      setState(() => finished = true);
      widget.onCompleted?.call();
    }
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
                "Quiz Finished!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                "Total Correct Answers: $correctCount",
                style: const TextStyle(fontSize: 20, color: Colors.green),
              ),
              const SizedBox(height: 8),
              Text(
                "Total Score: ${totalScore.toStringAsFixed(1)}",
                style: const TextStyle(fontSize: 20, color: Colors.blue),
              ),
              const SizedBox(height: 8),
              Text(
                "Wrong Answers: $wrongCount",
                style: const TextStyle(fontSize: 20, color: Colors.red),
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

    final question = questions[currentIndex];

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
                Text(
                  'Time: $remainingTime s',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              question['question'],
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
                    question['options'].map<Widget>((option) {
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
