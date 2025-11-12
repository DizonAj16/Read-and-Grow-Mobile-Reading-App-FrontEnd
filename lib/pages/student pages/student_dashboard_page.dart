import 'package:deped_reading_app_laravel/api/supabase_auth_service.dart';
import 'package:deped_reading_app_laravel/models/student_model.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'student page widgets/horizontal_card.dart';
import 'student page widgets/activity_tile.dart';
import 'enhanced_reading_level_page.dart';
import 'student_badges_page.dart';
import 'my_grades_page.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  String? username;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();
  bool _isLoading = false;
  bool _minimumLoadingTimeElapsed = false;
  bool _dataLoaded = false;

  // Progress data
  double _averageScore = 0;
  int _completedTasks = 0;
  int _pendingTasks = 0;
  int _totalCorrect = 0;
  int _totalWrong = 0;
  DateTime? _lastUpdated;
  List<double> _recentScores = [];
  int _assignedTasks = 0;
  int _badgesCount = 0;
  String _levelDisplay = 'N/A';

  @override
  void initState() {
    super.initState();
    _loadData();
    _startMinimumLoadingTimer();
  }

  void _startMinimumLoadingTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _minimumLoadingTimeElapsed = true;
          _updateLoadingState();
        });
      }
    });
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final response = await SupabaseAuthService.getAuthProfile();
      final profileJson = (response?['profile'] ?? {}) as Map<String, dynamic>;
      final student = Student.fromJson(profileJson);
      await student.saveToPrefs();

      if (mounted && student.username != null && student.username!.isNotEmpty) {
        setState(() => username = student.username);
      }

      await _loadProgressData();
      await _loadAssignedBadgesAndLevel();
    } catch (e) {
      debugPrint('API fetch failed: $e');
      final fallbackStudent = await Student.fromPrefs();
      if (mounted) {
        setState(() => username = fallbackStudent.username ?? '');
      }
      await _loadAssignedBadgesAndLevel();
    } finally {
      if (mounted) {
        setState(() {
          _dataLoaded = true;
          _updateLoadingState();
        });
      }
    }
  }

  Future<void> _loadProgressData() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get student.id from students table
      final studentRow = await supabase
          .from('students')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (studentRow == null) return;
      final String studentId = studentRow['id'] as String;

      // Get all classes the student is enrolled in
      final enrollments = await supabase
          .from('student_enrollments')
          .select('class_room_id')
          .eq('student_id', studentId);

      final classIds = (enrollments as List)
          .map((e) => e['class_room_id'] as String)
          .toList();

      // Get all assignments for these classes
      List<String> assignedTaskIds = [];
      List<String> assignedQuizIds = [];
      if (classIds.isNotEmpty) {
        final assignments = await supabase
            .from('assignments')
            .select('task_id, quiz_id, tasks(id, quizzes(id))')
            .inFilter('class_room_id', classIds);
        
        // Also get quizzes directly linked via quiz_id in assignments
        final directQuizAssignments = await supabase
            .from('assignments')
            .select('quiz_id')
            .inFilter('class_room_id', classIds)
            .not('quiz_id', 'is', null);

        for (var assignment in assignments) {
          // Handle task_id assignments
          final taskId = assignment['task_id'] as String?;
          if (taskId != null) {
            assignedTaskIds.add(taskId);
            
            // Get quizzes linked to this task
            final task = assignment['tasks'] as Map<String, dynamic>?;
            if (task != null) {
              final quizzes = task['quizzes'] as List?;
              if (quizzes != null) {
                for (var quiz in quizzes) {
                  final quizId = quiz['id'] as String?;
                  if (quizId != null && !assignedQuizIds.contains(quizId)) {
                    assignedQuizIds.add(quizId);
                  }
                }
              }
            }
          }
          
          // Handle quiz_id assignments (quizzes directly linked to assignment)
          final directQuizId = assignment['quiz_id'] as String?;
          if (directQuizId != null && !assignedQuizIds.contains(directQuizId)) {
            assignedQuizIds.add(directQuizId);
          }
        }
        
        // Add quizzes from direct quiz_id assignments
        for (var assignment in directQuizAssignments) {
          final quizId = assignment['quiz_id'] as String?;
          if (quizId != null && !assignedQuizIds.contains(quizId)) {
            assignedQuizIds.add(quizId);
          }
        }
      }

      // Get existing progress records
      final response = await supabase
          .from('student_task_progress')
          .select('task_id, score, max_score, correct_answers, wrong_answers, completed, updated_at')
          .eq('student_id', userId)
          .order('updated_at', ascending: false);

      // Handle case where there's no progress data yet
      if (response.isEmpty && assignedTaskIds.isEmpty && assignedQuizIds.isEmpty) {
        setState(() {
          _averageScore = 0;
          _completedTasks = 0;
          _pendingTasks = 0;
          _totalCorrect = 0;
          _totalWrong = 0;
          _lastUpdated = null;
          _recentScores = [];
        });
        return;
      }

      // Get quiz submissions to check which quizzes are completed
      final quizSubmissions = await supabase
          .from('student_submissions')
          .select('assignment_id, assignments(id, task_id, tasks(id, quizzes(id)))')
          .eq('student_id', userId);

      Set<String> completedQuizIds = {};
      for (var submission in quizSubmissions) {
        final assignment = submission['assignments'] as Map<String, dynamic>?;
        if (assignment != null) {
          final task = assignment['tasks'] as Map<String, dynamic>?;
          if (task != null) {
            final quizzes = task['quizzes'] as List?;
            if (quizzes != null) {
              for (var quiz in quizzes) {
                final quizId = quiz['id'] as String?;
                if (quizId != null) {
                  completedQuizIds.add(quizId);
                }
              }
            }
          }
        }
      }

      double totalScore = 0;
      double totalMax = 0;
      int correct = 0;
      int wrong = 0;
      DateTime? latest;

      List<double> scores = [];
      Set<String> completedTaskIds = {};
      Set<String> pendingTaskIds = {};

      // Process existing progress records
      for (var row in response) {
        final taskId = row['task_id'] as String?;
        if (taskId == null) continue;

        double score = (row['score'] ?? 0).toDouble();
        double maxScore = (row['max_score'] ?? 0).toDouble();

        totalScore += score;
        totalMax += maxScore;
        correct += (row['correct_answers'] ?? 0) as int;
        wrong += (row['wrong_answers'] ?? 0) as int;

        final updated = DateTime.tryParse(row['updated_at'] ?? '');
        if (updated != null) {
          if (latest == null || updated.isAfter(latest)) latest = updated;
        }

        // collect last 5 normalized scores
        if (maxScore > 0) scores.add(score / maxScore);

        // Track completed vs pending tasks
        if (row['completed'] == false || row['completed'] == null) {
          completedTaskIds.add(taskId);
        } else {
          pendingTaskIds.add(taskId);
        }
      }

      // Count newly assigned tasks/quizzes that haven't been started yet
      int newPendingTasks = 0;
      for (var taskId in assignedTaskIds) {
        if (!completedTaskIds.contains(taskId) && !pendingTaskIds.contains(taskId)) {
          newPendingTasks++;
        }
      }

      // Count newly assigned quizzes that haven't been taken yet
      int newPendingQuizzes = 0;
      for (var quizId in assignedQuizIds) {
        if (!completedQuizIds.contains(quizId)) {
          newPendingQuizzes++;
        }
      }

      // Total pending = existing pending + newly assigned tasks + newly assigned quizzes
      int totalPendingCount = pendingTaskIds.length + newPendingTasks + newPendingQuizzes;
      int totalCompletedCount = completedTaskIds.length + completedQuizIds.length;

      scores = scores.take(5).toList().reversed.toList();

      setState(() {
        _averageScore = totalMax > 0 ? totalScore / totalMax : 0;
        _completedTasks = totalCompletedCount;
        _pendingTasks = totalPendingCount;
        _totalCorrect = correct;
        _totalWrong = wrong;
        _lastUpdated = latest;
        _recentScores = scores;
      });
    } catch (e) {
      debugPrint('⚠️ Failed to load progress: $e');
    }
  }

  Future<void> _loadAssignedBadgesAndLevel() async {
    try {
      final supabase = Supabase.instance.client;
      final authUserId = supabase.auth.currentUser?.id;
      if (authUserId == null) return;

      // Get student.id from students by user_id
      final studentRow = await supabase
          .from('students')
          .select('id, current_reading_level_id')
          .eq('id', authUserId)
          .maybeSingle();

      if (studentRow == null) return;
      final String studentId = studentRow['id'] as String;

      // Fetch enrolled class ids
      final enrollments = await supabase
          .from('student_enrollments')
          .select('class_room_id')
          .eq('student_id', studentId);

      final classIds = (enrollments as List)
          .map((e) => e['class_room_id'] as String)
          .toList();

      int assignedCount = 0;
      if (classIds.isNotEmpty) {
        final assignments = await supabase
            .from('assignments')
            .select('id')
            .inFilter('class_room_id', classIds);
        assignedCount = (assignments as List).length;
      }

      // Badges: count submissions with score ratio >= 0.8
      final submissions = await supabase
          .from('student_submissions')
          .select('score, max_score')
          .eq('student_id', authUserId);

      int badges = 0;
      for (final row in (submissions as List)) {
        final int score = (row['score'] ?? 0) as int;
        final int maxScore = (row['max_score'] ?? 0) as int;
        if (maxScore > 0 && score / maxScore >= 0.8) {
          badges += 1;
        }
      }

      // Level display
      String levelText = 'N/A';
      final levelId = studentRow['current_reading_level_id'] as String?;
      if (levelId != null) {
        final levelRow = await supabase
            .from('reading_levels')
            .select('level_number, title')
            .eq('id', levelId)
            .maybeSingle();
        if (levelRow != null) {
          final num = levelRow['level_number'];
          final title = levelRow['title'];
          levelText = (num != null ? 'Level $num' : '') + (title != null ? ' - $title' : '');
          levelText = levelText.isEmpty ? 'N/A' : levelText;
        }
      }

      if (mounted) {
        setState(() {
          _assignedTasks = assignedCount;
          _badgesCount = badges;
          _levelDisplay = levelText;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load assigned/badges/level: $e');
    }
  }

  void _updateLoadingState() {
    if (_dataLoaded && _minimumLoadingTimeElapsed) {
      _isLoading = false;
    }
  }

  Future<void> _handleRefresh() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _minimumLoadingTimeElapsed = false;
        _dataLoaded = false;
      });
    }

    _startMinimumLoadingTimer();
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final showLoading = _isLoading || !_minimumLoadingTimeElapsed;

    return Scaffold(
      backgroundColor: const Color(0xFFFCEEEE),
      body: SafeArea(
        child: showLoading
            ? Center(
          child: Lottie.asset(
            'assets/animation/loading_rainbow.json',
            width: 90,
            height: 90,
          ),
        )
            : RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: Colors.purple,
          backgroundColor: Colors.white,
          strokeWidth: 3.0,
          displacement: 40.0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: _buildWelcomeSection(context)),
                        const SizedBox(height: 20),
                        _buildStatisticsCards(),
                        const SizedBox(height: 30),
                        _buildProgressSection(),
                        const SizedBox(height: 30),
                        _buildQuickAccessSection(context),
                        const SizedBox(height: 20),
                        _buildMyGradesCard(context),
                        const SizedBox(height: 30),
                        _buildRecentActivitiesSection(context),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Lottie.asset(
              'assets/animation/waving_hello.json',
              height: 150,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Hi ${username ?? ''}! 👋",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Ready to learn and have fun today?",
            style: TextStyle(fontSize: 16, color: Colors.purple.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return SizedBox(
      height: 170,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          StudentDashboardHorizontalCard(
            title: "Completed",
            value: _completedTasks.toString(),
            gradientColors: [Colors.lightGreen, Colors.green],
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(width: 16),
          StudentDashboardHorizontalCard(
            title: "Pending",
            value: _pendingTasks.toString(),
            gradientColors: [Colors.orangeAccent, Colors.deepOrange],
            icon: Icons.pending_actions,
          ),
          const SizedBox(width: 16),
          StudentDashboardHorizontalCard(
            title: "Badges",
            value: _badgesCount.toString(),
            gradientColors: [Colors.pinkAccent, Colors.redAccent],
            icon: Icons.emoji_events_outlined,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StudentBadgesPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          StudentDashboardHorizontalCard(
            title: "Level",
            value: _levelDisplay,
            gradientColors: [Colors.blueAccent, Colors.lightBlue],
            icon: Icons.star_border,
          ),
        ],
      ),
    );
  }

  // ✅ PROGRESS SECTION
  Widget _buildProgressSection() {
    final percent = _averageScore.clamp(0, 1);

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
              offset: const Offset(0, 3)),
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
               percent: percent.toDouble(),
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
              Expanded(child: _buildTrendChart()),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _progressStat(Icons.check_circle, "Completed",
                  _completedTasks.toString(), Colors.green),
              _progressStat(Icons.check, "Correct", _totalCorrect.toString(),
                  Colors.blue),
              _progressStat(
                  Icons.close, "Wrong", _totalWrong.toString(), Colors.redAccent),
            ],
          ),
          const SizedBox(height: 10),
          if (_lastUpdated != null)
            Text(
              "Last updated: ${_lastUpdated!.toLocal().toString().split('.')[0]}",
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
        ],
      ),
    );
  }

  Widget _progressStat(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  // 📈 TREND CHART
  Widget _buildTrendChart() {
    if (_recentScores.isEmpty) {
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
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              spots: _recentScores
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              color: Colors.purpleAccent,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.purpleAccent.withOpacity(0.2),
              ),
            ),
          ],
          minY: 0,
          maxY: 1,
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to reading levels page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EnhancedReadingLevelPage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.purple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.book,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📚 My Reading Tasks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Continue your reading journey',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyGradesCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyGradesPage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade400, Colors.orange.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.grade,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 My Grades',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View quiz scores & reading grades',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesSection(BuildContext context) {
    final List activities = [];

    if (activities.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.hourglass_empty_rounded,
                  size: 48,
                  color: Colors.amber.shade600,
                ),
                const SizedBox(height: 12),
                Text(
                  "No recent activities yet!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your activities will appear here once you start learning.",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "📚 Recent Activities",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: activities.map((activity) {
            return StudentDashboardActivityTile(
              title: activity.title,
              subtitle: activity.subtitle,
              icon: activity.icon,
            );
          }).toList(),
        ),
      ],
    );
  }
}
