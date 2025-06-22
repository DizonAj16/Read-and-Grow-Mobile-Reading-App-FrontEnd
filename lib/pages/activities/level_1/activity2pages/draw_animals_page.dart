import 'package:flutter/material.dart';

class DrawAnimalsPage extends StatefulWidget {
  const DrawAnimalsPage({super.key});

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

  void _handleDrop(String path) {
    if (droppedImages.contains(path) || droppedImages.length >= 2) return;

    setState(() {
      droppedImages.add(path);
    });

    if (droppedImages.length == 2) {
      final isCorrect =
          correctSet.containsAll(droppedImages.toSet()) &&
          droppedImages.toSet().length == 2;

      if (isCorrect) {
        setState(() {
          boxBorderColor = Colors.green;
        });
        showAnimatedOverlay(true, "Correct!");
      } else {
        setState(() {
          boxBorderColor = Colors.red;
        });
        showAnimatedOverlay(false, "Try again!");
        Future.delayed(const Duration(milliseconds: 600), () {
          setState(() {
            droppedImages.clear();
            boxBorderColor = Colors.black;
          });
        });
      }
    }
  }

  void showAnimatedOverlay(bool isCorrect, String message) {
    final overlay = Overlay.of(context);
    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    final animation = Tween<Offset>(
      begin:
          isCorrect
              ? const Offset(0, -1)
              : const Offset(-0.05, 0), // slight shake for sad
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
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        isCorrect
                            ? "assets/activity_images/happy.png"
                            : "assets/activity_images/sad.png",
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
