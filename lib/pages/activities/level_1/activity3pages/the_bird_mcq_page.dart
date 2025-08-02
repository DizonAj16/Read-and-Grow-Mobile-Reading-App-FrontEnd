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

class _TheBirdMultipleChoicePageState extends State<TheBirdMultipleChoicePage>
    with TickerProviderStateMixin {
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
  int remainingTime = 75;
  int maxTime = 75;

  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;

  List<String> currentShuffledOptions = [];
  String currentCorrectAnswer = '';

  @override
  void initState() {
    super.initState();

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _colorAnimation = ColorTween(
      begin: Colors.red,
      end: Colors.red.shade100,
    ).animate(_colorController);

    loadQuestion(currentIndex);
    startTimer();
  }

  void loadQuestion(int index) {
    final question = questions[index];
    currentCorrectAnswer = question['answer'];
    currentShuffledOptions = List<String>.from(question['options'])..shuffle();
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
          if (remainingTime <= 10 && !_colorController.isAnimating) {
            _colorController.repeat(reverse: true);
          }
        });
      } else {
        t.cancel();
        handleTimeout();
      }
    });
  }

  void stopTimer() {
    timer?.cancel();
    _colorController.stop();
  }

  void handleTimeout() {
    setState(() {
      finished = true;
    });
    _saveQuizResults();
    widget.onCompleted?.call();
  }

  void selectOption(String option) {
    final isCorrect = option == currentCorrectAnswer;

    if (isCorrect) {
      correctCount++;
      totalScore += 10;
    } else {
      wrongCount++;
    }

    showFeedbackDialog(isCorrect, isCorrect ? "Correct!" : "Wrong!");
  }

  void moveToNext() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        loadQuestion(currentIndex);
      });
    } else {
      setState(() {
        finished = true;
      });
      stopTimer();
      _saveQuizResults();
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
      builder: (_) => AlertDialog(
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                moveToNext();
              },
              child: const Text("Okay"),
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
      remainingTime = maxTime;
      finished = false;
    });
    loadQuestion(currentIndex);
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    _colorController.dispose();
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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'The Bird - Multiple Choice',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
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
                remainingTime <= 10
                    ? AnimatedBuilder(
                  animation: _colorController,
                  builder: (context, child) {
                    return Text(
                      'Time: $remainingTime s',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _colorAnimation.value,
                      ),
                    );
                  },
                )
                    : Text(
                  'Time: $remainingTime s',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              questions[currentIndex]["question"],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 3,
                children: List.generate(currentShuffledOptions.length, (index) {
                  final option = currentShuffledOptions[index];
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
