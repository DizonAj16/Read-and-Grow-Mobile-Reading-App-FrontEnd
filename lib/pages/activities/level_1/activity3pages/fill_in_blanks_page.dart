import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FillInTheBlanksPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const FillInTheBlanksPage({super.key, this.onCompleted});

  @override
  State<FillInTheBlanksPage> createState() => _FillInTheBlanksPageState();
}

class _FillInTheBlanksPageState extends State<FillInTheBlanksPage>
    with SingleTickerProviderStateMixin {
  final List<Map<String, String>> questions = [
    {"text": "The bird ____ loudly.", "answer": "sings"},
    {"text": "It flies in the ___.", "answer": "sky"},
    {"text": "The bird is in a ___.", "answer": "nest"},
  ];

  final TextEditingController _controller = TextEditingController();

  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  int wrongAnswers = 0;
  int totalScore = 0;
  int remainingTime = totalTime;
  bool isAnswered = false;
  bool isFinished = false;
  String userAnswer = "";

  static const int maxScore = 100;
  static const int totalTime = 120;

  Timer? timer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    questions.shuffle(); // Shuffle the questions

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(_pulseController);

    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    remainingTime = totalTime;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;

          if (remainingTime == 10) {
            _pulseController.repeat(reverse: true);
          }
        });
      } else {
        t.cancel();
        _pulseController.stop();

        if (!isAnswered) {
          userAnswer = '';
          checkAnswer();
        }
      }
    });
  }

  void checkAnswer() {
    final correct = questions[currentQuestionIndex]['answer']!.toLowerCase();
    final answer = userAnswer.trim().toLowerCase();

    setState(() {
      isAnswered = true;

      if (answer == correct) {
        correctAnswers++;
        int perQScore = (maxScore ~/ questions.length);
        totalScore += perQScore;
      } else {
        wrongAnswers++;
      }
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          isAnswered = false;
          userAnswer = "";
          _controller.clear();
        });
      } else {
        timer?.cancel();
        _pulseController.stop();
        setState(() => isFinished = true);
        _saveQuizResults();
        widget.onCompleted?.call();
      }
    });
  }

  Future<void> _saveQuizResults() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    await prefs.setInt('fill_blanks_score', totalScore.clamp(0, maxScore));
    await prefs.setInt('fill_blanks_correct', correctAnswers);
    await prefs.setInt('fill_blanks_wrong', wrongAnswers);
    await prefs.setString('fill_blanks_timestamp', now.toIso8601String());
  }

  void resetQuiz() {
    timer?.cancel();
    _pulseController.stop();

    setState(() {
      questions.shuffle(); // Re-shuffle for retry
      currentQuestionIndex = 0;
      correctAnswers = 0;
      wrongAnswers = 0;
      totalScore = 0;
      remainingTime = totalTime;
      isAnswered = false;
      isFinished = false;
      userAnswer = "";
      _controller.clear();
    });

    startTimer();
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isFinished) return Scaffold(body: _buildScorePage());

    final current = questions[currentQuestionIndex];
    Color timerColor = remainingTime <= 10 ? Colors.red : Colors.green;

    return Scaffold(
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
              ScaleTransition(
                scale: _pulseAnimation,
                child: Text(
                  '⏱ Time Left: $remainingTime seconds',
                  style: TextStyle(fontSize: 16, color: timerColor),
                ),
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
                    userAnswer.trim().isNotEmpty && !isAnswered
                        ? checkAnswer
                        : null,
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
