import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TheOwlAndTheRoosterMultipleChoicePage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const TheOwlAndTheRoosterMultipleChoicePage({super.key, this.onCompleted});

  @override
  State<TheOwlAndTheRoosterMultipleChoicePage> createState() =>
      _TheOwlAndTheRoosterMultipleChoicePageState();
}

class _TheOwlAndTheRoosterMultipleChoicePageState
    extends State<TheOwlAndTheRoosterMultipleChoicePage> {
  final List<Map<String, dynamic>> questions = [
    {
      'question': '1. At the beginning of the story, where was Mia?',
      'options': [
        'She was in her bedroom.',
        'She was in the bathroom.',
        'She was at the kitchen table.',
        'She was on a bench outside.',
      ],
      'answer': 'She was in her bedroom.',
    },
    {
      'question': '2. What time of the day was it?',
      'options': [
        'middle of the day',
        'late in the evening',
        'early in the morning',
        'late in the afternoon',
      ],
      'answer': 'early in the morning',
    },
    {
      'question': '3. What do you think will happen next?',
      'options': [
        'She will have lunch.',
        'She will have dinner.',
        'She will have a snack.',
        'She will have breakfast.',
      ],
      'answer': 'She will have breakfast.',
    },
    {
      'question': '4. What will she say when she gets up?',
      'options': [
        'Good evening.',
        'Good afternoon!',
        'Good morning!',
        'Thank you very much!',
      ],
      'answer': 'Good morning!',
    },
    {
      'question': '5. What other title can be given for this story?',
      'options': [
        'The End of the Day',
        'The Start of the Day',
        'Just Before Sleeping',
        'The Middle of the Day',
      ],
      'answer': 'The Start of the Day',
    },
  ];

  int currentIndex = 0;
  int correctCount = 0;
  int wrongCount = 0;
  bool finished = false;

  Timer? timer;
  int maxTimePerQuestion = 20;
  int remainingTime = 20;
  double totalScore = 0;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    remainingTime = maxTimePerQuestion;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingTime > 0) {
        setState(() => remainingTime--);
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/animation/wrong.json',
                  height: 120,
                  repeat: false,
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
        setState(() => currentIndex++);
        startTimer();
      } else {
        setState(() => finished = true);
        widget.onCompleted?.call();
      }
    });
  }

  void selectOption(String option) {
    stopTimer();
    final isCorrect = option == questions[currentIndex]['answer'];

    if (isCorrect) {
      correctCount++;
      totalScore += remainingTime;
    } else {
      wrongCount++;
    }

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
      Navigator.of(context).pop();
      if (currentIndex < questions.length - 1) {
        setState(() => currentIndex++);
        startTimer();
      } else {
        setState(() => finished = true);
        widget.onCompleted?.call();
      }
    });
  }

  void resetQuiz() {
    setState(() {
      currentIndex = 0;
      correctCount = 0;
      wrongCount = 0;
      finished = false;
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
          title: const Text('The Owl and The Rooster - Quiz'),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                child: const Text('Try Again', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      );
    }

    final question = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Owl and The Rooster - Multiple Choice'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (currentIndex + 1) / questions.length,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
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
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              question['question'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: question['options'].length,
              itemBuilder: (context, index) {
                final option = question['options'][index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ElevatedButton(
                    onPressed: () => selectOption(option),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade100,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
              padding: const EdgeInsets.only(right: 12, bottom: 8),
              child: Text(
                '© K5 Learning 2019',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
