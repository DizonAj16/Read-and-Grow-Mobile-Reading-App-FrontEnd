import 'package:flutter/material.dart';

import 'activity2pages/cat_and_rat_page.dart';
import 'activity2pages/fill_in_the_blanks.dart';
import 'activity2pages/matching_exercise_page.dart';

class Activity2Page extends StatefulWidget {
  const Activity2Page({super.key});

  @override
  _Activity2PageState createState() => _Activity2PageState();
}

class _Activity2PageState extends State<Activity2Page> {
  int _currentPage = 0;

  final List<Widget> _pages = [
    const CatAndRatPage(), // First page with the provided image
    const MatchingExercisePage(), // Second page with the matching exercise
    const FillInTheBlanksPage(), // Third page with fill-in-the-blank and drawing
    const DrawAnimalsPage(), // <-- New final drawing page
  ];

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Display the current activity page
              Expanded(child: _pages[_currentPage]),

              const SizedBox(height: 12),

              // Navigation section
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                      icon: const Icon(Icons.arrow_back_ios),
                      label: const Text("Back"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Text(
                      "Page ${_currentPage + 1} of ${_pages.length}",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                          _currentPage < _pages.length - 1
                              ? _goToNextPage
                              : null,
                      icon: const Icon(Icons.arrow_forward_ios),
                      label: const Text("Next"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawAnimalsPage extends StatefulWidget {
  const DrawAnimalsPage({super.key});

  @override
  State<DrawAnimalsPage> createState() => _DrawAnimalsPageState();
}

class _DrawAnimalsPageState extends State<DrawAnimalsPage> {
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

  void _handleDrop(String path) {
    if (droppedImages.contains(path) || droppedImages.length >= 2) return;

    setState(() {
      droppedImages.add(path);
    });

    // Only check when there are two images
    if (droppedImages.length == 2) {
      final isCorrect = correctSet.containsAll(droppedImages.toSet());

      if (isCorrect && droppedImages.toSet().length == 2) {
        setState(() {
          boxBorderColor = Colors.green;
        });
        _showMessage("Correct!");
      } else {
        setState(() {
          boxBorderColor = Colors.red;
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          setState(() {
            droppedImages.clear();
            boxBorderColor = Colors.black;
          });
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          const SizedBox(height: 20),

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
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
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
