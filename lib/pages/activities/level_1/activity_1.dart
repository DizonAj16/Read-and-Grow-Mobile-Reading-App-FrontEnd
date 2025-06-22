import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Activity1Page extends StatefulWidget {
  const Activity1Page({super.key});

  @override
  _Activity1PageState createState() => _Activity1PageState();
}

class _Activity1PageState extends State<Activity1Page> {
  int _currentPage = 0;

  final List<Widget> _pages = [
    const AgFamilyPage(),
    const MatchPicturesPage(),
    const MatchWordsToPicturesPage(),
    const FillInTheBlanksPage(),
    const ReadingPage(),
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

// Widget for the "Ag Family" page
class AgFamilyPage extends StatefulWidget {
  const AgFamilyPage({super.key});

  @override
  _AgFamilyPageState createState() => _AgFamilyPageState();
}

class _AgFamilyPageState extends State<AgFamilyPage> {
  final List<String> agFamilyWords = [
    'bag',
    'jag',
    'tag',
    'nag',
    'sag',
    'dag',
    'mag',
    'rag',
    'lag',
    'wag',
  ];

  final Map<String, String> wordImages = {
    'bag': 'assets/activity_images/bag.jpg',
    'jag': 'assets/activity_images/jag.jpg',
    'tag': 'assets/activity_images/tag.jpg',
    'nag': 'assets/activity_images/nag.png',
    'sag': 'assets/activity_images/sag.jpg',
    'dag': 'assets/activity_images/dag.jpg',
    'mag': 'assets/activity_images/mag.jpg',
    'rag': 'assets/activity_images/rag.jpg',
    'lag': 'assets/activity_images/lag.png',
    'wag': 'assets/activity_images/wag.jpg',
  };

  final FlutterTts _flutterTts = FlutterTts();
  int _highlightIndex = -1;
  final ScrollController _scrollController = ScrollController();

  Future<void> _speakWords() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.3);

    for (int i = 0; i < agFamilyWords.length; i++) {
      setState(() {
        _highlightIndex = i;
      });
      await _flutterTts.speak(agFamilyWords[i]);
      final position = (i ~/ 2) * 210.0;
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      await Future.delayed(const Duration(seconds: 2));
    }
    setState(() {
      _highlightIndex = -1;
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    "assets/activity_images/ag-family.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: GridView.builder(
                    controller: _scrollController,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          childAspectRatio: 0.9,
                        ),
                    itemCount: agFamilyWords.length,
                    itemBuilder: (context, index) {
                      final word = agFamilyWords[index];
                      final isHighlighted = _highlightIndex == index;

                      return Container(
                        decoration: BoxDecoration(
                          color:
                              isHighlighted
                                  ? Colors.deepPurple.withOpacity(0.1)
                                  : Colors.grey[200],
                          border: Border.all(
                            color:
                                isHighlighted ? Colors.deepPurple : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  wordImages[word] ?? 'assets/placeholder.jpg',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              word,
                              style: TextStyle(
                                color:
                                    isHighlighted
                                        ? Colors.deepPurple
                                        : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 10,
            child: FloatingActionButton(
              onPressed: _speakWords,
              child: const Icon(Icons.volume_up, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget for the "Match Pictures" page

class MatchPicturesPage extends StatefulWidget {
  const MatchPicturesPage({super.key});

  @override
  State<MatchPicturesPage> createState() => _MatchPicturesPageState();
}

class _MatchPicturesPageState extends State<MatchPicturesPage> {
  final List<Map<String, String>> originalItems = [
    {"image": "assets/activity_images/tag.jpg", "word": "tag"},
    {"image": "assets/activity_images/bag.jpg", "word": "bag"},
    {"image": "assets/activity_images/wag.jpg", "word": "wag"},
    {"image": "assets/activity_images/rag.jpg", "word": "rag"},
    {"image": "assets/activity_images/nag.png", "word": "nag"},
  ];

  late List<Map<String, String>> shuffledItems;
  int currentIndex = 0;
  bool showFeedback = false;
  bool isCorrect = false;

  @override
  void initState() {
    super.initState();
    shuffledItems = List<Map<String, String>>.from(originalItems);
    shuffledItems.shuffle(Random());
  }

  void checkAnswer(String selectedWord) {
    final correctWord = shuffledItems[currentIndex]["word"];
    setState(() {
      isCorrect = selectedWord == correctWord;
      showFeedback = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        showFeedback = false;
        if (isCorrect) {
          currentIndex++;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentIndex >= shuffledItems.length) {
      return const Center(
        child: Text(
          "Great job! You matched all the words.",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      );
    }

    final currentItem = shuffledItems[currentIndex];
    final allWords = originalItems.map((item) => item["word"]!).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "Tap the correct word for the picture.",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(currentItem["image"]!, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                allWords.map((word) {
                  return ElevatedButton(
                    onPressed: showFeedback ? null : () => checkAnswer(word),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: Text(word, style: const TextStyle(fontSize: 18)),
                  );
                }).toList(),
          ),
          const SizedBox(height: 30),
          if (showFeedback)
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
    );
  }
}

class MatchWordsToPicturesPage extends StatefulWidget {
  const MatchWordsToPicturesPage({super.key});

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
  late Map<int, String?> matchedWords;
  late Map<int, Color> borderColors;

  @override
  void initState() {
    super.initState();

    // Always keep "rag" first
    final first = allItems[0];
    final rest = allItems.sublist(1)..shuffle();
    allItems
      ..clear()
      ..add(first)
      ..addAll(rest);

    final words = allItems.map((e) => e["word"]!).toList();
    shuffledWords = [words.first, ...words.sublist(1)..shuffle()];

    matchedWords = {for (int i = 0; i < allItems.length; i++) i: null};

    borderColors = {for (int i = 0; i < allItems.length; i++) i: Colors.grey};
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "-ag Word Family: Match the word with the correct picture.",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: allItems.length,
            itemBuilder: (context, index) {
              final expectedWord = allItems[index]["word"]!;
              final imagePath = allItems[index]["image"]!;
              final currentMatch = matchedWords[index];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    // Draggable words (shuffled)
                    Expanded(
                      flex: 1,
                      child: _buildDraggableWord(
                        shuffledWords[index],
                        currentMatch,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // DragTarget images (fixed order)
                    Expanded(
                      flex: 1,
                      child: DragTarget<String>(
                        onAccept: (receivedWord) {
                          if (receivedWord == expectedWord) {
                            setState(() {
                              matchedWords[index] = receivedWord;
                              borderColors[index] = Colors.green;
                            });
                          } else {
                            setState(() {
                              borderColors[index] = Colors.red;
                            });
                            Future.delayed(const Duration(seconds: 1), () {
                              setState(() {
                                borderColors[index] = Colors.grey;
                              });
                            });
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColors[index]!,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                imagePath,
                                fit: BoxFit.contain,
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
        Align(
          alignment: Alignment.bottomRight,
          child: Text(
            "© Live Work Sheets",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableWord(String word, String? currentMatch) {
    final isMatched = word == currentMatch;
    return Draggable<String>(
      data: word,
      feedback: Material(
        color: Colors.transparent,
        child: _buildWordCard(word, isMatched),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildWordCard(word, isMatched),
      ),
      child: _buildWordCard(word, isMatched),
    );
  }

  Widget _buildWordCard(String word, bool isMatched) {
    return Card(
      color: isMatched ? Colors.green : Colors.blue,
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
}

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

class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key});

  @override
  _ReadingPageState createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  final List<String> sentences = [
    "The bag is on the cab.",
    "Gab is on the cab.",
    "Gab's bag has a jam.",
    "Gab's bag has a jam and a cam.",
  ];

  final FlutterTts _flutterTts = FlutterTts();

  Future<void> _speakSentences() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.3); // Reduced speech rate for kids
    await _flutterTts.speak(sentences.join(" "));
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Read the sentences below:",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: sentences.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      sentences[index],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 120,
          right: 20,
          child: Text(
            "Tap this sound button to hear \n the sentences.",
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
        Positioned(
          bottom: 50,
          right: 20,
          child: FloatingActionButton(
            onPressed: _speakSentences,
            child: Icon(Icons.volume_up, size: 30),
          ),
        ),
      ],
    );
  }
}

// Widget for displaying a word card
class WordCard extends StatelessWidget {
  final String word;

  const WordCard({super.key, required this.word});

  // Function to get a random color for the card
  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    return colors[Random().nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: _getRandomColor(),
      child: Center(
        child: Text(
          word,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
