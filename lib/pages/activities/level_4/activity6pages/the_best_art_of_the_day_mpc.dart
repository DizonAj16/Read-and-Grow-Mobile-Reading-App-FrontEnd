import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TheBestArtOfTheDayMultipleChoicePage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const TheBestArtOfTheDayMultipleChoicePage({super.key, this.onCompleted});

  @override
  State<TheBestArtOfTheDayMultipleChoicePage> createState() =>
      _TheBestArtOfTheDayMultipleChoicePageState();
}

class _TheBestArtOfTheDayMultipleChoicePageState
    extends State<TheBestArtOfTheDayMultipleChoicePage> {
  final List<Map<String, dynamic>> _questions = [
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

  int _currentIndex = 0;
  int _score = 0;
  int _wrong = 0;
  bool _finished = false;

  Timer? _timer;
  int _maxTime = 15;
  int _remainingTime = 15;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _remainingTime = _maxTime;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        t.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    _wrong++;
    _showFeedback(isCorrect: false, isTimeout: true);
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _selectAnswer(String selected) {
    _stopTimer();
    final isCorrect = selected == _questions[_currentIndex]['answer'];

    if (isCorrect) {
      _score++;
    } else {
      _wrong++;
    }

    _showFeedback(isCorrect: isCorrect);
  }

  void _showFeedback({required bool isCorrect, bool isTimeout = false}) {
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
                  isTimeout
                      ? "Time's Up!"
                      : isCorrect
                      ? "Correct!"
                      : "Wrong!",
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

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
        });
        _startTimer();
      } else {
        setState(() {
          _finished = true;
        });
        widget.onCompleted?.call();
      }
    });
  }

  void _resetQuiz() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _wrong = 0;
      _finished = false;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      final int finalScore = ((_score / _questions.length) * 100).round();
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('The Best Art of the Day - Quiz'),
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
                'Correct Answers: $_score',
                style: const TextStyle(fontSize: 20, color: Colors.green),
              ),
              const SizedBox(height: 8),
              Text(
                'Wrong Answers: $_wrong',
                style: const TextStyle(fontSize: 20, color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text(
                'Final Score: $finalScore%',
                style: const TextStyle(fontSize: 20, color: Colors.blue),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _resetQuiz,
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

    final current = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('The Best Art of the Day - Multiple Choice'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
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
                  'Question ${_currentIndex + 1} of ${_questions.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Time: $_remainingTime s',
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
              current['question'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
              children:
                  (current['options'] as List<String>).map((option) {
                    return ElevatedButton(
                      onPressed: () => _selectAnswer(option),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }).toList(),
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
