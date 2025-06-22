import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

class CatAndRatPage extends StatefulWidget {
  const CatAndRatPage({super.key});

  @override
  _CatAndRatPageState createState() => _CatAndRatPageState();
}

class _CatAndRatPageState extends State<CatAndRatPage> {
  final String _storyText =
      "A cat sat. "
      "He sat on a hat. "
      "It was red. "
      "The hat was on the mat. "
      "That cat sat and sat. "
      "He saw a rat. "
      "That cat ran!";

  final String _wordList = "cat, mat, hat, sat, rat, ran";

  final FlutterTts _flutterTts = FlutterTts();

  Future<void> _speakWordList() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.4); // Adjust speech rate for kids
    await _flutterTts.speak(_wordList);
  }

  Future<void> _speakStory() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.3);
    await _flutterTts.speak(_storyText);
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
        // Main content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Cat and Rat",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    _storyText,
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Image.asset(
                    "assets/activity_images/cat.jpg",
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Image.asset(
              "assets/activity_images/rat.jpg",
              height: 150,
              fit: BoxFit.contain,
            ),
          ],
        ),
        // Word list positioned in the upper right
        Positioned(
          top: 50,
          right: 5,
          child: Container(
            width: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      "cat   mat   hat",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "sat   rat   ran",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // TTS button for word list at the top left
        Positioned(
          top: 60,
          left: 140,
          child: FloatingActionButton(
            heroTag: "wordListButton", // Unique heroTag for this button
            onPressed: _speakWordList,
            child: Icon(Icons.volume_up, size: 30),
            mini: true,
          ),
        ),
        // Guide text above the text-to-speech button
        Positioned(
          bottom: 120,
          right: 20,
          child: Text(
            "Tap this sound button to hear the story.",
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
        // Text-to-speech button
        Positioned(
          bottom: 50,
          right: 20,
          child: FloatingActionButton(
            heroTag: "storyButton", // Unique heroTag for this button
            onPressed: _speakStory,
            child: Icon(Icons.volume_up, size: 30),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Text(
            "© K5 Learning 2019",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

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

class FillInTheBlanksPage extends StatefulWidget {
  const FillInTheBlanksPage({super.key});

  @override
  State<FillInTheBlanksPage> createState() => _FillInTheBlanksPageState();
}

class _FillInTheBlanksPageState extends State<FillInTheBlanksPage> {
  final List<TextEditingController> controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  final List<String> correctAnswers = ['mat', 'rat', 'ran'];
  final List<bool?> answerStatus = [null, null, null]; // null = unchecked

  void checkAnswers() {
    setState(() {
      for (int i = 0; i < correctAnswers.length; i++) {
        final userAnswer = controllers[i].text.trim().toLowerCase();
        answerStatus[i] = userAnswer == correctAnswers[i];
      }
    });
  }

  @override
  void dispose() {
    for (var c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "2. Fill in the blanks.",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 22, color: Colors.black),
                  children: [
                    const TextSpan(text: "The cat sat on a red "),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: FillBlankField(
                        controller: controllers[0],
                        isCorrect: answerStatus[0],
                      ),
                    ),
                    const TextSpan(text: ".\nThe cat saw a "),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: FillBlankField(
                        controller: controllers[1],
                        isCorrect: answerStatus[1],
                      ),
                    ),
                    const TextSpan(text: ".\nThen he "),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: FillBlankField(
                        controller: controllers[2],
                        isCorrect: answerStatus[2],
                      ),
                    ),
                    const TextSpan(text: "!"),
                  ],
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: checkAnswers,
                      child: const Text("Check Answers"),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "© K5 Learning 2019",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
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

class FillBlankField extends StatelessWidget {
  final TextEditingController controller;
  final bool? isCorrect;

  const FillBlankField({super.key, required this.controller, this.isCorrect});

  @override
  Widget build(BuildContext context) {
    Color? borderColor;
    if (isCorrect != null) {
      borderColor = isCorrect! ? Colors.green : Colors.red;
    }

    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor ?? Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor ?? Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: borderColor ?? Theme.of(context).primaryColor,
            ),
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
