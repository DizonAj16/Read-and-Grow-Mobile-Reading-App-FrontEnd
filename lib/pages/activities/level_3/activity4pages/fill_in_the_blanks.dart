import 'dart:async';

import 'package:flutter/material.dart';

class FillInTheBlanksPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const FillInTheBlanksPage({super.key, this.onCompleted});

  @override
  State<FillInTheBlanksPage> createState() => _FillInTheBlanksPageState();
}

class _FillInTheBlanksPageState extends State<FillInTheBlanksPage> {
  final List<Map<String, String>> questions = [
    {"sentence": "The frog sat on a ___ leaf.", "answer": "green"},
    {"sentence": "It saw a ___ in the pond.", "answer": "fish"},
    {"sentence": "The frog jumped ___ the log.", "answer": "over"},
  ];

  int currentIndex = 0;
  int correctAnswers = 0;
  int wrongAnswers = 0;
  int score = 100;
  int remainingTime = 60;
  bool showScorePage = false;
  bool isInputFilled = false;

  final TextEditingController _controller = TextEditingController();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onInputChanged);
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {
      isInputFilled = _controller.text.trim().isNotEmpty;
    });
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        finishQuiz();
      }
    });
  }

  void checkAnswer() {
    final userAnswer = _controller.text.trim().toLowerCase();
    final correctAnswer = questions[currentIndex]["answer"]!.toLowerCase();

    if (userAnswer == correctAnswer) {
      correctAnswers++;
    } else {
      wrongAnswers++;
    }

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        _controller.clear();
        isInputFilled = false;
      });
    } else {
      finishQuiz();
    }
  }

  void finishQuiz() {
    timer?.cancel();

    int baseScore = 100;
    int penalty = (wrongAnswers * 10) + remainingTime;
    int finalScore = baseScore - penalty;
    if (finalScore < 0) finalScore = 0;

    setState(() {
      score = finalScore;
      showScorePage = true;
    });

    widget.onCompleted?.call();
  }

  void restartQuiz() {
    setState(() {
      currentIndex = 0;
      correctAnswers = 0;
      wrongAnswers = 0;
      score = 100;
      remainingTime = 60;
      showScorePage = false;
      _controller.clear();
      isInputFilled = false;
    });
    startTimer();
  }

  Widget _buildQuestion() {
    final sentence = questions[currentIndex]["sentence"]!;
    final displaySentence = sentence.replaceAll("___", "______");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Text(
            "Time Left: $remainingTime seconds",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            "Fill in the Blank",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            "Type the missing word in the sentence below.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          "Question ${currentIndex + 1} of ${questions.length}",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Text(
          displaySentence,
          style: const TextStyle(fontSize: 22),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            hintText: "Enter your answer",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: isInputFilled ? checkAnswer : null,
          child: const Text("Submit"),
        ),
      ],
    );
  }

  Widget _buildScorePage() {
    final lowScore = correctAnswers <= 1;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              lowScore ? Icons.mood : Icons.emoji_events,
              color: lowScore ? Colors.blueGrey : Colors.amber,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              lowScore ? "Keep going!" : "Great job!",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text("Score: $score", style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text("Correct Answers: $correctAnswers"),
            Text("Wrong Answers: $wrongAnswers"),
            Text("Time Penalty: $remainingTime"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: restartQuiz,
              child: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child:
            showScorePage
                ? _buildScorePage()
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildQuestion(),
                ),
      ),
    );
  }
}
