import 'dart:async';

import 'package:flutter/material.dart';

class PenguinMultipleChoicePage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const PenguinMultipleChoicePage({super.key, this.onCompleted});

  @override
  State<PenguinMultipleChoicePage> createState() =>
      _PenguinMultipleChoicePageState();
}

class _PenguinMultipleChoicePageState extends State<PenguinMultipleChoicePage> {
  int currentIndex = 0;
  int score = 0;
  int wrongAnswers = 0;
  bool answered = false;
  bool finished = false;
  int remainingTime = 60;
  late Timer timer;

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

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingTime > 0) {
        setState(() => remainingTime--);
      } else {
        handleTimeout();
      }
    });
  }

  void handleTimeout() {
    timer.cancel();
    setState(() => finished = true);
    widget.onCompleted?.call();
  }

  void selectOption(String selectedOption) {
    if (answered || finished) return;

    setState(() {
      answered = true;
      if (selectedOption == questions[currentIndex]['answer']) {
        score++;
      } else {
        wrongAnswers++;
      }
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (currentIndex < questions.length - 1) {
        setState(() {
          currentIndex++;
          answered = false;
        });
      } else {
        timer.cancel();
        setState(() => finished = true);
        widget.onCompleted?.call();
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Widget buildQuestion() {
    final question = questions[currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Penguin Quiz",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Time Left: $remainingTime s",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 32),
        Text(
          question['question'],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ...question['options'].map<Widget>((option) {
          final correctAnswer = question['answer'];
          Color color = Colors.white;
          if (answered) {
            if (option == correctAnswer) {
              color = Colors.green.shade200;
            } else if (option == option) {
              color = Colors.red.shade200;
            }
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton(
              onPressed: () => selectOption(option),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(option, style: const TextStyle(fontSize: 18)),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget buildScorePage() {
    final int total = questions.length;
    final int finalScore =
        (score * 100 ~/ total) - wrongAnswers * 5 - (60 - remainingTime);
    final bool passed = score >= (total / 2);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          passed ? Icons.emoji_events : Icons.mood,
          color: passed ? Colors.amber : Colors.orange,
          size: 100,
        ),
        const SizedBox(height: 20),
        Text(
          passed ? "Well Done!" : "Keep Going!",
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text("Correct: $score / $total", style: const TextStyle(fontSize: 20)),
        Text(
          "Wrong: $wrongAnswers",
          style: const TextStyle(fontSize: 20, color: Colors.red),
        ),
        const SizedBox(height: 12),
        Text(
          "Final Score: $finalScore",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            setState(() {
              currentIndex = 0;
              score = 0;
              wrongAnswers = 0;
              finished = false;
              remainingTime = 60;
              answered = false;
            });
            startTimer();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text("Try Again", style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: finished ? buildScorePage() : buildQuestion(),
        ),
      ),
    );
  }
}
