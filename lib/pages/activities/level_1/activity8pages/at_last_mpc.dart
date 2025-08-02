import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AtLastMultipleChoicePage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const AtLastMultipleChoicePage({super.key, this.onCompleted});

  @override
  State<AtLastMultipleChoicePage> createState() =>
      _AtLastMultipleChoicePageState();
}

class _AtLastMultipleChoicePageState extends State<AtLastMultipleChoicePage> {
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'Where did the bird come from? (Literal)',
      'options': [
        'an egg with lots of spots',
        'an egg with many colors',
        'an egg with only one color',
        'an egg with plenty of stripes',
      ],
      'answer': 'an egg with only one color',
    },
    {
      'question': 'Why was the bird afraid? (Inferential)',
      'options': [
        'He did not have any friends.',
        'He did not know how to fly.',
        'He did not know his mother.',
        'He did not see his brothers.',
      ],
      'answer': 'He did not know how to fly.',
    },
    {
      'question': 'Why was the bird\'s mother not in the nest? (Inferential)',
      'options': [
        'She had to look for a nest to house the little bird.',
        'She had to leave the bird so he will learn on his own.',
        'She had to find food to feed the hungry little bird.',
        'She had to look for something to help the little bird fly.',
      ],
      'answer': 'She had to find food to feed the hungry little bird.',
    },
    {
      'question': 'How did the bird learn to fly? (Inferential)',
      'options': [
        'by studying and practicing',
        'by watching other birds fly',
        'by having his mother teach him',
        'by accidentally flapping its wings',
      ],
      'answer': 'by accidentally flapping its wings',
    },
    {
      'question':
          'At the end of the passage, how did the little bird feel? (Inferential)',
      'options': ['lonely', 'afraid', 'nervous', 'excited'],
      'answer': 'excited',
    },
  ];

  int currentIndex = 0;
  int correctCount = 0;
  int wrongCount = 0;
  bool finished = false;

  Timer? timer;
  int maxTimePerQuestion = 75;
  int remainingTime = 75;

  int totalCorrectAnswers = 0;
  double totalScore = 0;

  @override
  void initState() {
    super.initState();

    // Shuffle questions and options
    questions.shuffle();
    for (var q in questions) {
      (q['options'] as List).shuffle();
    }

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
                    'assets/animation/wrong.json',
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Time\'s up!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
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
      Navigator.of(context).pop();
      if (currentIndex < questions.length - 1) {
        setState(() {
          currentIndex++;
        });
        startTimer();
      } else {
        setState(() {
          finished = true;
        });
        widget.onCompleted?.call();
      }
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
      Navigator.of(context).pop();
      if (currentIndex < questions.length - 1) {
        setState(() {
          currentIndex++;
        });
        startTimer();
      } else {
        setState(() {
          finished = true;
        });
        widget.onCompleted?.call();
      }
    });
  }

  void resetQuiz() {
    setState(() {
      questions.shuffle();
      for (var q in questions) {
        (q['options'] as List).shuffle();
      }

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
          title: const Text('At last - Quiz'),
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
                'Total Correct Answers: $totalCorrectAnswers',
                style: const TextStyle(fontSize: 20, color: Colors.green),
              ),
              const SizedBox(height: 8),
              Text(
                'Total Score: ${totalScore.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 20, color: Colors.blue),
              ),
              const SizedBox(height: 8),
              Text(
                'Wrong Answers: $wrongCount',
                style: const TextStyle(fontSize: 20, color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: resetQuiz,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.deepPurple,
                ),
                child: const Text('Try Again', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      );
    }

    final questionData = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('At last - Quiz'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (currentIndex + 1) / questions.length,
            backgroundColor: Colors.grey.shade300,
            color: Colors.deepPurple,
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${currentIndex + 1} of ${questions.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Time: $remainingTime s',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              questionData['question'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: questionData['options'].length,
              itemBuilder: (context, index) {
                final option = questionData['options'][index];
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
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
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
    );
  }
}
