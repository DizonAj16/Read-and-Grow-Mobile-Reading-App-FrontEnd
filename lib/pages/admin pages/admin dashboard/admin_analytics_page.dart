import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Admin Analytics Page - Monitor overall app usage and student performance
class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  
  // App Usage Statistics
  int _totalStudents = 0;
  int _totalTeachers = 0;
  int _totalClasses = 0;
  int _activeStudents = 0;
  int _activeTeachers = 0;
  
  // Student Performance Statistics
  int _totalTasksCompleted = 0;
  int _totalQuizSubmissions = 0;
  double _averageScore = 0.0;
  double _averageQuizScore = 0.0;
  int _totalRecordings = 0;
  
  // Performance Trends
  List<Map<String, dynamic>> _dailyActivity = [];
  List<Map<String, dynamic>> _scoreDistribution = [];
  
  // Reading Level Distribution
  Map<String, int> _readingLevelDistribution = {};
  
  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _loadAppUsageStats(),
        _loadStudentPerformance(),
        _loadActivityTrends(),
        _loadReadingLevelDistribution(),
      ]);
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAppUsageStats() async {
    try {
      // Total students
      final students = await supabase.from('students').select('id');
      _totalStudents = students.length;
      
      // Total teachers
      final teachers = await supabase.from('teachers').select('id');
      _totalTeachers = teachers.length;
      
      // Total classes
      final classes = await supabase.from('class_rooms').select('id');
      _totalClasses = classes.length;
      
      // Active students (students who have completed at least one task in the last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final activeStudentsData = await supabase
          .from('student_task_progress')
          .select('student_id')
          .gte('updated_at', thirtyDaysAgo.toIso8601String());
      _activeStudents = activeStudentsData.map((s) => s['student_id']).toSet().length;
      
      // Active teachers (teachers who have created classes or graded work in last 30 days)
      final activeTeachersData = await supabase
          .from('class_rooms')
          .select('teacher_id')
          .gte('created_at', thirtyDaysAgo.toIso8601String());
      _activeTeachers = activeTeachersData.map((t) => t['teacher_id']).toSet().length;
    } catch (e) {
      debugPrint('Error loading app usage stats: $e');
    }
  }

  Future<void> _loadStudentPerformance() async {
    try {
      // Total tasks completed
      final tasks = await supabase
          .from('student_task_progress')
          .select('score, max_score, completed');
      _totalTasksCompleted = tasks.where((t) => t['completed'] == true).length;
      
      // Average score
      double totalScore = 0;
      double totalMax = 0;
      for (var task in tasks) {
        totalScore += (task['score'] ?? 0).toDouble();
        totalMax += (task['max_score'] ?? 0).toDouble();
      }
      _averageScore = totalMax > 0 ? (totalScore / totalMax) * 100 : 0.0;
      
      // Quiz submissions and average
      final quizzes = await supabase.from('student_submissions').select('score');
      _totalQuizSubmissions = quizzes.length;
      if (quizzes.isNotEmpty) {
        double quizTotal = 0;
        for (var quiz in quizzes) {
          quizTotal += (quiz['score'] ?? 0).toDouble();
        }
        _averageQuizScore = quizTotal / quizzes.length;
      }
      
      // Total recordings
      final recordings = await supabase
          .from('student_recordings')
          .select('id');
      _totalRecordings = recordings.length;
      
      // Score distribution (0-20, 21-40, 41-60, 61-80, 81-100)
      _scoreDistribution = [
        {'range': '0-20', 'count': 0},
        {'range': '21-40', 'count': 0},
        {'range': '41-60', 'count': 0},
        {'range': '61-80', 'count': 0},
        {'range': '81-100', 'count': 0},
      ];
      
      for (var task in tasks) {
        if (task['max_score'] != null && task['max_score'] > 0) {
          double percentage = ((task['score'] ?? 0) / task['max_score']) * 100;
          if (percentage <= 20) {
            _scoreDistribution[0]['count'] = (_scoreDistribution[0]['count'] as int) + 1;
          } else if (percentage <= 40) {
            _scoreDistribution[1]['count'] = (_scoreDistribution[1]['count'] as int) + 1;
          } else if (percentage <= 60) {
            _scoreDistribution[2]['count'] = (_scoreDistribution[2]['count'] as int) + 1;
          } else if (percentage <= 80) {
            _scoreDistribution[3]['count'] = (_scoreDistribution[3]['count'] as int) + 1;
          } else {
            _scoreDistribution[4]['count'] = (_scoreDistribution[4]['count'] as int) + 1;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading student performance: $e');
    }
  }

  Future<void> _loadActivityTrends() async {
    try {
      // Last 7 days of activity
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final activities = await supabase
          .from('student_task_progress')
          .select('updated_at')
          .gte('updated_at', sevenDaysAgo.toIso8601String());
      
      // Group by date
      Map<String, int> dailyCount = {};
      for (var activity in activities) {
        final date = DateTime.parse(activity['updated_at']);
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        dailyCount[dateKey] = (dailyCount[dateKey] ?? 0) + 1;
      }
      
      // Fill in missing days
      _dailyActivity = [];
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        _dailyActivity.add({
          'date': DateFormat('MMM dd').format(date),
          'count': dailyCount[dateKey] ?? 0,
        });
      }
    } catch (e) {
      debugPrint('Error loading activity trends: $e');
    }
  }

  Future<void> _loadReadingLevelDistribution() async {
    try {
      final students = await supabase
          .from('students')
          .select('current_reading_level_id, reading_levels(title)');
      
      _readingLevelDistribution = {};
      for (var student in students) {
        final levelTitle = student['reading_levels']?['title'] ?? 'Not Assigned';
        _readingLevelDistribution[levelTitle] = 
            (_readingLevelDistribution[levelTitle] ?? 0) + 1;
      }
    } catch (e) {
      debugPrint('Error loading reading level distribution: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Performance'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading analytics...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('App Usage Overview'),
                    _buildAppUsageCards(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Student Performance'),
                    _buildPerformanceCards(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Activity Trends (Last 7 Days)'),
                    _buildActivityChart(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Score Distribution'),
                    _buildScoreDistributionChart(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Reading Level Distribution'),
                    _buildReadingLevelChart(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildAppUsageCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Total Students', _totalStudents.toString(), Icons.people, Colors.blue),
        _buildStatCard('Total Teachers', _totalTeachers.toString(), Icons.person, Colors.green),
        _buildStatCard('Total Classes', _totalClasses.toString(), Icons.class_, Colors.orange),
        _buildStatCard('Active Students', _activeStudents.toString(), Icons.how_to_reg, Colors.purple),
        _buildStatCard('Active Teachers', _activeTeachers.toString(), Icons.verified_user, Colors.teal),
        _buildStatCard('Total Recordings', _totalRecordings.toString(), Icons.mic, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Tasks Completed',
          _totalTasksCompleted.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Quiz Submissions',
          _totalQuizSubmissions.toString(),
          Icons.quiz,
          Colors.blue,
        ),
        _buildStatCard(
          'Avg Task Score',
          '${_averageScore.toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.orange,
        ),
        _buildStatCard(
          'Avg Quiz Score',
          '${_averageQuizScore.toStringAsFixed(1)}%',
          Icons.assessment,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildActivityChart() {
    if (_dailyActivity.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No activity data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final maxValue = _dailyActivity.map((d) => d['count'] as int).reduce((a, b) => a > b ? a : b);
    final chartMax = maxValue > 0 ? (maxValue.toDouble() + (maxValue * 0.1)).ceilToDouble() : 10.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartMax,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _dailyActivity.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _dailyActivity[index]['date'] as String,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: _dailyActivity.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: (entry.value['count'] as int).toDouble(),
                          color: Theme.of(context).colorScheme.primary,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDistributionChart() {
    if (_scoreDistribution.isEmpty || _scoreDistribution.every((d) => d['count'] == 0)) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.assessment, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No score data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final maxValue = _scoreDistribution.map((d) => d['count'] as int).reduce((a, b) => a > b ? a : b);
    final chartMax = maxValue > 0 ? (maxValue.toDouble() + (maxValue * 0.1)).ceilToDouble() : 10.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartMax,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _scoreDistribution.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _scoreDistribution[index]['range'] as String,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: _scoreDistribution.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: (entry.value['count'] as int).toDouble(),
                          color: _getScoreColor(entry.key),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int index) {
    if (index <= 1) return Colors.red;
    if (index <= 2) return Colors.orange;
    if (index <= 3) return Colors.yellow;
    return Colors.green;
  }

  Widget _buildReadingLevelChart() {
    if (_readingLevelDistribution.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.menu_book, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No reading level data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final entries = _readingLevelDistribution.entries.toList();
    final maxValue = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final chartMax = maxValue > 0 ? (maxValue.toDouble() + (maxValue * 0.1)).ceilToDouble() : 10.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartMax,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < entries.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                entries[index].key,
                                style: const TextStyle(fontSize: 10),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: entries.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color: Theme.of(context).colorScheme.secondary,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              children: entries.map((entry) {
                return Chip(
                  label: Text('${entry.key}: ${entry.value}'),
                  backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

