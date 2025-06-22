import 'package:flutter/material.dart';

class TheBirdMultipleChoicePage extends StatefulWidget {
  const TheBirdMultipleChoicePage({super.key});

  @override
  State<TheBirdMultipleChoicePage> createState() =>
      _TheBirdMultipleChoicePageState();
}

class _TheBirdMultipleChoicePageState extends State<TheBirdMultipleChoicePage> {
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'Where is the bird?',
      'options': ['in the car', 'in the bed', 'in the sky', 'in the box'],
      'answer': 'in the sky',
    },
    {
      'question': 'What is in the tree?',
      'options': ['a cat', 'a kite', 'a rope swing', 'a nest'],
      'answer': 'a nest',
    },
    {
      'question': 'What does the bird do at the end of the story?',
      'options': [
        'sleeps in a nest',
        'eats a worm',
        'flies away',
        'sings a song',
      ],
      'answer': 'flies away',
    },
  ];

  int currentIndex = 0;
  String? selectedOption;
  bool? isCorrect;
  bool finished = false;

  void selectOption(String option) {
    final correctAnswer = questions[currentIndex]['answer'];
    setState(() {
      selectedOption = option;
      isCorrect = option == correctAnswer;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (currentIndex < questions.length - 1) {
        setState(() {
          currentIndex++;
          selectedOption = null;
          isCorrect = null;
        });
      } else {
        setState(() {
          finished = true;
        });
      }
    });
  }

  void resetQuiz() {
    setState(() {
      currentIndex = 0;
      selectedOption = null;
      isCorrect = null;
      finished = false;
    });
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
                'You finished the quiz!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

    final questionData = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('The Bird - Multiple Choice')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${currentIndex + 1}: ${questionData['question']}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ...questionData['options'].map<Widget>((option) {
              final isSelected = selectedOption == option;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ElevatedButton(
                  onPressed:
                      selectedOption == null
                          ? () => selectOption(option)
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSelected
                            ? (isCorrect == true ? Colors.green : Colors.red)
                            : null,
                  ),
                  child: Text(option),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            if (isCorrect != null) ...[
              Icon(
                isCorrect! ? Icons.check_circle : Icons.cancel,
                color: isCorrect! ? Colors.green : Colors.red,
                size: 50,
              ),
              const SizedBox(height: 8),
              Text(
                isCorrect! ? 'Correct!' : 'Try again!',
                style: TextStyle(
                  color: isCorrect! ? Colors.green : Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
