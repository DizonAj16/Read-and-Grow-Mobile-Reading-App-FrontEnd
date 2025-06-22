import 'package:flutter/material.dart';

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
