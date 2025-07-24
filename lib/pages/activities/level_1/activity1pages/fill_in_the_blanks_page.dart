import 'dart:async';

import 'package:flutter/material.dart';

class FillInTheBlanksPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const FillInTheBlanksPage({super.key, this.onCompleted});

  @override
  State<FillInTheBlanksPage> createState() => _FillInTheBlanksPageState();
}

class _FillInTheBlanksPageState extends State<FillInTheBlanksPage> {
  final List<Map<String, String>> fillItems = [
    {"image": "assets/activity_images/bag.jpg", "answer": "b"},
    {"image": "assets/activity_images/tag.jpg", "answer": "t"},
    {"image": "assets/activity_images/wag.jpg", "answer": "w"},
    {"image": "assets/activity_images/rag.jpg", "answer": "r"},
  ];

  final List<String> options = ["r", "w", "t", "b"];
  late List<String?> droppedLetters;
  late List<Color> boxColors;
  late Set<String> usedLetters;

  bool _completed = false;
  bool showScorePage = false;

  int remainingTime = 60;
  int score = 0;
  Timer? _timer;
  bool _retrying = false;
  bool _timeoutHandled = false;

  @override
  void initState() {
    super.initState();
    _resetGame();
    _startTimer();
  }

  void _resetGame() {
    droppedLetters = List<String?>.filled(fillItems.length, null);
    boxColors = List<Color>.filled(fillItems.length, Colors.grey);
    usedLetters = {};
    _completed = false;
    showScorePage = false;
    score = 0;
    remainingTime = 60;
    _timeoutHandled = false;
    _timer?.cancel();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel(); // stop timer if widget is no longer in the tree
        return;
      }

      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else if (!_timeoutHandled) {
          _timeoutHandled = true;
          _timer?.cancel();
          _showTimeoutDialog();
        }
      });
    });
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text("⏰ Time's up!"),
            content: const Text(
              "Your time has run out. Let's see how you did.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _finishAndShowScore();
                },
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  void _checkIfAllCorrect() {
    bool allCorrect = true;
    for (int i = 0; i < fillItems.length; i++) {
      if (droppedLetters[i] != fillItems[i]["answer"]) {
        allCorrect = false;
        break;
      }
    }

    if (allCorrect && !_completed) {
      _completed = true;
      _timer?.cancel();
      _finishAndShowScore();
    }
  }

  void _finishAndShowScore() {
    setState(() {
      score = ((remainingTime / 60) * 100).round();
      showScorePage = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!_retrying) widget.onCompleted?.call();
    });
  }

  void _onTryAgain() {
    setState(() => _retrying = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _resetGame();
        _retrying = false;
      });
    });
  }

  @override
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (showScorePage) return _buildScoreScreen(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Fill in the blank with the correct letter.",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "⏳ Time Left: $remainingTime s",
          style: TextStyle(
            fontSize: 18,
            color: remainingTime <= 10 ? Colors.red : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: fillItems.length,
            itemBuilder: (context, index) {
              final item = fillItems[index];
              final image = item["image"]!;
              final answer = item["answer"]!;
              final letter = droppedLetters[index];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: Image.asset(image, width: 100, height: 100),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Row(
                      children: [
                        DragTarget<String>(
                          onWillAccept:
                              (data) =>
                                  !_completed && !usedLetters.contains(data),
                          onAccept: (data) {
                            setState(() {
                              if (droppedLetters[index] != null) {
                                usedLetters.remove(droppedLetters[index]);
                              }

                              droppedLetters[index] = data;
                              usedLetters.add(data);

                              if (data == answer) {
                                boxColors[index] = Colors.green;
                                _checkIfAllCorrect();
                              } else {
                                boxColors[index] = Colors.red;
                                Future.delayed(const Duration(seconds: 1), () {
                                  setState(() {
                                    droppedLetters[index] = null;
                                    boxColors[index] = Colors.grey;
                                    usedLetters.remove(data);
                                  });
                                });
                              }
                            });
                          },
                          builder: (context, _, __) {
                            return Container(
                              width: 45,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: boxColors[index],
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                letter ?? "",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "ag",
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            "Options:",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            spacing: 10,
            children:
                options.map((option) {
                  final isUsed = usedLetters.contains(option);
                  return isUsed
                      ? _buildOptionChip(context, option, disabled: true)
                      : Draggable<String>(
                        data: option,
                        feedback: Material(
                          color: Colors.transparent,
                          child: _buildOptionChip(context, option),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: _buildOptionChip(context, option),
                        ),
                        child: _buildOptionChip(context, option),
                      );
                }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.bottomRight,
          child: Text(
            "© Live Work Sheets",
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionChip(
    BuildContext context,
    String letter, {
    bool disabled = false,
  }) {
    return Chip(
      label: Text(
        letter,
        style: TextStyle(
          color: disabled ? Colors.grey : Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      backgroundColor:
          disabled
              ? Colors.grey.withOpacity(0.3)
              : Colors.deepPurple.withOpacity(0.1),
    );
  }

  Widget _buildScoreScreen(BuildContext context) {
    return Container(
      color: Colors.deepPurple.shade50,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 20,
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
                Text(
                  "You completed the activity!",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.deepPurple.shade400,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "🏆 Your Score",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "$score / 100",
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _onTryAgain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    "Try Again",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
