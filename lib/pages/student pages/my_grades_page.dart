import 'dart:convert';
import 'package:deped_reading_app_laravel/pages/student%20pages/quiz_review_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';

class MyGradesPage extends StatefulWidget {
  const MyGradesPage({super.key});

  @override
  State<MyGradesPage> createState() => _MyGradesPageState();
}

class _MyGradesPageState extends State<MyGradesPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  late ColorScheme _colorScheme;

  bool isLoading = true;
  List<Map<String, dynamic>> quizScores = [];
  List<Map<String, dynamic>> readingGrades = [];
  Map<String, dynamic> analyticsData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllGrades();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorScheme = Theme.of(context).colorScheme;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getPrimaryColor([double opacity = 1.0]) {
    return _colorScheme.primary.withOpacity(opacity);
  }

  Color _getPrimaryContainerColor([double opacity = 1.0]) {
    return _colorScheme.primaryContainer.withOpacity(opacity);
  }

  Color _getOnPrimaryColor([double opacity = 1.0]) {
    return _colorScheme.onPrimary.withOpacity(opacity);
  }

  Color _getSurfaceVariantColor([double opacity = 1.0]) {
    return _colorScheme.surfaceVariant.withOpacity(opacity);
  }

  Color _getSecondaryColor([double opacity = 1.0]) {
    return _colorScheme.secondary.withOpacity(opacity);
  }

  Future<void> _loadAllGrades() async {
    setState(() => isLoading = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      await Future.wait([
        _loadQuizScores(user.id),
        _loadReadingGrades(user.id),
        _loadAnalyticsData(user.id),
      ]);
    } catch (e) {
      debugPrint('Error loading grades: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadAnalyticsData(String userId) async {
    try {
      // Load quiz scores for analytics
      final quizData = await supabase
          .from('student_submissions')
          .select('''
          score,
          max_score,
          submitted_at,
          assignments(
            tasks(
              quizzes(
                title
              )
            )
          )
        ''')
          .eq('student_id', userId);

      // Load reading grades for analytics
      final readingData = await supabase
          .from('student_recordings')
          .select('''
          score,
          graded_at,
          reading_materials(title)
        ''')
          .eq('student_id', userId)
          .eq('needs_grading', false)
          .not('score', 'is', null);

      // Calculate analytics
      List<Map<String, dynamic>> quizAnalytics = [];
      List<Map<String, dynamic>> readingAnalytics = [];
      double totalQuizScore = 0;
      double totalReadingScore = 0;
      int quizCount = 0;
      int readingCount = 0;
      List<double> recentScores = [];
      Map<String, List<double>> quizTypeScores = {};
      Map<String, List<double>> readingLevelScores = {};

      // Process quiz data
      for (var quiz in quizData) {
        final score = (quiz['score'] ?? 0) as num;
        final maxScore = (quiz['max_score'] ?? 1) as num;
        final percent = maxScore > 0 ? score / maxScore : 0;
        final quizTitle =
            quiz['assignments']?['tasks']?['quizzes']?[0]?['title'] ?? 'Quiz';

        totalQuizScore += percent;
        quizCount++;

        // Group by quiz type/category
        final category = _extractQuizCategory(quizTitle);
        quizTypeScores
            .putIfAbsent(category, () => <double>[])
            .add(percent.toDouble());

        // Store for recent scores
        recentScores.add(percent.toDouble());
      }

      // Process reading data
      for (var reading in readingData) {
        final score = (reading['score'] ?? 0) as num;
        final maxScore = 5.0; // Assuming max score is 5 for reading
        final percent = score / maxScore;
        final title = reading['reading_materials']?['title'] ?? 'Reading';

        totalReadingScore += percent;
        readingCount++;

        // Group by reading level
        final level = _extractReadingLevel(title);
        readingLevelScores
            .putIfAbsent(level, () => <double>[])
            .add(percent.toDouble());
      }

      // Calculate strengths and weaknesses
      final Map<String, double> strengths = <String, double>{};
      final Map<String, double> weaknesses = <String, double>{};

      // Analyze quiz categories
      for (var entry in quizTypeScores.entries) {
        final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        if (avg >= 0.7) strengths[entry.key] = avg;
        if (avg <= 0.5) weaknesses[entry.key] = avg;
      }

      // Analyze reading levels
      for (var entry in readingLevelScores.entries) {
        final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        if (avg >= 0.7) strengths[entry.key] = avg;
        if (avg <= 0.5) weaknesses[entry.key] = avg;
      }

      // Sort recent scores (last 10)
      recentScores.sort((a, b) => b.compareTo(a));
      final topScores = recentScores.take(5).toList();
      final bottomScores = recentScores.reversed.take(5).toList();

      setState(() {
        analyticsData = {
          'overallQuizScore': quizCount > 0 ? totalQuizScore / quizCount : 0,
          'overallReadingScore':
              readingCount > 0 ? totalReadingScore / readingCount : 0,
          'totalAttempts': quizCount + readingCount,
          'quizCount': quizCount,
          'readingCount': readingCount,
          'strengths': strengths,
          'weaknesses': weaknesses,
          'quizTypeScores': quizTypeScores,
          'readingLevelScores': readingLevelScores,
          'topScores': topScores,
          'bottomScores': bottomScores,
          'recentScores': recentScores.take(10).toList(),
        };
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }
  }

  String _extractQuizCategory(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('comprehension')) return 'Reading Comprehension';
    if (lower.contains('vocabulary')) return 'Vocabulary';
    if (lower.contains('grammar')) return 'Grammar';
    if (lower.contains('listening')) return 'Listening';
    if (lower.contains('writing')) return 'Writing';
    return 'General Knowledge';
  }

  String _extractReadingLevel(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('level 1') || lower.contains('beginner'))
      return 'Beginner';
    if (lower.contains('level 2') || lower.contains('intermediate'))
      return 'Intermediate';
    if (lower.contains('level 3') || lower.contains('advanced'))
      return 'Advanced';
    return 'General Reading';
  }

  Future<void> _loadQuizScores(String userId) async {
    try {
      final submissions = await supabase
          .from('student_submissions')
          .select('''
            id,
            score,
            max_score,
            submitted_at,
            assignment_id,
            assignments(
              tasks(
                title,
                quizzes(
                  id,
                  title
                )
              )
            )
          ''')
          .eq('student_id', userId)
          .order('submitted_at', ascending: false);

      final List<Map<String, dynamic>> scores = [];

      for (var submission in submissions) {
        final task = submission['assignments']?['tasks'];
        final quizzes = task?['quizzes'];

        if (quizzes != null && quizzes is List && quizzes.isNotEmpty) {
          final quiz = quizzes.first;
          scores.add({
            'id': submission['id'],
            'quiz_title': quiz['title'] ?? 'Untitled Quiz',
            'task_title': task?['title'] ?? 'Untitled Task',
            'score': submission['score'] ?? 0,
            'max_score': submission['max_score'] ?? 0,
            'submitted_at': submission['submitted_at'],
            'type': 'quiz',
          });
        }
      }

      if (mounted) {
        setState(() => quizScores = scores);
      }
    } catch (e) {
      debugPrint('Error loading quiz scores: $e');
    }
  }

  Future<void> _loadReadingGrades(String userId) async {
    try {
      // Fetch graded recordings with material info (reading materials)
      final recordingsRes = await supabase
          .from('student_recordings')
          .select('''
        id,
        task_id,
        material_id,
        score,
        teacher_comments,
        graded_at,
        graded_by,
        recorded_at,
        tasks(title, description),
        reading_materials(title, description)
      ''')
          .eq('student_id', userId)
          .eq('needs_grading', false)
          .not('score', 'is', null)
          .order('graded_at', ascending: false);

      final List<Map<String, dynamic>> grades = [];
      final Set<String> teacherIds = {};

      for (var recording in recordingsRes) {
        final gradedBy = recording['graded_by']?.toString();
        if (gradedBy != null) teacherIds.add(gradedBy);
      }

      // Fetch teacher names
      Map<String, String> teacherNames = {};
      if (teacherIds.isNotEmpty) {
        final teachersRes = await supabase
            .from('teachers')
            .select('id, teacher_name')
            .inFilter('id', teacherIds.toList());

        for (var teacher in teachersRes) {
          final tid = teacher['id']?.toString();
          if (tid != null)
            teacherNames[tid] = teacher['teacher_name'] ?? 'Unknown';
        }
      }

      for (var recording in recordingsRes) {
        final taskId = recording['task_id']?.toString();
        final score = recording['score'];
        final tasksData = recording['tasks'];
        final materialData = recording['reading_materials'];
        final teacherComments = recording['teacher_comments']?.toString();
        final gradedBy = recording['graded_by']?.toString();
        final gradedByName =
            gradedBy != null ? teacherNames[gradedBy] : 'Unknown';

        String title;
        String? description;

        if (taskId != null && taskId.isNotEmpty && tasksData != null) {
          if (tasksData is Map<String, dynamic>) {
            title = tasksData['title']?.toString() ?? 'Reading Task';
            description = tasksData['description']?.toString();
          } else {
            title = 'Reading Task';
          }
        } else if (materialData != null) {
          title = materialData['title'] ?? 'Reading Material';
          description = materialData['description'];
        } else {
          title = 'Reading Material';
          description = null;
        }

        grades.add({
          'id': recording['id'],
          'title': title,
          'description': description,
          'score':
              score is num
                  ? score.toDouble()
                  : double.tryParse(score.toString()) ?? 0.0,
          'max_score': 5.0,
          'teacher_comments': teacherComments,
          'graded_at': recording['graded_at'],
          'recorded_at': recording['recorded_at'],
          'graded_by_name': gradedByName,
          'type': 'reading',
        });
      }

      if (mounted) setState(() => readingGrades = grades);
    } catch (e) {
      debugPrint('Error loading reading grades: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '📊 My Grades & Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: primaryColor,
        foregroundColor: _getOnPrimaryColor(),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _getOnPrimaryColor(),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: _getOnPrimaryColor(),
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.normal,
            color: _getOnPrimaryColor(0.7),
          ),
          tabs: const [
            Tab(icon: Icon(Icons.quiz_outlined), text: 'Quiz Scores'),
            Tab(icon: Icon(Icons.mic_outlined), text: 'Reading Grades'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Analytics'),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading Grades & Analytics...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildQuizScoresTab(),
                  _buildReadingGradesTab(),
                  _buildAnalyticsTab(),
                ],
              ),
    );
  }

  Widget _buildAnalyticsTab() {
    final primaryColor = _getPrimaryColor();
    final secondaryColor = _getSecondaryColor();
    final primaryLight = _getPrimaryColor(0.1);
    final secondaryLight = _getSecondaryColor(0.1);

    if (analyticsData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No analytics data yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete more activities to see detailed analytics',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllGrades,
      color: primaryColor,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Performance Card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.9),
                    secondaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.insights_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Overall Performance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildScoreCard(
                        'Quiz Score',
                        '${(analyticsData['overallQuizScore'] * 100).toStringAsFixed(1)}%',
                        Icons.quiz_rounded,
                        Colors.white,
                      ),
                      _buildScoreCard(
                        'Reading Score',
                        '${(analyticsData['overallReadingScore'] * 100).toStringAsFixed(1)}%',
                        Icons.book_rounded,
                        Colors.white,
                      ),
                      _buildScoreCard(
                        'Total Attempts',
                        analyticsData['totalAttempts'].toString(),
                        Icons.check_circle_rounded,
                        Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Performance Trend Chart
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📈 Performance Trend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(height: 200, child: _buildTrendChart()),
                ],
              ),
            ),

            // Strengths & Weaknesses
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8, bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.thumb_up_rounded,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Strengths',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._buildStrengthsList(),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8, bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.thumb_down_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Areas to Improve',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._buildWeaknessesList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Category Performance
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Performance by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(height: 300, child: _buildCategoryChart()),
                ],
              ),
            ),

            // Score Distribution
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Score Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildScoreDistribution(),
                ],
              ),
            ),

            // Recommendations
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.lightbulb_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Learning Recommendations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._buildRecommendations(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildTrendChart() {
    final scores =
        (analyticsData['recentScores'] as List?)?.cast<double>() ?? [];

    if (scores.isEmpty) {
      return Center(
        child: Text(
          'No recent scores to display',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List<FlSpot>.generate(
              scores.length,
              (index) => FlSpot(index.toDouble(), scores[index]),
            ),
            isCurved: true,
            color: _getPrimaryColor(),
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _getPrimaryColor().withOpacity(0.3),
                  _getPrimaryColor().withOpacity(0.05),
                ],
              ),
            ),
            dotData: FlDotData(show: false),
          ),
        ],
        minY: 0,
        maxY: 1,
      ),
    );
  }

List<Widget> _buildStrengthsList() {
  final strengths = analyticsData['strengths'] ?? {};
  final List<Widget> widgets = []; // Explicitly create List<Widget>

  if (strengths.isEmpty) {
    widgets.add(
      Text(
        'No strengths identified yet',
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
    return widgets;
  }

  for (var entry in (strengths as Map).entries) {
    final key = entry.key.toString();
    final value = entry.value as double;
    
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                key,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return widgets;
}

List<Widget> _buildWeaknessesList() {
  final weaknesses = analyticsData['weaknesses'] ?? {};
  final List<Widget> widgets = []; // Explicitly create List<Widget>

  if (weaknesses.isEmpty) {
    widgets.add(
      Text(
        'No areas to improve identified yet',
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
    return widgets;
  }

  for (var entry in (weaknesses as Map).entries) {
    final key = entry.key.toString();
    final value = entry.value as double;
    
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                key,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return widgets;
}

  Widget _buildCategoryChart() {
    final quizScores =
        analyticsData['quizTypeScores'] ?? <String, List<double>>{};
    final readingScores =
        analyticsData['readingLevelScores'] ?? <String, List<double>>{};

    if (quizScores.isEmpty && readingScores.isEmpty) {
      return Center(
        child: Text(
          'No category data available',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    // Fixed line - added explicit type argument
    final allCategories = <String>{...quizScores.keys, ...readingScores.keys};
    final List<BarChartGroupData> barGroups = [];
    int index = 0;

    for (var category in allCategories) {
      double quizAvg = 0;
      double readingAvg = 0;

      if (quizScores.containsKey(category)) {
        final scores = quizScores[category] as List<double>;
        quizAvg = scores.reduce((a, b) => a + b) / scores.length;
      }

      if (readingScores.containsKey(category)) {
        final scores = readingScores[category] as List<double>;
        readingAvg = scores.reduce((a, b) => a + b) / scores.length;
      }

      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(toY: quizAvg, color: _getPrimaryColor(), width: 12),
            BarChartRodData(
              toY: readingAvg,
              color: _getSecondaryColor(),
              width: 12,
            ),
          ],
        ),
      );
      index++;
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
      ),
    );
  }

  Widget _buildScoreDistribution() {
    final topScores = analyticsData['topScores'] ?? [];
    final bottomScores = analyticsData['bottomScores'] ?? [];

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Scores',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              ...topScores.map((score) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearPercentIndicator(
                            percent: score,
                            lineHeight: 8,
                            backgroundColor: Colors.grey[200],
                            progressColor: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(score * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lowest Scores',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              ...bottomScores.map((score) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearPercentIndicator(
                            percent: score,
                            lineHeight: 8,
                            backgroundColor: Colors.grey[200],
                            progressColor: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(score * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, color: Colors.red[700]),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

List<Widget> _buildRecommendations() {
  final weaknesses = analyticsData['weaknesses'] ?? {};
  final List<Widget> recommendations = <Widget>[]; // Explicit List<Widget>

  if (weaknesses.isEmpty) {
    recommendations.add(
      Text(
        'Great job! Keep up the good work and continue practicing regularly.',
        style: TextStyle(color: Colors.grey[700]),
      ),
    );
  } else {
    int index = 1;
    for (var entry in (weaknesses as Map).entries) {
      final key = entry.key.toString();
      final value = entry.value as double;
      
      recommendations.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getPrimaryColor(),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Focus on improving your ${key.toLowerCase()} skills. Practice more exercises in this area.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      );
      index++;
    }
  }

  recommendations.add(
    const SizedBox(height: 12),
  );

  recommendations.add(
    Text(
      'General Tips:',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey[800],
      ),
    ),
  );

  recommendations.add(
    const SizedBox(height: 8),
  );

  final generalTips = [
    'Review mistakes from previous quizzes',
    'Practice reading aloud for better fluency',
    'Take notes while reading comprehension exercises',
    'Set aside regular study time each day',
    'Ask your teacher for specific feedback',
  ];

  for (var tip in generalTips) {
    recommendations.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tip,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  return recommendations;
}

  // Original quiz scores and reading grades tabs remain the same
  Widget _buildQuizScoresTab() {
    final primaryColor = _getPrimaryColor();
    final primaryLight = _getPrimaryColor(0.1);

    if (quizScores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No quiz scores yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete quizzes to see your scores here',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllGrades,
      color: primaryColor,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quizScores.length,
        itemBuilder: (context, index) {
          final score = quizScores[index];
          final scoreValue = ((score['score'] ?? 0) as num).toDouble();
          final maxScore = ((score['max_score'] ?? 0) as num).toDouble();
          final scorePercent = maxScore > 0 ? (scoreValue / maxScore) : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              color: Colors.white,
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => QuizReviewPage(
                            submissionId: score['id'].toString(),
                            studentId: supabase.auth.currentUser!.id,
                          ),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.all(20),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: _getScoreGradient(
                      scorePercent.toDouble(),
                      primaryColor,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getScoreColor(
                          scorePercent.toDouble(),
                        ).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getScoreIcon(scorePercent.toDouble()),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    score['quiz_title'] ?? 'Untitled Quiz',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueGrey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (score['task_title'] != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          score['task_title'],
                          style: TextStyle(
                            fontSize: 11,
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 8),
                    _buildDateTimeDisplay(score['submitted_at']),
                  ],
                ),
                trailing: SizedBox(
                  width: 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getScoreColor(scorePercent).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getScoreColor(
                              scorePercent,
                            ).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '${scoreValue.toInt()}/${maxScore.toInt()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(scorePercent),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(scorePercent * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

Widget _buildReadingGradesTab() {
  final primaryColor = _getPrimaryColor();
  final primaryLight = _getPrimaryColor(0.1);

  if (readingGrades.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'No reading grades yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Submit reading recordings to see your grades here',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  return RefreshIndicator(
    onRefresh: _loadAllGrades,
    color: primaryColor,
    backgroundColor: Colors.white,
    child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: readingGrades.length,
      itemBuilder: (context, index) {
        final grade = readingGrades[index];
        final score = (grade['score'] ?? 0.0) as double;
        final maxScore = (grade['max_score'] ?? 10.0) as double;
        final scorePercent = maxScore > 0 ? (score / maxScore) : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            color: Colors.white,
            child: ExpansionTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withOpacity(0.7), primaryColor],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 24),
              ),
              title: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.5,
                ),
                child: Text(
                  grade['title'] ?? 'Reading Task',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blueGrey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              subtitle: _buildDateTimeDisplay(grade['graded_at']),
              trailing: SizedBox(
                width: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Star rating row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (starIndex) {
                        return Icon(
                          starIndex < score.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 16,
                          color: starIndex < score.round()
                              ? Colors.amber[600]
                              : Colors.grey[300],
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    // Numeric score display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(scorePercent)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getScoreColor(scorePercent)
                              .withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${score.toStringAsFixed(1)}/$maxScore',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(scorePercent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (grade['teacher_comments'] != null &&
                          grade['teacher_comments'].toString().isNotEmpty &&
                          !grade['teacher_comments'].toString().startsWith('{'))
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: primaryLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.comment_rounded,
                                      color: primaryColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Teacher Feedback',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                grade['teacher_comments'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blueGrey[700],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.person,
                                color: primaryColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Graded by',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Teacher ${grade['graded_by_name'] ?? 'Unknown'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueGrey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  Color _getScoreColor(double percent) {
    final primaryColor = _getPrimaryColor();

    if (percent >= 0.8) return Colors.green;
    if (percent >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Gradient _getScoreGradient(double percent, Color primaryColor) {
    if (percent >= 0.8) {
      return LinearGradient(colors: [Colors.green[400]!, Colors.green[600]!]);
    }
    if (percent >= 0.6) {
      return LinearGradient(colors: [Colors.orange[400]!, Colors.orange[600]!]);
    }
    return LinearGradient(colors: [Colors.red[400]!, Colors.red[600]!]);
  }

  IconData _getScoreIcon(double percent) {
    if (percent >= 0.8) return Icons.star_rounded;
    if (percent >= 0.6) return Icons.check_circle_rounded;
    return Icons.warning_rounded;
  }

  Widget _buildDateTimeDisplay(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) {
      return Text(
        'Unknown',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      );
    }

    try {
      // Parse the timestamp - no timezone adjustment
      final dt = DateTime.parse(dateTime);

      // Format date and time separately
      final date = DateFormat('MMMM d, y').format(dt);
      final time = DateFormat('h:mma').format(dt);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                time,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      );
    } catch (_) {
      return Text(
        'Invalid date',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      );
    }
  }
}
