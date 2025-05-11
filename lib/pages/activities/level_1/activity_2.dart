import 'package:flutter/material.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(child: _pages[_currentPage]),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                  child: const Text("Previous"),
                ),
                Text(
                  "Page ${_currentPage + 1} of ${_pages.length}",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                ElevatedButton(
                  onPressed:
                      _currentPage < _pages.length - 1 ? _goToNextPage : null,
                  child: const Text("Next"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CatAndRatPage extends StatelessWidget {
  const CatAndRatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Center(
                  child: Text(
                    "Cat and Rat",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
            Row(
              children: [
                Text(
                  "A cat sat.\n"
                  "He sat on a hat.\n"
                  "It was red.\n"
                  "The hat was on the mat.\n"
                  "That cat sat and sat.\n"
                  "He saw a rat.\n"
                  "That cat ran!",
                  style: TextStyle(fontSize: 20, color: Colors.black),
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
          right: 16,
          child: Container(
            width: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
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

class MatchingExercisePage extends StatelessWidget {
  const MatchingExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Cat and Rat (exercises)",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "1. Draw a line to match the word and picture.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                // Words column
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("cat", style: TextStyle(fontSize: 20)),
                      Text("hat", style: TextStyle(fontSize: 20)),
                      Text("mat", style: TextStyle(fontSize: 20)),
                      Text("rat", style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
                // Images column
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Image.asset(
                        "assets/activity_images/rat.jpg",
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      Image.asset(
                        "assets/activity_images/cat.jpg",
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      Image.asset(
                        "assets/activity_images/hat.png",
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      Image.asset(
                        "assets/activity_images/mat.png",
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ],
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
      ),
    );
  }
}

class FillInTheBlanksPage extends StatelessWidget {
  const FillInTheBlanksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
              style: TextStyle(fontSize: 22, color: Colors.black),
              children: [
                const TextSpan(text: "The cat sat on a red "),
                WidgetSpan(
                  child: SizedBox(
                    height: 30,
                    width: 100,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ".\nThe cat saw a "),
                WidgetSpan(
                  child: SizedBox(
                    height: 30,
                    width: 100,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ".\nThen he "),
                WidgetSpan(
                  child: SizedBox(
                    height: 30,
                    width: 100,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: "!"),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            "3. Draw the two animals from the story.",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
            ),
          ),
          const Spacer(),
          Align(
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
