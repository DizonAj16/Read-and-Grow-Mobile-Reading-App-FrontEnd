import 'dart:async';

import 'package:flutter/material.dart';

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
      "question": "Where is the bird ?",
      "options": ["In the Sky", "In the Bed", "In the car", "In the box"],
      "answer": "In the Sky",
    },
    {
      "question": "What is in the tree?",
      "options": ["a kite", "a nest", "a rope swing", "a cat"],
      "answer": "a nest",
    },
    {
      "question": "What does the bird do at the end of the story",
      "options": [
        "flies away",
        "sing a song",
        "sleep it nest ",
        "eats  a worm",
      ],
      "answer": "flies away",
    },
  ];

  int currentQuestionIndex = 0;
  bool answered = false;
  String? selectedOption;
  Timer? _timer;
  int timeRemaining = 10;
  bool finished = false;

  int wrongAnswers = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    timeRemaining = 10;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          timeRemaining--;
        });
      }

      if (timeRemaining == 0) {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    if (!answered) {
      wrongAnswers++;
      _goToNextQuestion();
    }
  }

  void selectOption(String option) {
    if (answered) return;

    setState(() {
      answered = true;
      selectedOption = option;
      if (option != questions[currentQuestionIndex]["answer"]) {
        wrongAnswers++;
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      _goToNextQuestion();
    });
  }

  void _goToNextQuestion() {
    _timer?.cancel();
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        answered = false;
        selectedOption = null;
      });
      _startTimer();
    } else {
      setState(() {
        finished = true;
      });
      widget.onCompleted?.call();
    }
  }

  Color _getOptionColor(String option) {
    if (!answered) return Colors.grey.shade200;
    if (option == questions[currentQuestionIndex]["answer"]) {
      return Colors.green.shade200;
    } else if (option == selectedOption) {
      return Colors.red.shade200;
    }
    return Colors.grey.shade200;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return _buildScorePage();
    }

    final question = questions[currentQuestionIndex];
    final options = List<String>.from(question["options"]);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Time: $timeRemaining",
          style: const TextStyle(fontSize: 18, color: Colors.red),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            question["question"],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        ...options.map(
          (option) => GestureDetector(
            onTap: () => selectOption(option),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _getOptionColor(option),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple),
              ),
              child: Text(
                option,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScorePage() {
    int finalScore = 30 - (wrongAnswers * 10);
    if (finalScore < 0) finalScore = 0;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.2),
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
            Text("Wrong: $wrongAnswers", style: const TextStyle(fontSize: 20)),
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
              onPressed: () {
                setState(() {
                  currentQuestionIndex = 0;
                  answered = false;
                  selectedOption = null;
                  finished = false;
                  wrongAnswers = 0;
                });
                _startTimer();
              },
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
    );
  }
}
