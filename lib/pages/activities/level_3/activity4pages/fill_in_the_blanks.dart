import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FillInTheBlanksPage extends StatefulWidget {
  const FillInTheBlanksPage({super.key});

  @override
  State<FillInTheBlanksPage> createState() => _FillInTheBlanksPageState();
}

class _FillInTheBlanksPageState extends State<FillInTheBlanksPage> {
  final List<Map<String, dynamic>> questions = [
    {
      "template": "The frog is the color ____.",
      "answers": ["green"],
    },
    {
      "template": "It moves its ____ and ____.",
      "answers": ["legs", "arms"],
    },
    {
      "template": "The ____ sits on a lily pad.",
      "answers": ["frog"],
    },
  ];

  int currentIndex = 0;
  int correctAnswers = 0;
  int wrongAnswers = 0;
  double score = 0;

  List<TextEditingController> controllers = [];
  bool? isCorrect;
  bool isFinished = false;

  Timer? timer;
  int maxTime = 60; // 60 seconds per question
  int remainingTime = 60;

  @override
  void initState() {
    super.initState();
    prepareControllers();
    startTimer();
  }

  void prepareControllers() {
    controllers = List.generate(
      questions[currentIndex]['answers'].length,
      (_) => TextEditingController(),
    );
  }

  void startTimer() {
    remainingTime = maxTime;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        t.cancel();
        autoSubmit();
      }
    });
  }

  void autoSubmit() {
    setState(() {
      isCorrect = false;
      wrongAnswers++;
    });

    showFeedbackDialog();
  }

  void checkAnswer() {
    List<String> correctAnswerList = List<String>.from(
      questions[currentIndex]['answers'],
    );
    List<String> userAnswers =
        controllers.map((c) => c.text.trim().toLowerCase()).toList();

    bool allCorrect = true;

    for (int i = 0; i < correctAnswerList.length; i++) {
      if (userAnswers[i] != correctAnswerList[i]) {
        allCorrect = false;
        break;
      }
    }

    setState(() {
      isCorrect = allCorrect;
      if (isCorrect!) {
        correctAnswers++;
        score += remainingTime; // Faster answers give more score
      } else {
        wrongAnswers++;
      }
    });

    timer?.cancel();
    showFeedbackDialog();
  }

  void showFeedbackDialog() {
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
                  height: 150,
                  width: 150,
                  child: Lottie.asset(
                    isCorrect!
                        ? 'assets/animation/correct.json'
                        : 'assets/animation/wrong.json',
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isCorrect! ? 'Correct!' : 'Wrong!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCorrect! ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Press OK to continue.'),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (currentIndex < questions.length - 1) {
                    setState(() {
                      currentIndex++;
                      isCorrect = null;
                    });
                    prepareControllers();
                    startTimer();
                  } else {
                    setState(() {
                      isFinished = true;
                    });
                    timer?.cancel();
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
      correctAnswers = 0;
      wrongAnswers = 0;
      isCorrect = null;
      isFinished = false;
      score = 0;
    });
    prepareControllers();
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isFinished) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fill in the Blanks')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Great job!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                'Score: ${score.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 22),
              ),
              Text(
                'Correct Answers: $correctAnswers',
                style: const TextStyle(fontSize: 22),
              ),
              Text(
                'Wrong Answers: $wrongAnswers',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: resetQuiz,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = questions[currentIndex];
    final displayedText = currentQuestion['template'].replaceAll(
      '____',
      '______',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Fill in the Blanks')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Time Left: $remainingTime s',
                style: const TextStyle(fontSize: 22, color: Colors.red),
              ),
              const SizedBox(height: 20),
              Text(
                displayedText,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ...List.generate(controllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 200,
                    child: TextField(
                      controller: controllers[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.blueAccent,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.blueAccent,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.deepPurple,
                            width: 3,
                          ),
                        ),
                        hintText: 'Answer ${index + 1}',
                        hintStyle: const TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.lightBlue.shade50,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 30),
              SizedBox(
                width: 120,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    bool anyEmpty = controllers.any(
                      (c) => c.text.trim().isEmpty,
                    );
                    if (anyEmpty) return;
                    checkAnswer();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
