import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DayFourMultipleChoicePage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const DayFourMultipleChoicePage({super.key, this.onCompleted});

  @override
  State<DayFourMultipleChoicePage> createState() =>
      _DayFourMultipleChoicePageState();
}

class _DayFourMultipleChoicePageState extends State<DayFourMultipleChoicePage> {
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'Which prediction is based on the title and illustration?',
      'options': [
        'Nick is moving to a new town.',
        'Nick makes a friend at camp.',
        'Nick will get a new puppy who will become his friend.',
        'Two puppies do not get along.',
      ],
      'answer': 'Nick will get a new puppy who will become his friend.',
    },
    {
      'question': 'Why does Nick choose a corgi?',
      'options': [
        'Dalmatians are too big for the house.',
        'He is afraid of dalmatians.',
        'His parents do not like dalmatians.',
        'He likes corgis better than dalmatians.',
      ],
      'answer': 'Dalmatians are too big for the house.',
    },
    {
      'question': 'What is the purpose of this text?',
      'options': [
        'to entertain',
        'to persuade someone to get a puppy',
        'to learn about training a puppy',
        'to find out how much a puppy costs',
      ],
      'answer': 'to entertain',
    },
    {
      'question': 'Why would Nick suggest going to the pet-supply store next?',
      'options': [
        'The family does not know where the pet-supply store is.',
        'The family did not find a puppy.',
        'The family will need to buy things for Tucker.',
        'The shelter manager works at the pet-supply store.',
      ],
      'answer': 'The family will need to buy things for Tucker.',
    },
    {
      'question':
          'How does the shelter manager probably feel about Nick adopting Tucker?',
      'options': ['worried', 'jealous', 'furious', 'glad'],
      'answer': 'glad',
    },
    {
      'question': 'What do you think Nick will do when he gets home?',
      'options': [
        'He will play with Tucker.',
        'He will do his homework.',
        'He will watch TV.',
        'He will go on a bike ride.',
      ],
      'answer': 'He will play with Tucker.',
    },
    {
      'question': 'What can readers learn from Nick and his family?',
      'options': [
        'Pets should be as large as possible.',
        'Puppies only need food and water.',
        'There are many things to consider when choosing a puppy.',
        'Parents should pick the family pet.',
      ],
      'answer': 'There are many things to consider when choosing a puppy.',
    },
    {
      'question': 'Which text would have a similar theme?',
      'options': [
        'a nonfiction review of a video game',
        'a poem about cats',
        'a fictional story about a child choosing a new bike at a toy store',
        'an advertisement for pet food',
      ],
      'answer':
          'a fictional story about a child choosing a new bike at a toy store',
    },
  ];

  int currentIndex = 0;
  int correctCount = 0;
  int wrongCount = 0;
  bool finished = false;

  Timer? timer;
  int totalTime = 75;
  int remainingTime = 75;
  int totalScore = 0;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingTime > 0) {
        setState(() => remainingTime--);
      } else {
        t.cancel();
        finishQuiz();
      }
    });
  }

  void stopTimer() {
    timer?.cancel();
  }

  void selectOption(String option) {
    final correctAnswer = questions[currentIndex]['answer'];
    final isCorrect = option == correctAnswer;

    if (isCorrect) {
      correctCount++;
      totalScore += 20;
    } else {
      wrongCount++;
      totalScore -= 20;
    }

    showFeedbackDialog(
      isCorrect: isCorrect,
      message: isCorrect ? 'Correct!' : 'Wrong!',
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      goToNextQuestion();
    });
  }

  void showFeedbackDialog({required bool isCorrect, required String message}) {
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
                  message,
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
  }

  void goToNextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      finishQuiz();
    }
  }

  void finishQuiz() {
    stopTimer();
    setState(() => finished = true);
    widget.onCompleted?.call();
  }

  void resetQuiz() {
    setState(() {
      currentIndex = 0;
      correctCount = 0;
      wrongCount = 0;
      finished = false;
      totalScore = 0;
      remainingTime = totalTime;
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
        appBar: AppBar(title: const Text('Day 4 - Quiz Result')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Quiz Finished!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  'Correct: $correctCount',
                  style: const TextStyle(fontSize: 22, color: Colors.green),
                ),
                Text(
                  'Wrong: $wrongCount',
                  style: const TextStyle(fontSize: 22, color: Colors.red),
                ),
                Text(
                  'Score: $totalScore',
                  style: const TextStyle(fontSize: 22, color: Colors.blue),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: resetQuiz,
                  child: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Day 4 - Multiple Choice')),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Progress bar based on answered questions
            LinearProgressIndicator(
              value: (currentIndex + 1) / questions.length,
              backgroundColor: Colors.grey.shade300,
              color: Colors.deepPurple,
              minHeight: 8,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Q ${currentIndex + 1}/${questions.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Time Left: $remainingTime s',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      question['question'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...question['options'].map<Widget>((option) {
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
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "© K5 Learning 2019",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
