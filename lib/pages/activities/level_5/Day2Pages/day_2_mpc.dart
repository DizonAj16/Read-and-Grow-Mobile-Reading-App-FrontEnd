import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Day2MultipleChoicePage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const Day2MultipleChoicePage({super.key, this.onCompleted});

  @override
  State<Day2MultipleChoicePage> createState() => _Day2MultipleChoicePageState();
}

class _Day2MultipleChoicePageState extends State<Day2MultipleChoicePage> {
  final List<Map<String, dynamic>> questions = [
    {
      'question': '1. What does the first sentence tell about this text?',
      'options': [
        'This text is about volunteering at an animal shelter.',
        'This text is about taking shelter during a storm.',
        'This text is about adopting an animal.',
        'This text is about different animals.',
      ],
      'answer': 'This text is about volunteering at an animal shelter.',
    },
    {
      'question':
          '2. What detail does the author include to explain why Nick plays with the puppies?',
      'options': [
        'To help them learn to eat and drink',
        'So he can stop being afraid of dogs',
        'To help them get used to people',
        'So he can learn about the different breeds of dog',
      ],
      'answer': 'To help them get used to people',
    },
    {
      'question': '3. To which word can the suffix –ing be added?',
      'options': ['Also', 'Dogs', 'Care', 'Plenty'],
      'answer': 'Care',
    },
    {
      'question': '4. What is a kennel?',
      'options': [
        'Place for animals',
        'Kind of food',
        'Piece of clothing',
        'Helper',
      ],
      'answer': 'Place for animals',
    },
    {
      'question': '5. Which word means once in a while?',
      'options': ['Often', 'Never', 'Occasionally', 'Daily'],
      'answer': 'Occasionally',
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
    showFeedbackDialog(isCorrect: false, message: "Time's up!");
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pop();
      goToNextQuestion();
    });
  }

  void selectOption(String option) {
    stopTimer();
    final correctAnswer = questions[currentIndex]['answer'];
    final isCorrect = option == correctAnswer;

    if (isCorrect) {
      correctCount++;
      totalScore += remainingTime;
    } else {
      wrongCount++;
    }

    showFeedbackDialog(
      isCorrect: isCorrect,
      message: isCorrect ? 'Correct!' : 'Wrong!',
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pop();
      goToNextQuestion();
    });
  }

  void showFeedbackDialog({required bool isCorrect, required String message}) {
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

  void goToNextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
      });
      startTimer();
    } else {
      setState(() {
        finished = true;
      });
      widget.onCompleted?.call(); // <-- trigger callback if provided
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
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Day 2 - Quiz Result'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Quiz Finished!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  'Correct: $correctCount',
                  style: const TextStyle(fontSize: 22, color: Colors.green),
                ),
                const SizedBox(height: 8),
                Text(
                  'Wrong: $wrongCount',
                  style: const TextStyle(fontSize: 22, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  'Score: ${totalScore.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 22, color: Colors.blue),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: resetQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final questionData = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Day 2 - Multiple Choice'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (currentIndex + 1) / questions.length,
              backgroundColor: Colors.grey.shade300,
              color: Colors.deepPurple,
              minHeight: 8,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Q ${currentIndex + 1}/${questions.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Time Left: $remainingTime s',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      questionData['question'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...questionData['options'].map<Widget>((option) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ElevatedButton(
                          onPressed: () => selectOption(option),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 12,
                            ),
                          ),
                          child: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
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
    );
  }
}
