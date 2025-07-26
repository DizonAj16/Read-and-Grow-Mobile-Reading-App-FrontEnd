import 'package:flutter/material.dart';

class DayFiveEssayPage extends StatefulWidget {
  final VoidCallback? onCompleted;

  const DayFiveEssayPage({super.key, this.onCompleted});

  @override
  State<DayFiveEssayPage> createState() => _DayFiveEssayPageState();
}

class _DayFiveEssayPageState extends State<DayFiveEssayPage> {
  final TextEditingController _essayController = TextEditingController();
  String? _confirmationMessage;

  Future<void> _submitEssay() async {
    final text = _essayController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _confirmationMessage = "⚠️ Please write something before submitting.";
      });
      return;
    }

    // 👇 Commented out Laravel API connection for now
    /*
    try {
      final url = Uri.parse('http://your-laravel-api.com/api/essays');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'day': 5, 'text': text}),
      );

      if (response.statusCode == 201) {
        setState(() {
          _confirmationMessage = "✅ Your essay has been submitted.";
        });
      } else {
        setState(() {
          _confirmationMessage = "❌ Submission failed. Try again.";
        });
        print("Error: ${response.body}");
      }
    } catch (e) {
      setState(() {
        _confirmationMessage = "❌ Error connecting to server.";
      });
      print("Exception: $e");
    }
    */

    // ✅ Temporary confirmation (no backend)
    setState(() {
      _confirmationMessage = "📝 Essay saved locally (not submitted).";
    });

    // ✅ Notify parent page (e.g. Activity13Page) that essay is complete
    if (widget.onCompleted != null) {
      widget.onCompleted!();
    }

    // _essayController.clear(); // Optional
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reread the text “A New Friend for Nick.” Then, read the prompt and respond on the lines below.',
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Day 5: How Would You Care for a Pet?",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextField(
                              controller: _essayController,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              style: const TextStyle(
                                fontSize: 17,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                              decoration: const InputDecoration(
                                hintText: "Start writing your essay...",
                                border: InputBorder.none,
                              ),
                              cursorColor: Colors.blueAccent,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _submitEssay,
                          icon: const Icon(Icons.send),
                          label: const Text("Submit"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size(double.infinity, 48),
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (_confirmationMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _confirmationMessage!,
                            style: TextStyle(
                              color:
                                  _confirmationMessage!.startsWith("✅") ||
                                          _confirmationMessage!.startsWith("📝")
                                      ? Colors.green
                                      : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
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
