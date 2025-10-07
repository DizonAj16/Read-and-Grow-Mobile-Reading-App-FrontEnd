import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../models/student_progress.dart';
import '../api/student_progress_service.dart';
import 'student_detail_screen.dart';

class ClassProgressPage extends StatefulWidget {
  final String classId;
  const ClassProgressPage({super.key, required this.classId});

  @override
  State<ClassProgressPage> createState() => _ClassProgressPageState();
}

class _ClassProgressPageState extends State<ClassProgressPage> {
  final _service = StudentProgressService();
  late Future<List<StudentProgress>> _future;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _future = _service.getClassProgress(widget.classId);
  }

  Future<void> _refresh() async {
    setState(() {
      isRefreshing = true;
      _future = _service.getClassProgress(widget.classId);
    });
    await _future;
    if (mounted) setState(() => isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Class Progress")),
      body: FutureBuilder<List<StudentProgress>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return _buildEmptyStateCard(context);
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final sp = students[index];
                return _buildStudentProgressCard(context, sp);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentProgressCard(BuildContext context, StudentProgress sp) {
    final double progress = (sp.quizAverage / 100).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(
                    sp.studentName.isNotEmpty
                        ? sp.studentName[0].toUpperCase()
                        : "?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sp.studentName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(
                progress >= 1 ? Colors.green : Colors.deepPurple,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 6),
            Text(
              "${sp.quizAverage.toStringAsFixed(1)}% Average Score",
              style: TextStyle(
                fontSize: 13,
                color: progress >= 1 ? Colors.green.shade700 : Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 120,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (sp.readingTime > sp.miscues
                      ? sp.readingTime.toDouble()
                      : sp.miscues.toDouble()) +
                      5,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Reading');
                            case 1:
                              return const Text('Miscues');
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

            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentDetailScreen(student: sp),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("View Details"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(BuildContext context) {
    return Center(
      child: Card(
        elevation: 6,
        shadowColor: Colors.deepPurple.withOpacity(0.2),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.deepPurple.withOpacity(0.1),
                child: Icon(
                  Icons.person_off_rounded,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "No Students Yet",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Students have not been assigned to this class.\nPlease check again later.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, _) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}
