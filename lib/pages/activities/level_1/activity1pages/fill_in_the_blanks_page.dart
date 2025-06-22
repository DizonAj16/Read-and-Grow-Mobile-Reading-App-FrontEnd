import 'package:flutter/material.dart';

class FillInTheBlanksPage extends StatefulWidget {
  const FillInTheBlanksPage({super.key});

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

  @override
  void initState() {
    super.initState();
    droppedLetters = List<String?>.filled(fillItems.length, null);
    boxColors = List<Color>.filled(fillItems.length, Colors.grey);
    usedLetters = {};
  }

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: fillItems.length,
            itemBuilder: (context, index) {
              final item = fillItems[index];
              final answer = item["answer"]!;
              final image = item["image"]!;
              final letter = droppedLetters[index];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    // Image Box
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(image, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Drag Target + "ag"
                    Row(
                      children: [
                        DragTarget<String>(
                          onWillAccept: (data) => !usedLetters.contains(data),
                          onAccept: (data) {
                            setState(() {
                              // Remove previous letter if any
                              if (droppedLetters[index] != null) {
                                usedLetters.remove(droppedLetters[index]);
                              }

                              droppedLetters[index] = data;
                              usedLetters.add(data);

                              if (data == answer) {
                                boxColors[index] = Colors.green;
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
                          builder: (context, candidateData, rejectedData) {
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

        // Options Section
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

        // Footer
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
}
