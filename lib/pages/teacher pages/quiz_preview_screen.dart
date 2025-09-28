import 'package:flutter/material.dart';
import '../../../../api/supabase_api_service.dart';
import '../../../../models/quiz_questions.dart';

/// 2️⃣ Screen for dynamic quiz preview
class QuizPreviewScreen extends StatefulWidget {
  final String title;
  final List<QuizQuestion> questions;

  const QuizPreviewScreen({super.key, required this.title, required this.questions});

  @override
  State<QuizPreviewScreen> createState() => _QuizPreviewScreenState();
}

class _QuizPreviewScreenState extends State<QuizPreviewScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize userAnswer and userSelected for all questions/pairs
    for (var q in widget.questions) {
      q.userAnswer = q.userAnswer ?? '';
      q.matchingPairs ??= [];
      for (var pair in q.matchingPairs!) {
        pair.userSelected = pair.userSelected ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quiz Preview: ${widget.title}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: widget.questions.length,
          itemBuilder: (context, index) {
            final q = widget.questions[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${index + 1}. ${q.questionText}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // MULTIPLE CHOICE
                    if (q.type == QuestionType.multipleChoice && q.options!.isNotEmpty)
                      Column(
                        children: q.options!.map((opt) => ListTile(
                          title: Text(opt),
                          leading: Radio<String>(
                            value: opt,
                            groupValue: q.userAnswer,
                            onChanged: (val) => setState(() => q.userAnswer = val ?? ''),
                          ),
                        )).toList(),
                      ),

                    // FILL IN THE BLANK
                    if (q.type == QuestionType.fillInTheBlank)
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Answer: ${q.correctAnswer ?? ''}',
                        ),
                        onChanged: (val) => q.userAnswer = val,
                      ),

                    // DRAG & DROP
                    if (q.type == QuestionType.dragAndDrop && q.options!.isNotEmpty)
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = q.options!.removeAt(oldIndex);
                            q.options!.insert(newIndex, item);
                          });
                        },
                        children: [
                          for (int i = 0; i < q.options!.length; i++)
                            ListTile(
                              key: ValueKey('${q.options![i]}-$i'),
                              title: Text(q.options![i]),
                              trailing: const Icon(Icons.drag_handle),
                            )
                        ],
                      ),

                    // MATCHING
                    if (q.type == QuestionType.matching && q.matchingPairs!.isNotEmpty)
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          const Text('Drag the texdt to match the images',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Left column: draggable text
                              Expanded(
                                child: ListView(
                                  shrinkWrap: true,
                                  children: q.matchingPairs!
                                      .map((pair) => Draggable<String>(
                                    data: pair.leftItem,
                                    feedback: Material(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        color: Colors.blue,
                                        child: Text(pair.leftItem,
                                            style: const TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                    childWhenDragging: Container(
                                      padding: const EdgeInsets.all(8),
                                      color: Colors.grey[300],
                                      child: Text(pair.leftItem),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      color: Colors.blue[100],
                                      child: Text(pair.leftItem),
                                    ),
                                  )).toList(),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Right column: drop targets (images)
                              Expanded(
                                child: ListView(
                                  shrinkWrap: true,
                                  children: q.matchingPairs!
                                      .map((pair) => DragTarget<String>(
                                    onAccept: (received) {
                                      setState(() {
                                        pair.userSelected = received;
                                      });
                                    },
                                    builder: (context, candidateData, rejectedData) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        padding: const EdgeInsets.all(8),
                                        height: 100,
                                        color: Colors.green[100],
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: (pair.rightItemUrl?.isNotEmpty ?? false)
                                                  ? Image.network(pair.rightItemUrl!, fit: BoxFit.contain)
                                                  : const SizedBox(),
                                            ),
                                            Text(pair.userSelected!.isEmpty
                                                ? 'Drop text here'
                                                : pair.userSelected!),
                                          ],
                                        ),
                                      );
                                    },
                                  )).toList(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
