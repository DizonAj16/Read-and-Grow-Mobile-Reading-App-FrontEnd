import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/student_progress.dart';

class StudentDetailScreen extends StatelessWidget {
  final StudentProgress student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(student.studentName)),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // TODO: Add CRUD form for new quiz/task
        },
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Card
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

          // Quiz Results Header
          const Text(
            "Quiz Results",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Bar Chart for Quiz Scores
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

          // Quiz Results List
          ...student.quizResults.map(
                (quiz) => Card(
              child: ListTile(
                leading: const Icon(Icons.quiz),
                title: Text(
                  quiz['quizzes'] != null
                      ? quiz['quizzes']['title'] ?? 'Untitled Quiz'
                      : 'Untitled Quiz',
                ),
                subtitle: Text("Score: ${quiz['score']}%"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Edit quiz submission
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
