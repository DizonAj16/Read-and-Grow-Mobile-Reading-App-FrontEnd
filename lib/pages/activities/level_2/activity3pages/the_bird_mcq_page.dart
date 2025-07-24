import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TheBirdMultipleChoicePage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const TheBirdMultipleChoicePage({super.key, this.onCompleted});

  @override
  State<TheBirdMultipleChoicePage> createState() =>
      _TheBirdMultipleChoicePageState();
}

class _TheBirdMultipleChoicePageState extends State<TheBirdMultipleChoicePage> {
  final List<Map<String, dynamic>> questions = [
    {
      "question": "Where is the bird?",
      "options": ["In the Sky", "In the Bed", "In the car", "In the box"],
      "answer": "In the Sky",
    },
    {
      "question": "What is in the tree?",
      "options": ["a kite", "a nest", "a rope swing", "a cat"],
      "answer": "a nest",
    },
    {
      "question": "What does the bird do at the end of the story?",
      "options": ["flies away", "sing a song", "sleep in nest", "eats a worm"],
      "answer": "flies away",
    },
  ];

  int currentIndex = 0;
  int correctCount = 0;
  int wrongCount = 0;
  double totalScore = 0;
  bool finished = false;

  Timer? timer;
  int remainingTime = 15;
  int maxTime = 15;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    remainingTime = maxTime;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
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
    showFeedbackDialog(false, "Time’s up!");

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      moveToNext();
    });
  }

  void selectOption(String option) {
    stopTimer();

    final correctAnswer = questions[currentIndex]["answer"];
    final isCorrect = option == correctAnswer;

    if (isCorrect) {
      correctCount++;
      totalScore += remainingTime;
    } else {
      wrongCount++;
    }

    showFeedbackDialog(isCorrect, isCorrect ? "Correct!" : "Wrong!");

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      moveToNext();
    });
  }

  void moveToNext() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
      });
      startTimer();
    } else {
      setState(() {
        finished = true;
      });
      _saveQuizResults(); // Save to shared preferences
      widget.onCompleted?.call();
    }
  }

  Future<void> _saveQuizResults() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    await prefs.setDouble('mcq_score', totalScore);
    await prefs.setInt('mcq_correct', correctCount);
    await prefs.setInt('mcq_wrong', wrongCount);
    await prefs.setString('mcq_timestamp', now.toIso8601String());
  }

  void showFeedbackDialog(bool isCorrect, String message) {
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
                  message,
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
  }

  void resetQuiz() {
    setState(() {
      currentIndex = 0;
      correctCount = 0;
      wrongCount = 0;
      totalScore = 0;
      finished = false;
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
        appBar: AppBar(title: const Text('The Bird - Quiz')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Quiz Completed!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
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
                'Final Score: ${totalScore.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 20, color: Colors.blue),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: resetQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text("Try Again", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      );
    }

    final question = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('The Bird - Multiple Choice')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (currentIndex + 1) / questions.length,
              color: Colors.deepPurple,
              backgroundColor: Colors.grey.shade300,
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
            const SizedBox(height: 16),
            Text(
              question["question"],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 3,
                children: List.generate(question["options"].length, (index) {
                  final option = question["options"][index];
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
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10, bottom: 10),
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
