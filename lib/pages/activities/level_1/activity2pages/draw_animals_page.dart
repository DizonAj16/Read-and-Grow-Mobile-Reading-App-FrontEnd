import 'dart:async';

import 'package:flutter/material.dart';

class DrawAnimalsPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const DrawAnimalsPage({super.key, this.onCompleted});

  @override
  State<DrawAnimalsPage> createState() => _DrawAnimalsPageState();
}

class _DrawAnimalsPageState extends State<DrawAnimalsPage>
    with TickerProviderStateMixin {
  final List<String> animalImages = [
    "assets/activity_images/cat.jpg",
    "assets/activity_images/rat.jpg",
    "assets/activity_images/bat.png",
    "assets/activity_images/doge.jpg",
  ];

  final Set<String> correctSet = {
    "assets/activity_images/cat.jpg",
    "assets/activity_images/rat.jpg",
  };

  final List<String> droppedImages = [];
  Color boxBorderColor = Colors.black;
  bool completed = false;
  int correctCount = 0;
  int wrongCount = 0;
  double score = 100;
  Timer? _timer;
  int remainingTime = 60;
  bool showScoreScreen = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    startTimer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime == 0 || completed) {
        finalizeScore();
        timer.cancel();
        _pulseController.stop();
        setState(() => showScoreScreen = true);
        widget.onCompleted?.call();
      } else {
        setState(() => remainingTime--);
      }
    });
  }

  void _handleDrop(String path) {
    if (completed || droppedImages.contains(path) || droppedImages.length >= 2)
      return;

    setState(() {
      droppedImages.add(path);
    });

    if (droppedImages.length == 2) {
      final isCorrect =
          correctSet.containsAll(droppedImages.toSet()) &&
          droppedImages.toSet().length == 2;

      if (isCorrect) {
        setState(() {
          correctCount = 2;
          boxBorderColor = Colors.green;
          completed = true;
        });
        showAnimatedOverlay(true, "Correct!");
        Future.delayed(const Duration(seconds: 1), () {
          finalizeScore();
          setState(() => showScoreScreen = true);
          widget.onCompleted?.call();
        });
      } else {
        setState(() {
          wrongCount++;
          boxBorderColor = Colors.red;
        });
        showAnimatedOverlay(false, "Try again!");
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            droppedImages.clear();
            boxBorderColor = Colors.black;
          });
        });
      }
    }
  }

  void finalizeScore() {
    double finalScore = 100 - (wrongCount * 10) + (remainingTime * 0.5);
    score = finalScore.clamp(0, 100);
  }

  void resetGame() {
    setState(() {
      droppedImages.clear();
      boxBorderColor = Colors.black;
      completed = false;
      correctCount = 0;
      wrongCount = 0;
      score = 100;
      remainingTime = 60;
      showScoreScreen = false;
    });
    _pulseController.repeat(reverse: true);
    startTimer();
  }

  void showAnimatedOverlay(bool isCorrect, String message) {
    final overlay = Overlay.of(context);
    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    final animation = Tween<Offset>(
      begin: isCorrect ? const Offset(0, -1) : const Offset(-0.05, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: isCorrect ? Curves.bounceOut : Curves.elasticIn,
      ),
    );

    final entry = OverlayEntry(
      builder:
          (_) => Center(
            child: Material(
              color: Colors.transparent,
              child: SlideTransition(
                position: animation,
                child: Container(
                  width: 200,
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        isCorrect
                            ? "assets/animation/correct.json"
                            : "assets/animation/wrong.json",
                        width: 80,
                        height: 80,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 20,
                          color: isCorrect ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(entry);
    animationController.forward();
    Future.delayed(const Duration(seconds: 2), () {
      animationController.dispose();
      entry.remove();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (showScoreScreen) return _buildScorePage();

    final isWarningTime = remainingTime <= 10;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "3. Drag the two animals in the story.",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isWarningTime ? _pulseAnimation.value : 1.0,
                  child: Text(
                    "Time Left: $remainingTime s",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isWarningTime ? Colors.red : Colors.green,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            DrawBox(
              droppedImages: droppedImages,
              onAccept: _handleDrop,
              borderColor: boxBorderColor,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              children:
                  animalImages.map((path) {
                    final used = droppedImages.contains(path);
                    return Draggable<String>(
                      data: path,
                      feedback: Image.asset(path, width: 80, height: 80),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: Image.asset(path, width: 80, height: 80),
                      ),
                      child: Opacity(
                        opacity: used ? 0.4 : 1.0,
                        child: Image.asset(path, width: 80, height: 80),
                      ),
                    );
                  }).toList(),
            ),
            const Spacer(),
            const Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "© K5 Learning 2019",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScorePage() {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
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
                    offset: const Offset(0, 10),
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
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 24),
                  _buildScoreItem(
                    "Final Score",
                    "${score.toStringAsFixed(1)} / 100",
                  ),
                  _buildScoreItem("Correct Answers", "$correctCount"),
                  _buildScoreItem("Wrong Attempts", "$wrongCount"),
                  _buildScoreItem("Time Left", "$remainingTime s"),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: resetGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Try Again",
                      style: TextStyle(fontSize: 18),
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

  Widget _buildScoreItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class DrawBox extends StatelessWidget {
  final List<String> droppedImages;
  final void Function(String) onAccept;
  final Color borderColor;

  const DrawBox({
    super.key,
    required this.droppedImages,
    required this.onAccept,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAccept: (_) => true,
      onAccept: onAccept,
      builder: (context, candidate, rejected) {
        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 3),
            color: Colors.grey.shade100,
          ),
          child: Stack(
            children: [
              if (droppedImages.isEmpty)
                const Center(
                  child: Text(
                    "Drag here",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              if (droppedImages.length >= 1)
                Positioned(
                  left: 40,
                  top: 60,
                  child: Image.asset(droppedImages[0], width: 80, height: 80),
                ),
              if (droppedImages.length >= 2)
                Positioned(
                  right: 40,
                  top: 60,
                  child: Image.asset(droppedImages[1], width: 80, height: 80),
                ),
            ],
          ),
        );
      },
    );
  }
}
