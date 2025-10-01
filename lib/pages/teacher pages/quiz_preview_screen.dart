import 'package:deped_reading_app_laravel/api/classroom_service.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20classes/class_details_page.dart';
import 'package:flutter/material.dart';
import '../../../../models/quiz_questions.dart';

/// Reusable screen for both preview (teacher) and actual quiz (student)
class QuizPreviewScreen extends StatefulWidget {
  final String title;
  final List<QuizQuestion> questions;

  /// Indicates whether the screen is being used as a teacher preview
  final bool isPreview;

  /// If preview (teacher), we need classDetails to go back
  final Map<String, dynamic>? classDetails;

  const QuizPreviewScreen({
    super.key,
    required this.title,
    required this.questions,
    this.isPreview = false, // default false for students
    this.classDetails,      // only required for teacher preview
  });

  @override
  State<QuizPreviewScreen> createState() => _QuizPreviewScreenState();
}

class _QuizPreviewScreenState extends State<QuizPreviewScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize user answers
    for (var q in widget.questions) {
      q.userAnswer = q.userAnswer ?? '';
      q.matchingPairs ??= [];
      for (var pair in q.matchingPairs!) {
        pair.userSelected = pair.userSelected ?? '';
      }
    }
  }

  // Build question widget
  Widget _buildQuestionWidget(QuizQuestion q) {
    if (q.type == QuestionType.multipleChoice && q.options!.isNotEmpty) {
      return Column(
        children: q.options!.map((opt) {
          final isCorrect = q.correctAnswer == opt;
          return ListTile(
            title: Text(
              opt,
              style: TextStyle(
                color: widget.isPreview && isCorrect ? Colors.green : null,
                fontWeight: widget.isPreview && isCorrect
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            leading: widget.isPreview
                ? Icon(
              isCorrect
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: isCorrect ? Colors.green : Colors.grey,
            )
                : Radio<String>(
              value: opt,
              groupValue: q.userAnswer,
              onChanged: (val) => setState(() {
                q.userAnswer = val ?? '';
              }),
            ),
          );
        }).toList(),
      );
    }

    if (q.type == QuestionType.fillInTheBlank) {
      return widget.isPreview
          ? Text(
        'Correct Answer: ${q.correctAnswer ?? ""}',
        style: const TextStyle(color: Colors.green),
      )
          : TextField(
        decoration: const InputDecoration(labelText: 'Your Answer'),
        onChanged: (val) => q.userAnswer = val,
      );
    }

    if (q.type == QuestionType.dragAndDrop && q.options!.isNotEmpty) {
      return widget.isPreview
          ? Column(
        children: q.options!
            .map((opt) => ListTile(
          title: Text(opt),
          leading: const Icon(Icons.drag_handle, color: Colors.grey),
        ))
            .toList(),
      )
          : ReorderableListView(
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
      );
    }

    if (q.type == QuestionType.matching && q.matchingPairs!.isNotEmpty) {
      return widget.isPreview
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: q.matchingPairs!.map((pair) {
          return Row(
            children: [
              Expanded(child: Text(pair.leftItem)),
              const SizedBox(width: 8),
              Expanded(
                child: (pair.rightItemUrl != null &&
                    pair.rightItemUrl!.isNotEmpty)
                    ? Image.network(
                  pair.rightItemUrl!,
                  height: 60,
                  fit: BoxFit.cover,
                )
                    : const SizedBox(),
              ),
            ],
          );
        }).toList(),
      )
          : Column(
        children: [
          const SizedBox(height: 8),
          const Text(
            'Drag the text to match the images',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
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
                        child: Text(
                          pair.leftItem,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    childWhenDragging: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey[300],
                      child: Text(pair.leftItem),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.all(4),
                      color: Colors.blue[100],
                      child: Text(pair.leftItem),
                    ),
                  ))
                      .toList(),
                ),
              ),
              const SizedBox(width: 10),
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
                              child: (pair.rightItemUrl != null &&
                                  pair.rightItemUrl!.isNotEmpty)
                                  ? Image.network(
                                pair.rightItemUrl!,
                                fit: BoxFit.contain,
                              )
                                  : const SizedBox(),
                            ),
                            Text(pair.userSelected!.isEmpty
                                ? 'Drop text here'
                                : pair.userSelected!),
                          ],
                        ),
                      );
                    },
                  ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return const SizedBox();
  }

  // Refresh class details from API
  Future<Map<String, dynamic>> _fetchUpdatedClassDetails() async {
    if (widget.classDetails == null) return {};
    final classId = widget.classDetails!['id'];
    final updatedData = await ClassroomService.getClassDetails(classId);
    return updatedData;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.isPreview && widget.classDetails != null) {
          final updatedData = await _fetchUpdatedClassDetails();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ClassDetailsPage(classDetails: updatedData),
              ),
            );
          }
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isPreview
              ? 'Quiz Preview: ${widget.title}'
              : widget.title),
          leading: widget.isPreview ? null : const BackButton(),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...widget.questions.asMap().entries.map((entry) {
              final index = entry.key;
              final q = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${q.questionText}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildQuestionWidget(q),
                    ],
                  ),
                ),
              );
            }).toList(),

            if (widget.isPreview && widget.classDetails != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final updatedData = await _fetchUpdatedClassDetails();
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ClassDetailsPage(classDetails: updatedData),
                          ),
                        );
                      }
                    },
                    child: const Text("Finish"),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
