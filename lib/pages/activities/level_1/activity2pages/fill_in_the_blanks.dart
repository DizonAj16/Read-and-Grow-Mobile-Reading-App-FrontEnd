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
    {"text": "The cat sat on a red ____.", "answer": "mat"},
    {"text": "The cat saw a ____.", "answer": "rat"},
    {"text": "Then he ____ to catch it!", "answer": "ran"},
  ];

  final TextEditingController _controller = TextEditingController();

  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  int wrongAnswers = 0;
  bool isFinished = false;
  bool isAnswered = false;
  String userAnswer = "";
  int totalScore = 0;

  static const int maxScore = 100;
  static const int secondsPerQuestion = 10;

  Timer? timer;
  int remainingTime = secondsPerQuestion;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    remainingTime = secondsPerQuestion;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          t.cancel();
          checkAnswer(); // auto check if time runs out
        }
      });
    });
  }

  void checkAnswer() {
    final correct = questions[currentQuestionIndex]['answer']!.toLowerCase();
    final answer = userAnswer.trim().toLowerCase();

    setState(() {
      isAnswered = true;

      if (answer == correct) {
        correctAnswers++;
        // Each correct answer max 33, minus time used
        int perQScore = (maxScore ~/ questions.length);
        int timePenalty = secondsPerQuestion - remainingTime;
        int score = (perQScore - timePenalty).clamp(0, perQScore);
        totalScore += score;
      } else {
        wrongAnswers++;
      }
    });

    timer?.cancel();

    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        if (currentQuestionIndex < questions.length - 1) {
          currentQuestionIndex++;
          _controller.clear();
          userAnswer = "";
          isAnswered = false;
          startTimer();
        } else {
          isFinished = true;
          timer?.cancel();
          widget.onCompleted?.call();
        }
      });
    });
  }

  void resetQuiz() {
    setState(() {
      currentQuestionIndex = 0;
      correctAnswers = 0;
      wrongAnswers = 0;
      userAnswer = "";
      isAnswered = false;
      isFinished = false;
      totalScore = 0;
      _controller.clear();
      startTimer();
    });
  }

  Widget _buildScorePage() {
    final finalScore = correctAnswers == 0 ? 0 : totalScore.clamp(0, maxScore);

    return Container(
      color: Colors.deepPurple.shade50,
      width: double.infinity,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
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
                '🎉 Great Job!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You completed the activity!',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16),
              Text(
                '✅ Correct: $correctAnswers\n❌ Wrong: $wrongAnswers',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              Text(
                'Your Score: $finalScore',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
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
                child: const Text('Try Again', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isFinished) return Scaffold(body: _buildScorePage());

    final current = questions[currentQuestionIndex];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Fill in the Blanks',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Question ${currentQuestionIndex + 1} of ${questions.length}',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 12),
              Text(
                '⏱ Time Left: $remainingTime seconds',
                style: const TextStyle(fontSize: 16, color: Colors.redAccent),
              ),
              const SizedBox(height: 24),
              Text(current['text']!, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple),
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: (val) => setState(() => userAnswer = val),
                  enabled: !isAnswered,
                  decoration: const InputDecoration(
                    hintText: "Type your answer...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    userAnswer.isNotEmpty && !isAnswered ? checkAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text("Submit", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
