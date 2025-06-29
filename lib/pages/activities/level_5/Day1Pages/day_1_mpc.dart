import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Day1MultipleChoicePage extends StatefulWidget {
  const Day1MultipleChoicePage({super.key});

  @override
  State<Day1MultipleChoicePage> createState() => _Day1MultipleChoicePageState();
}

class _Day1MultipleChoicePageState extends State<Day1MultipleChoicePage> {
  final List<Map<String, dynamic>> questions = [
    {
      'question':
          '1. Which word tells a reader most about the text while previewing it?',
      'options': ['Obey', 'Groom', 'Idea', 'Puppy'],
      'answer': 'Idea',
    },
    {
      'question': '2. What is the problem in the text?',
      'options': [
        'Nick’s parents think that he is not capable of taking care of a puppy.',
        'Nick is allergic to puppies.',
        'Nick’s parents think that puppies are not a lot of work.',
        'Nick’s parents think that the family should get a puppy right away.',
      ],
      'answer':
          'Nick’s parents think that he is not capable of taking care of a puppy.',
    },
    {
      'question': '3. A person who *volunteers* is someone who',
      'options': [
        'Studies for tests.',
        'Does no work at all.',
        'Gets a raise.',
        'Does work without being paid.',
      ],
      'answer': 'Does work without being paid.',
    },
    {
      'question':
          '4. Nick’s parents say he isn’t *capable* of taking care of a puppy. Which word or phrase means *capable*?',
      'options': ['Interested', 'Angry about', 'Afraid of', 'Able to'],
      'answer': 'Able to',
    },
    {
      'question': '5. What does the phrase *have no idea* mean?',
      'options': [
        'Do not understand',
        'Can’t think',
        'Ran out of ideas',
        'Have an active imagination',
      ],
      'answer': 'Do not understand',
    },
  ];

  int currentIndex = 0;
  int correctCount = 0;
  int wrongCount = 0;
  bool finished = false;

  Timer? timer;
  int maxTimePerQuestion = 15;
  int remainingTime = 15;

  int totalCorrectAnswers = 0;
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
      totalCorrectAnswers++;
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
    }
  }

  void resetQuiz() {
    setState(() {
      currentIndex = 0;
      correctCount = 0;
      wrongCount = 0;
      finished = false;
      totalCorrectAnswers = 0;
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
          title: const Text('Day 1 - Quiz Result'),
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
                  'Correct: $totalCorrectAnswers',
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
        title: const Text('Day 1 - Multiple Choice'),
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
