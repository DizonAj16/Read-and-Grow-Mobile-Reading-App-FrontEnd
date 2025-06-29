import 'dart:async';

import 'package:flutter/material.dart';

class FillInTheBlanksPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const FillInTheBlanksPage({super.key, this.onCompleted});

  @override
  State<FillInTheBlanksPage> createState() => _FillInTheBlanksPageState();
}

class _FillInTheBlanksPageState extends State<FillInTheBlanksPage> {
  final List<Map<String, String>> questions = [
    {"text": "Penguins live in __ places.", "answer": "cold"},
    {"text": "Penguins cannot __.", "answer": "fly"},
    {"text": "They use their wings to __.", "answer": "swim"},
  ];

  final TextEditingController answerController = TextEditingController();
  int currentIndex = 0;
  int correct = 0;
  int wrong = 0;
  int timeLeft = 60;
  bool isFinished = false;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    answerController.dispose();
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        handleTimeout();
      }
    });
  }

  void handleTimeout() {
    timer?.cancel();
    if (!isFinished) {
      setState(() {
        isFinished = true;
      });
      widget.onCompleted?.call();
    }
  }

  void checkAnswer() {
    String userAnswer = answerController.text.trim().toLowerCase();
    String correctAnswer = questions[currentIndex]["answer"]!.toLowerCase();

    if (userAnswer == correctAnswer) {
      correct++;
    } else {
      wrong++;
    }

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        answerController.clear();
      });
    } else {
      timer?.cancel();
      setState(() {
        isFinished = true;
      });
      widget.onCompleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          "Fill in the Blanks",
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          "Type the missing word to complete each sentence.",
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (!isFinished)
          Text(
            "Time Left: $timeLeft",
            style: const TextStyle(fontSize: 20, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 20),
        if (!isFinished) _buildQuizContent() else _buildScorePage(),
      ],
    );
  }

  Widget _buildQuizContent() {
    return Column(
      children: [
        Text(
          questions[currentIndex]["text"]!,
          style: const TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: answerController,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: "Enter your answer",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: answerController.text.trim().isEmpty ? null : checkAnswer,
          child: const Text("Submit"),
        ),
      ],
    );
  }

  Widget _buildScorePage() {
    int score =
        ((correct * 100) ~/ questions.length) - wrong * 10 - (60 - timeLeft);

    if (score < 0) score = 0;

    return Column(
      children: [
        Text(
          score >= 60 ? "Great Job!" : "Keep Going!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: score >= 60 ? Colors.green : Colors.orange,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text("Correct: $correct", style: const TextStyle(fontSize: 18)),
        Text("Wrong: $wrong", style: const TextStyle(fontSize: 18)),
        Text("Final Score: $score", style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() {
              currentIndex = 0;
              correct = 0;
              wrong = 0;
              timeLeft = 60;
              isFinished = false;
              answerController.clear();
              startTimer();
            });
          },
          child: const Text("Try Again"),
        ),
      ],
    );
  }
}
