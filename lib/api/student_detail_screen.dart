import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_progress.dart';

class StudentDetailScreen extends StatelessWidget {
  final StudentProgress student;
  const StudentDetailScreen({super.key, required this.student});

  void _showFeedbackDialog(BuildContext context, String submissionId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Feedback'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Write your feedback here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveFeedback(submissionId, controller.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback saved!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFeedback(String submissionId, String feedback) async {
    final supabase = Supabase.instance.client;

    await supabase
        .from('student_submissions')
        .update({'teacher_feedback': feedback})
        .eq('id', submissionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(student.studentName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text("Summary"),
              subtitle: Text(
                "Reading Time: ${student.readingTime} mins\n"
                    "Miscues: ${student.miscues}\n"
                    "Quiz Average: ${student.quizAverage.toStringAsFixed(1)}%",
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "Quiz Results",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (student.quizResults.isNotEmpty)
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < student.quizResults.length) {
                            return Text("Q${index + 1}");
                          }
                          return const Text("");
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(student.quizResults.length, (i) {
                    final quiz = student.quizResults[i];
                    final score = (quiz['score'] as num).toDouble();
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: score,
                          color: Colors.blue,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),

          const SizedBox(height: 16),
          ...student.quizResults.map(
                (quiz) => Card(
              child: ListTile(
                leading: const Icon(Icons.quiz),
                title: Text(
                  quiz['quizzes']?['title'] ?? 'Untitled Quiz',
                ),
                subtitle: Text("Score: ${quiz['score']}%"),
                trailing: IconButton(
                  icon: const Icon(Icons.feedback_outlined),
                  onPressed: () {
                    final submissionId = quiz['id'] ?? quiz['submission_id'] ?? quiz['quiz_id'];
                    if (submissionId != null && submissionId is String) {
                      _showFeedbackDialog(context, submissionId);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cannot find submission ID for feedback.')),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
