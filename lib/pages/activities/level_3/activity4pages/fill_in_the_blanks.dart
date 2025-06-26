import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FillInTheBlanksPage extends StatefulWidget {
  const FillInTheBlanksPage({super.key});

  @override
  State<FillInTheBlanksPage> createState() => _FillInTheBlanksPageState();
}

class _FillInTheBlanksPageState extends State<FillInTheBlanksPage> {
  final List<Map<String, dynamic>> questions = [
    {"template": "The frog is the color ____.", "answer": "green"},
    {"template": "It moves its ____ and ____.", "answer": "legs arms"},
    {"template": "The ____ sits on a lily pad.", "answer": "frog"},
  ];

  int currentIndex = 0;
  int correctAnswers = 0;
  int wrongAnswers = 0;

  final TextEditingController _controller = TextEditingController();
  bool? isCorrect;
  bool isFinished = false;

  void checkAnswer() {
    String userAnswer = _controller.text.trim().toLowerCase();
    String correctAnswer = questions[currentIndex]['answer'];

    setState(() {
      isCorrect = userAnswer == correctAnswer;
      if (isCorrect!) {
        correctAnswers++;
      } else {
        wrongAnswers++;
      }
    });

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
                  height: 150,
                  width: 150,
                  child: Lottie.asset(
                    isCorrect!
                        ? 'assets/animation/correct.json'
                        : 'assets/animation/wrong.json',
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isCorrect! ? 'Correct!' : 'Wrong!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCorrect! ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Press OK to continue.'),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (currentIndex < questions.length - 1) {
                    setState(() {
                      currentIndex++;
                      _controller.clear();
                      isCorrect = null;
                    });
                  } else {
                    setState(() {
                      isFinished = true;
                    });
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void resetQuiz() {
    setState(() {
      currentIndex = 0;
      correctAnswers = 0;
      wrongAnswers = 0;
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
              Text(
                'Correct Answers: $correctAnswers',
                style: const TextStyle(fontSize: 22),
              ),
              Text(
                'Wrong Answers: $wrongAnswers',
                style: const TextStyle(fontSize: 22),
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
    final displayedText = currentQuestion['template'].replaceAll(
      '____',
      '______',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Fill in the Blanks')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                displayedText,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                        color: Colors.deepPurple,
                        width: 3,
                      ),
                    ),
                    hintText: 'Answer',
                    hintStyle: const TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: Colors.lightBlue.shade50,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 120,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    if (_controller.text.trim().isEmpty) return;
                    checkAnswer();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
