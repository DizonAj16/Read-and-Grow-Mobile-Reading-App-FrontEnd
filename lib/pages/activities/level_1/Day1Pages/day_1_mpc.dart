import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Day1MultipleChoicePage extends StatefulWidget {
  const Day1MultipleChoicePage({super.key, this.onCompleted});
  final VoidCallback? onCompleted;

  @override
  State<Day1MultipleChoicePage> createState() => _Day1MultipleChoicePageState();
}

class _Day1MultipleChoicePageState extends State<Day1MultipleChoicePage> {
  int currentIndex = 0;
  int correctCount = 0;
  int wrongCount = 0;
  bool finished = false;
  double totalScore = 0;

  Timer? timer;
  int totalQuizTime = 75;
  int remainingTime = 75;

  late List<Map<String, Object>> questions;

  final List<Map<String, Object>> originalQuestions = [
    {
      'question': '1. What did Nick want ever since he was six?',
      'options': ['A kitten', 'A puppy', 'A rabbit', 'A hamster'],
      'answer': 'A puppy',
    },
    {
      'question': '2. What was one reason Nick\'s parents said no to a puppy?',
      'options': [
        'They were allergic',
        'They lived in an apartment',
        'They said Nick couldn’t take care of one',
        'They already had a dog',
      ],
      'answer': 'They said Nick couldn’t take care of one',
    },
    {
      'question':
          '3. What did Nick decide to do to prove he was ready for a puppy?',
      'options': [
        'Adopt a puppy secretly',
        'Buy pet supplies',
        'Volunteer at an animal shelter',
        'Write an essay',
      ],
      'answer': 'Volunteer at an animal shelter',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeQuiz();
    _loadProgress();
  }

  void _initializeQuiz() {
    final random = Random();
    questions = List<Map<String, Object>>.from(originalQuestions);
    questions.shuffle(random);

    for (var question in questions) {
      final options = List<String>.from(question['options'] as List);
      options.shuffle(random);
      question['options'] = options;
    }
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      currentIndex = prefs.getInt('day1_currentIndex') ?? 0;
      correctCount = prefs.getInt('day1_correctCount') ?? 0;
      wrongCount = prefs.getInt('day1_wrongCount') ?? 0;
      totalScore = prefs.getDouble('day1_totalScore') ?? 0;
      finished = prefs.getBool('day1_finished') ?? false;
    });

    if (!finished) {
      startTimer();
    } else {
      widget.onCompleted?.call();
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('day1_currentIndex', currentIndex);
    await prefs.setInt('day1_correctCount', correctCount);
    await prefs.setInt('day1_wrongCount', wrongCount);
    await prefs.setDouble('day1_totalScore', totalScore);
    await prefs.setBool('day1_finished', finished);
  }

  void startTimer() {
    remainingTime = totalQuizTime;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingTime > 0) {
        setState(() => remainingTime--);
      } else {
        t.cancel();
        handleQuizTimeout();
      }
    });
  }

  void stopTimer() {
    timer?.cancel();
  }

  void handleQuizTimeout() {
    setState(() => finished = true);
    _saveProgress();
    widget.onCompleted?.call();
  }

  void selectOption(String option) {
    if (finished) return;

    final correctAnswer = questions[currentIndex]['answer'] as String;
    final isCorrect = option == correctAnswer;

    if (isCorrect) {
      correctCount++;
      totalScore += remainingTime; // award remaining time as score
    } else {
      wrongCount++;
    }

    _saveProgress();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  isCorrect
                      ? 'assets/animation/correct.json'
                      : 'assets/animation/wrong.json',
                  height: 120,
                  repeat: false,
                ),
                const SizedBox(height: 12),
                Text(
                  isCorrect ? 'Correct!' : 'Wrong!',
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

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
      goToNextQuestion();
    });
  }

  void goToNextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
      _saveProgress();
    } else {
      setState(() => finished = true);
      _saveProgress();
      widget.onCompleted?.call();
    }
  }

  void resetQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('day1_currentIndex');
    await prefs.remove('day1_correctCount');
    await prefs.remove('day1_wrongCount');
    await prefs.remove('day1_totalScore');
    await prefs.remove('day1_finished');

    setState(() {
      currentIndex = 0;
      correctCount = 0;
      wrongCount = 0;
      totalScore = 0;
      finished = false;
      remainingTime = totalQuizTime;
    });

    _initializeQuiz();
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
          title: const Text('Quiz Result'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Quiz Finished!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                'Correct Answers: $correctCount',
                style: const TextStyle(fontSize: 20, color: Colors.green),
              ),
              Text(
                'Wrong Answers: $wrongCount',
                style: const TextStyle(fontSize: 20, color: Colors.red),
              ),
              Text(
                'Score: ${totalScore.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 20, color: Colors.blue),
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

    final question = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Quiz'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (totalQuizTime - remainingTime) / totalQuizTime,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${currentIndex + 1} of ${questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Time: $remainingTime s',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              question['question'] as String,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ...(question['options'] as List<String>).map((option) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => selectOption(option),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
