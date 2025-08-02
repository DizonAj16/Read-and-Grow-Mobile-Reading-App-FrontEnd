import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MatchWordsToPicturesPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const MatchWordsToPicturesPage({super.key, this.onCompleted});

  @override
  State<MatchWordsToPicturesPage> createState() =>
      _MatchWordsToPicturesPageState();
}

class _MatchWordsToPicturesPageState extends State<MatchWordsToPicturesPage>
    with SingleTickerProviderStateMixin {
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

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startTimer();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft <= 0) {
        timer.cancel();
        _showScorePage();
      } else {
        setState(() => _timeLeft--);
        _saveGameState();
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Center(
                    child: Lottie.asset(
                      isCorrect
                          ? 'assets/animation/correct.json'
                          : 'assets/animation/wrong.json',
                      width: 150,
                      height: 150,
                      repeat: false,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      isCorrect ? "✅ Correct!" : "❌ Try again!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Okay",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop();
    });
  }

  void _showScorePage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('match_words_state');
    setState(() => _showingScore = true);
  }

  Future<void> _saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'matchedWords': matchedWords,
      'borderColors': borderColors.map(
        (key, value) => MapEntry(key, value.value.toString()),
      ),
      'wrongWords': wrongWords.toList(),
      'timeLeft': _timeLeft,
      'shuffledWords': shuffledWords,
    };
    await prefs.setString('match_words_state', jsonEncode(data));
  }

  void _initializeGame() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('match_words_state');

    if (savedData != null) {
      final Map<String, dynamic> data = jsonDecode(savedData);
      setState(() {
        matchedWords = Map<String, String?>.from(data['matchedWords']);
        borderColors = Map<String, String>.from(
          data['borderColors'],
        ).map((key, value) => MapEntry(key, Color(int.parse(value))));
        wrongWords = Set<String>.from(data['wrongWords']);
        _timeLeft = data['timeLeft'];
        shuffledWords = List<String>.from(data['shuffledWords']);
        _completed = false;
        _showingScore = false;
      });
    } else {
      matchedWords = {for (var item in allItems) item["word"]!: null};
      borderColors = {for (var item in allItems) item["word"]!: Colors.grey};
      wrongWords.clear();
      _completed = false;
      _showingScore = false;
      _timeLeft = 60;
      shuffledWords = allItems.map((e) => e["word"]!).toList();
      shuffledWords.shuffle();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _showingScore ? _buildScorePage() : _buildGamePage();
  }

  Widget _buildGamePage() {
    final timeColor = _timeLeft <= 10 ? Colors.red : Colors.green;

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
            _timeLeft <= 10
                ? ScaleTransition(
                  scale: _pulseAnimation,
                  child: Text(
                    "⏱ Time left: $_timeLeft seconds",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: timeColor,
                    ),
                  ),
                )
                : Text(
                  "⏱ Time left: $_timeLeft seconds",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: timeColor,
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
                  final draggableWord = shuffledWords[index];
                  final showWord =
                      matchedWords[draggableWord] == null
                          ? _buildDraggableWord(draggableWord)
                          : const SizedBox(height: 100);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: showWord),
                        const SizedBox(width: 16),
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

                              _saveGameState();
                              _showFeedbackDialog(isCorrect);

                              if (!isCorrect) {
                                Future.delayed(const Duration(seconds: 1), () {
                                  setState(() {
                                    matchedWords[imageWord] = null;
                                    borderColors[imageWord] = Colors.grey;
                                  });
                                  _saveGameState();
                                });
                              }

                              Future.delayed(
                                const Duration(milliseconds: 1200),
                                _checkIfCompleted,
                              );
                            },
                            builder: (context, _, __) {
                              return Container(
                                width: 100,
                                height: 100,
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
                                        fit: BoxFit.cover,
                                        width: 100,
                                        height: 100,
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
    int correctAnswers =
        matchedWords.entries.where((e) => e.key == e.value).length;
    int finalScore =
        (_timeLeft == 0 && correctAnswers == 0)
            ? 0
            : (_maxScore - wrongWords.length * 10).clamp(0, 100).round();

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
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('match_words_state');
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
