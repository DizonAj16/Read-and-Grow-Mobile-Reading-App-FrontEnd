import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class MatchWordsToPicturesPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const MatchWordsToPicturesPage({super.key, this.onCompleted});

  @override
  State<MatchWordsToPicturesPage> createState() =>
      _MatchWordsToPicturesPageState();
}

class _MatchWordsToPicturesPageState extends State<MatchWordsToPicturesPage> {
  final List<Map<String, String>> allItems = [
    {"word": "rag", "image": "assets/activity_images/rag.jpg"},
    {"word": "wag", "image": "assets/activity_images/wag.jpg"},
    {"word": "tag", "image": "assets/activity_images/tag.jpg"},
    {"word": "bag", "image": "assets/activity_images/bag.jpg"},
  ];

  late List<String> shuffledWords;
  late Map<String, String?> matchedWords;
  late Map<String, Color> borderColors;

  Set<String> wrongWords = {};
  bool _completed = false;
  bool _showingScore = false;
  Timer? _timer;
  int _timeLeft = 60;
  final int _maxScore = 100;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startTimer();
  }

  void _initializeGame() {
    matchedWords = {for (var item in allItems) item["word"]!: null};
    borderColors = {for (var item in allItems) item["word"]!: Colors.grey};
    wrongWords.clear();
    _completed = false;
    _showingScore = false;
    _timeLeft = 60;

    // Shuffle only the left-side word list
    shuffledWords = allItems.map((e) => e["word"]!).toList();
    shuffledWords.shuffle();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft <= 0) {
        timer.cancel();
        _showScorePage();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _checkIfCompleted() {
    final allCorrect = matchedWords.entries.every(
      (entry) => entry.key == entry.value,
    );

    if (allCorrect && !_completed) {
      _completed = true;
      _timer?.cancel();
      widget.onCompleted?.call();
      _showScorePage();
    }
  }

  void _showFeedbackDialog(bool isCorrect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  isCorrect
                      ? 'assets/animation/correct.json'
                      : 'assets/animation/wrong.json',
                  width: 200,
                  height: 200,
                  repeat: false,
                ),
                const SizedBox(height: 8),
                Text(
                  isCorrect ? "✅ Correct!" : "❌ Try again!",
                  style: TextStyle(
                    fontSize: 20,
                    color: isCorrect ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop();
    });
  }

  void _showScorePage() {
    setState(() => _showingScore = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _showingScore ? _buildScorePage() : _buildGamePage();
  }

  Widget _buildGamePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Match Words to Pictures"),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            Text(
              "-ag Word Family: Match the word with the correct picture.",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "⏱ Time left: $_timeLeft seconds",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: allItems.length,
                itemBuilder: (context, index) {
                  final imageWord = allItems[index]["word"]!;
                  final imagePath = allItems[index]["image"]!;
                  final currentMatch = matchedWords[imageWord];

                  // Get shuffled word for left side
                  final draggableWord = shuffledWords[index];
                  final showWord =
                      matchedWords[draggableWord] == null
                          ? _buildDraggableWord(draggableWord)
                          : const SizedBox(height: 100);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12,
                    ),
                    child: Row(
                      children: [
                        // Left side: draggable word
                        Expanded(flex: 1, child: showWord),
                        const SizedBox(width: 16),
                        // Right side: drag target (image)
                        Expanded(
                          flex: 1,
                          child: DragTarget<String>(
                            onAccept: (receivedWord) {
                              final isCorrect = receivedWord == imageWord;

                              setState(() {
                                matchedWords[imageWord] = receivedWord;
                                borderColors[imageWord] =
                                    isCorrect ? Colors.green : Colors.red;
                                if (!isCorrect) wrongWords.add(imageWord);
                              });

                              _showFeedbackDialog(isCorrect);

                              if (!isCorrect) {
                                Future.delayed(const Duration(seconds: 1), () {
                                  setState(() {
                                    matchedWords[imageWord] = null;
                                    borderColors[imageWord] = Colors.grey;
                                  });
                                });
                              }

                              Future.delayed(
                                const Duration(milliseconds: 1200),
                                _checkIfCompleted,
                              );
                            },
                            builder: (context, _, __) {
                              return Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: borderColors[imageWord]!,
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset(
                                        imagePath,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                      if (currentMatch != null)
                                        Positioned(
                                          bottom: 8,
                                          child: Stack(
                                            children: [
                                              Text(
                                                currentMatch,
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w900,
                                                  foreground:
                                                      Paint()
                                                        ..style =
                                                            PaintingStyle.stroke
                                                        ..strokeWidth = 3
                                                        ..color = Colors.white,
                                                ),
                                              ),
                                              Text(
                                                currentMatch,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(right: 12.0, bottom: 6),
                child: Text(
                  "© Live Work Sheets",
                  style: TextStyle(
                    color: Colors.grey,
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

  Widget _buildDraggableWord(String word) {
    return Draggable<String>(
      data: word,
      feedback: Material(
        color: Colors.transparent,
        child: _buildWordCard(word),
      ),
      childWhenDragging: const SizedBox.shrink(),
      child: _buildWordCard(word),
    );
  }

  Widget _buildWordCard(String word) {
    return Card(
      color: Colors.blue,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            word,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, color: Colors.black87),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildScorePage() {
    int finalScore =
        ((_timeLeft / 60) * _maxScore - wrongWords.length * 10)
            .clamp(0, 100)
            .round();

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "🎉 Great Job!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "You completed the activity!",
                    style: TextStyle(fontSize: 20, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildScoreRow("Final Score", "$finalScore / 100"),
                        const SizedBox(height: 12),
                        _buildScoreRow("Wrong Answers", "${wrongWords.length}"),
                        const SizedBox(height: 12),
                        _buildScoreRow("Time Left", "$_timeLeft s"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _initializeGame();
                          _startTimer();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        "🔁 Try Again",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
