import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReadingProgressPage extends StatefulWidget {
  const ReadingProgressPage({super.key});

  @override
  State<ReadingProgressPage> createState() => _ReadingProgressPageState();
}

class _ReadingProgressPageState extends State<ReadingProgressPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  double averageScore = 0.0;
  int totalTasks = 0;
  int completedTasks = 0;
  int totalAttemptsUsed = 0;
  List<double> lastFiveScores = [];
  String currentLevelTitle = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1️⃣ Fetch student's current reading level
      final studentRes = await supabase
          .from('students')
          .select('current_reading_level_id, reading_levels(title)')
          .eq('id', user.id)
          .maybeSingle();

      if (studentRes != null) {
        currentLevelTitle = studentRes['reading_levels']['title'] ?? 'No Level';
      }

      // 2️⃣ Fetch student progress (scores, attempts, completion)
      final progressRes = await supabase
          .from('student_task_progress')
          .select('score, max_score, completed, attempts_left')
          .eq('student_id', user.id)
          .order('updated_at', ascending: false);

      if (progressRes.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      totalTasks = progressRes.length;
      completedTasks = progressRes.where((p) => p['completed'] == true).length;
      totalAttemptsUsed = progressRes.fold<int>(
        0,
            (int sum, p) {
          final attemptsLeft = (p['attempts_left'] ?? 3) as int;
          return sum + (3 - attemptsLeft);
        },
      );


      // Compute average score
      final scores = progressRes
          .map((p) =>
      (p['max_score'] != 0 && p['max_score'] != null)
          ? (p['score'] ?? 0) / p['max_score']
          : 0.0)
          .toList();
      averageScore = scores.isNotEmpty
          ? scores.reduce((a, b) => a + b) / scores.length
          : 0.0;

      // Get last 5 trend scores
      lastFiveScores = scores.take(5).map((e) => (e as num).toDouble()).toList().reversed.toList();


      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Error loading progress: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = averageScore.clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("📈 My Reading Progress"),
        backgroundColor: Colors.purple.shade700,
      ),
      backgroundColor: const Color(0xFFF9F6FF),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadProgressData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 25),
            _buildProgressSection(percent),
            const SizedBox(height: 30),
            _buildSummaryCards(),
            const SizedBox(height: 30),
            _buildTrendChartSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD1C4E9), Color(0xFFB39DDB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Current Reading Level",
            style: TextStyle(
              fontSize: 16,
              color: Colors.purple.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentLevelTitle,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade900,
              fontFamily: 'ComicNeue',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(double percent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDE7F6), Color(0xFFF3E5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade100,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "📊 My Progress Report",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircularPercentIndicator(
                radius: 70,
                lineWidth: 10,
                percent: percent,
                animation: true,
                circularStrokeCap: CircularStrokeCap.round,
                center: Text(
                  "${(percent * 100).toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.purple.shade800,
                  ),
                ),
                progressColor: Colors.purpleAccent,
                backgroundColor: Colors.purple.shade100,
              ),
              const SizedBox(width: 10),
              Expanded(child: _buildMiniTrendLine()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTrendLine() {
    if (lastFiveScores.isEmpty) {
      return const Center(
        child: Text(
          "No recent scores yet",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                lastFiveScores.length,
                    (i) => FlSpot(i.toDouble(), lastFiveScores[i] * 100),
              ),
              isCurved: true,
              barWidth: 3,
              color: Colors.purpleAccent,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _summaryCard("Completed", completedTasks.toString(), Colors.green),
        _summaryCard("Total Tasks", totalTasks.toString(), Colors.blue),
        _summaryCard("Attempts Used", totalAttemptsUsed.toString(), Colors.orange),
      ],
    );
  }

  Widget _summaryCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChartSection() {
    if (lastFiveScores.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            "📈 Score Trend (Last 5 Tasks)",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade800,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                backgroundColor: Colors.transparent,
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      lastFiveScores.length,
                          (i) => FlSpot(i.toDouble(), lastFiveScores[i] * 100),
                    ),
                    isCurved: true,
                    color: Colors.deepPurpleAccent,
                    barWidth: 4,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurpleAccent.withOpacity(0.3),
                          Colors.deepPurpleAccent.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
