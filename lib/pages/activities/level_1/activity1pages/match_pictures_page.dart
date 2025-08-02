import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MatchPicturesPage extends StatefulWidget {
  final VoidCallback? onCompleted;
  const MatchPicturesPage({super.key, this.onCompleted});

  @override
  State<MatchPicturesPage> createState() => _MatchPicturesPageState();
}

class _MatchPicturesPageState extends State<MatchPicturesPage>
    with SingleTickerProviderStateMixin {
  final List<Map<String, String>> originalItems = [
    {"image": "assets/activity_images/tag.jpg", "word": "tag"},
    {"image": "assets/activity_images/bag.jpg", "word": "bag"},
    {"image": "assets/activity_images/wag.jpg", "word": "wag"},
    {"image": "assets/activity_images/rag.jpg", "word": "rag"},
    {"image": "assets/activity_images/nag.png", "word": "nag"},
  ];

  List<Map<String, String>> shuffledItems = [];
  List<String> remainingWords = [];
  int currentIndex = 0;
  int correctAnswers = 0;
  int wrongAnswers = 0;
  int remainingTime = 60;
  Timer? timer;

  bool _completedQuiz = false;
  bool _showScorePage = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseController.forward();
      }
    });

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(_pulseController);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool loaded = await _loadQuizState();
      if (!loaded) _resetGame();
      startTimer();
    });
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
          if (remainingTime == 10) {
            _pulseController.forward();
          }
        });
        _saveQuizState();
      } else {
        t.cancel();
        _pulseController.stop();
        _handleTimeout();
      }
    });
  }

  void stopTimer() {
    timer?.cancel();
    _pulseController.stop();
  }

  void _handleTimeout() {
    stopTimer();
    setState(() {
      if (correctAnswers == 0 && wrongAnswers == 0) {
        correctAnswers = 0;
        wrongAnswers = 0;
      }
      remainingTime = 0;
    });
    _clearSavedQuizState();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildFeedbackDialog(false, timeout: true),
    ).then((_) => _showFinalScorePage());
  }

  void _checkAnswer(String selectedWord) {
    final correctWord = shuffledItems[currentIndex]["word"];
    final isCorrect = selectedWord == correctWord;

    if (isCorrect) {
      correctAnswers++;
      setState(() => remainingWords.remove(selectedWord));
    } else {
      wrongAnswers++;
    }

    _saveQuizState();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildFeedbackDialog(isCorrect),
    ).then((_) => _nextStep());
  }

  void _nextStep() {
    if (currentIndex < shuffledItems.length - 1) {
      setState(() {
        currentIndex++;
        remainingWords.shuffle();
      });
      _saveQuizState();
    } else {
      _showFinalScorePage();
    }
  }

  Widget _buildFeedbackDialog(bool isCorrect, {bool timeout = false}) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 150,
            width: 150,
            child: Lottie.asset(
              isCorrect
                  ? 'assets/animation/correct.json'
                  : 'assets/animation/wrong.json',
              repeat: false,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            timeout ? "Time's up!" : (isCorrect ? "Correct!" : "Wrong!"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          const Text('Press OK to continue.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    );
  }

  void _showFinalScorePage() {
    if (_completedQuiz) return;
    stopTimer();
    _clearSavedQuizState();
    setState(() {
      _completedQuiz = true;
      _showScorePage = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      widget.onCompleted?.call();
    });
  }

  void _resetGame() {
    stopTimer();
    _pulseController.reset();
    setState(() {
      shuffledItems = List<Map<String, String>>.from(originalItems)..shuffle();
      remainingWords = shuffledItems.map((e) => e['word']!).toList()..shuffle();
      currentIndex = 0;
      correctAnswers = 0;
      wrongAnswers = 0;
      remainingTime = 60;
      _completedQuiz = false;
      _showScorePage = false;
    });
    _clearSavedQuizState();
    _saveQuizState();
    startTimer();
  }

  Future<void> _saveQuizState() async {
    if (_completedQuiz) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('match_quiz_shuffled', jsonEncode(shuffledItems));
    await prefs.setStringList('match_quiz_remaining', remainingWords);
    await prefs.setInt('match_quiz_index', currentIndex);
    await prefs.setInt('match_quiz_correct', correctAnswers);
    await prefs.setInt('match_quiz_wrong', wrongAnswers);
    await prefs.setInt('match_quiz_timer', remainingTime);
    await prefs.setBool('match_quiz_completed', false);
  }

  Future<void> _clearSavedQuizState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('match_quiz_shuffled');
    await prefs.remove('match_quiz_remaining');
    await prefs.remove('match_quiz_index');
    await prefs.remove('match_quiz_correct');
    await prefs.remove('match_quiz_wrong');
    await prefs.remove('match_quiz_timer');
    await prefs.remove('match_quiz_completed');
  }

  Future<bool> _loadQuizState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('match_quiz_shuffled')) return false;
    if (prefs.getBool('match_quiz_completed') == true) return false;

    try {
      final shuffled = jsonDecode(
        prefs.getString('match_quiz_shuffled') ?? '[]',
      );
      final index = prefs.getInt('match_quiz_index') ?? 0;

      if (index >= shuffled.length) return false;

      setState(() {
        shuffledItems = List<Map<String, String>>.from(
          (shuffled as List).map((e) => Map<String, String>.from(e)),
        );
        remainingWords =
            (prefs.getStringList('match_quiz_remaining') ?? [])..shuffle();
        currentIndex = index;
        correctAnswers = prefs.getInt('match_quiz_correct') ?? 0;
        wrongAnswers = prefs.getInt('match_quiz_wrong') ?? 0;
        remainingTime = prefs.getInt('match_quiz_timer') ?? 60;
        _completedQuiz = false;
        _showScorePage = false;
      });
      return true;
    } catch (e) {
      debugPrint("Failed to load quiz state: $e");
      return false;
    }
  }

  @override
  void dispose() {
    stopTimer();
    if (!_completedQuiz) _saveQuizState();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showScorePage) {
      int score = ((correctAnswers / shuffledItems.length) * 100).round().clamp(
        0,
        100,
      );

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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.shade100,
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildScoreRow("Final Score", "$score / 100"),
                          const SizedBox(height: 12),
                          _buildScoreRow("Correct Answers", "$correctAnswers"),
                          const SizedBox(height: 12),
                          _buildScoreRow("Wrong Answers", "$wrongAnswers"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _resetGame,
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

    if (shuffledItems.isEmpty || currentIndex >= shuffledItems.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentItem = shuffledItems[currentIndex];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) {
                    return Transform.scale(
                      scale: remainingTime <= 10 ? _pulseAnimation.value : 1.0,
                      child: Text(
                        '⏰ Timer Remaining: $remainingTime s',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color:
                              remainingTime <= 10 ? Colors.red : Colors.green,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Tap the correct word for the picture.",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    currentItem["image"] ?? '',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children:
                    remainingWords
                        .map(
                          (word) => ElevatedButton(
                            onPressed: () => _checkAnswer(word),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                            child: Text(
                              word,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        )
                        .toList(),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildScoreRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 18, color: Colors.black87)),
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
