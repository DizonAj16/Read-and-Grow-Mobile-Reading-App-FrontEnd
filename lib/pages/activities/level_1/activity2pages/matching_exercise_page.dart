import 'package:flutter/material.dart';

class MatchingExercisePage extends StatefulWidget {
  const MatchingExercisePage({super.key});

  @override
  State<MatchingExercisePage> createState() => _MatchingExercisePageState();
}

class _MatchingExercisePageState extends State<MatchingExercisePage>
    with SingleTickerProviderStateMixin {
  final List<Map<String, String>> matchItems = [
    {"word": "cat", "image": "assets/activity_images/cat.jpg"},
    {"word": "hat", "image": "assets/activity_images/hat.png"},
    {"word": "mat", "image": "assets/activity_images/mat.png"},
    {"word": "rat", "image": "assets/activity_images/rat.jpg"},
  ];

  late List<String> shuffledWords;
  Map<int, String> matchedWords = {};
  Map<int, bool> matchResults = {};

  double opacityLevel = 1.0;
  bool isResetting = false;

  @override
  void initState() {
    super.initState();
    _shuffleWords();
  }

  void _shuffleWords() {
    shuffledWords = matchItems.map((item) => item['word']!).toList()..shuffle();
  }

  void _animatedReset() async {
    setState(() {
      opacityLevel = 0.0;
      isResetting = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      matchedWords.clear();
      matchResults.clear();
      _shuffleWords();
    });

    await Future.delayed(const Duration(milliseconds: 150));

    setState(() {
      opacityLevel = 1.0;
      isResetting = false;
    });
  }

  void _checkSingleAnswer(int index, String word) {
    final correctWord = matchItems[index]['word'];
    final isCorrect = word == correctWord;

    setState(() {
      matchedWords[index] = word;
      matchResults[index] = isCorrect;
    });

    if (!isCorrect) {
      _animatedReset(); // reset immediately if incorrect
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cat and Rat (exercises)")),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: opacityLevel,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "1. Drag the word to the matching picture.",
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Draggable Words
                              Expanded(
                                flex: 1,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children:
                                      shuffledWords.map((word) {
                                        final isUsed = matchedWords
                                            .containsValue(word);

                                        Widget wordTile = Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.lightBlue.shade100,
                                            border: Border.all(
                                              color: Colors.blue.shade700,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            word,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Draggable<String>(
                                            data: word,
                                            feedback: Material(
                                              color: Colors.transparent,
                                              child: wordTile,
                                            ),
                                            childWhenDragging: Opacity(
                                              opacity: 0.3,
                                              child: wordTile,
                                            ),
                                            child:
                                                isUsed
                                                    ? Opacity(
                                                      opacity: 0.4,
                                                      child: wordTile,
                                                    )
                                                    : wordTile,
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),

                              const SizedBox(width: 40),

                              // Drop Targets with Images
                              Expanded(
                                flex: 2,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(matchItems.length, (
                                    index,
                                  ) {
                                    final image = matchItems[index]['image']!;
                                    final matchedWord = matchedWords[index];
                                    final result = matchResults[index];

                                    Color borderColor;
                                    if (result == true) {
                                      borderColor = Colors.green;
                                    } else if (result == false) {
                                      borderColor = Colors.red;
                                    } else {
                                      borderColor = Colors.grey;
                                    }

                                    return DragTarget<String>(
                                      builder: (
                                        context,
                                        candidateData,
                                        rejectedData,
                                      ) {
                                        return Container(
                                          height: 140,
                                          padding: const EdgeInsets.all(8),
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: borderColor,
                                              width: 3,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: Colors.grey.shade200,
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Image.asset(
                                                image,
                                                fit: BoxFit.contain,
                                                height: 100,
                                              ),
                                              if (matchedWord != null)
                                                Positioned(
                                                  bottom: 4,
                                                  child: Container(
                                                    color: Colors.white70,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    child: Text(
                                                      matchedWord,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                      onWillAccept:
                                          (data) =>
                                              !matchedWords.containsValue(data),
                                      onAccept: (data) {
                                        _checkSingleAnswer(index, data);
                                      },
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "© K5 Learning 2019",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
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
          },
        ),
      ),
    );
  }
}
