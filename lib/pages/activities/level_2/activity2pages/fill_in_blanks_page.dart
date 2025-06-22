import 'package:flutter/material.dart';

class FillInTheBlanksPage extends StatefulWidget {
  const FillInTheBlanksPage({super.key});

  @override
  State<FillInTheBlanksPage> createState() => _FillInTheBlanksPageState();
}

class _FillInTheBlanksPageState extends State<FillInTheBlanksPage> {
  final List<Map<String, dynamic>> questions = [
    {"template": "The bird ____ loudly.", "answer": "sings"},
    {"template": "It flies in the ___.", "answer": "sky"},
    {"template": "The bird is in a ___.", "answer": "nest"},
  ];

  int currentIndex = 0;
  final TextEditingController _controller = TextEditingController();
  bool? isCorrect;
  bool isFinished = false;

  void checkAnswer() {
    String userAnswer = _controller.text.trim().toLowerCase();
    String correctAnswer = questions[currentIndex]['answer'];

    setState(() {
      isCorrect = userAnswer == correctAnswer;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (isCorrect == true && currentIndex < questions.length - 1) {
        setState(() {
          currentIndex++;
          _controller.clear();
          isCorrect = null;
        });
      } else if (isCorrect == true && currentIndex == questions.length - 1) {
        setState(() {
          isFinished = true;
        });
      } else {
        // Incorrect answer – keep showing feedback until user fixes it
      }
    });
  }

  void resetQuiz() {
    setState(() {
      currentIndex = 0;
      isCorrect = null;
      isFinished = false;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isFinished) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fill in the Blanks')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Great job!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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

    final currentQuestion = questions[currentIndex];
    final displayedText = currentQuestion['template'];

    return Scaffold(
      appBar: AppBar(title: const Text('Fill in the Blanks')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayedText,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type your answer here',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: checkAnswer, child: const Text('Submit')),
            const SizedBox(height: 20),
            if (isCorrect != null)
              Icon(
                isCorrect! ? Icons.check_circle : Icons.cancel,
                color: isCorrect! ? Colors.green : Colors.red,
                size: 60,
              ),
          ],
        ),
      ),
    );
  }
}
