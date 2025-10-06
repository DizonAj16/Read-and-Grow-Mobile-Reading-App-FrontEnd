import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/student_progress.dart';
import '../api/student_progress_service.dart';
import 'student_detail_screen.dart';

class ClassProgressScreen extends StatefulWidget {
  final String classId;
  const ClassProgressScreen({super.key, required this.classId});

  @override
  State<ClassProgressScreen> createState() => _ClassProgressScreenState();
}

class _ClassProgressScreenState extends State<ClassProgressScreen> {
  final _service = StudentProgressService();
  late Future<List<StudentProgress>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getClassProgress(widget.classId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Progress")),
      body: FutureBuilder<List<StudentProgress>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return const Center(child: Text("No students yet."));

          final students = snapshot.data!;

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, i) {
              final sp = students[i];

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Info
                      Text(
                        sp.studentName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Total Score: ${sp.readingTime} | Wrong Answers: ${sp.miscues} | Avg: ${sp.quizAverage.toStringAsFixed(1)}%",
                      ),
                      const SizedBox(height: 12),

                      // Chart
                      SizedBox(
                        height: 150,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (sp.readingTime > sp.miscues ? sp.readingTime.toDouble() : sp.miscues.toDouble()) + 5,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, meta) {
                                    switch (value.toInt()) {
                                      case 0:
                                        return const Text('Score');
                                      case 1:
                                        return const Text('Wrong');
                                      default:
                                        return const Text('');
                                    }
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                            ),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                            barGroups: [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: sp.readingTime.toDouble(),
                                    color: Colors.green,
                                    width: 20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: sp.miscues.toDouble(),
                                    color: Colors.red,
                                    width: 20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentDetailScreen(student: sp),
                            ),
                          );
                        },
                        child: const Text("View Details"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
