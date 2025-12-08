import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../api/parent_service.dart';

class ChildDetailPage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const ChildDetailPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<ChildDetailPage> createState() => _ChildDetailPageState();
}

class _ChildDetailPageState extends State<ChildDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Progress data
  String _readingLevel = 'Not Set';
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _pendingTasks = 0;
  int _totalCorrect = 0;
  int _totalWrong = 0;
  double _averageScore = 0;
  List<Map<String, dynamic>> _recentSubmissions = [];

  // Quiz data
  int _totalQuizzes = 0;
  int _completedQuizzes = 0;
  double _quizAverage = 0;
  List<Map<String, dynamic>> _quizSubmissions = [];

  List<Map<String, dynamic>> readingGrades = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final parentService = ParentService();

      final progressData = await parentService.getChildProgress(
        widget.studentId,
      );
      readingGrades = await parentService.getReadingGrades(widget.studentId);

      if (progressData != null) {
        // --- General Progress Data ---
        _readingLevel = progressData['readingLevel'] as String? ?? 'Not Set';
        _completedTasks = progressData['completedTasks'] as int? ?? 0;
        _pendingTasks = progressData['pendingTasks'] as int? ?? 0;
        _totalTasks = _completedTasks + _pendingTasks;
        _totalCorrect = progressData['totalCorrect'] as int? ?? 0;
        _totalWrong = progressData['totalWrong'] as int? ?? 0;
        _averageScore = progressData['averageScore'] as double? ?? 0.0;

        // --- Quiz Statistics ---
        _totalQuizzes = progressData['totalQuizzes'] as int? ?? 0;
        _completedQuizzes = progressData['completedQuizzes'] as int? ?? 0;
        _quizAverage = progressData['quizAverage'] as double? ?? 0.0;

        // --- Quiz Submissions ---
        final List<Map<String, dynamic>> submissions = [];

        for (var e
            in (progressData['quizSubmissions'] as List<dynamic>? ?? [])) {
          final data = Map<String, dynamic>.from(e);

          // Use provided quiz_title or fallback
          String quizTitle = data['quiz_title'] as String? ?? 'Quiz';
          data['quiz_title'] = quizTitle;

          // Parse submitted_at as UTC and convert to PH time (UTC+8)
          if (data['submitted_at'] != null) {
            final submittedAtStr = data['submitted_at'] as String;
            final parsedUtc = DateTime.tryParse(submittedAtStr);
            if (parsedUtc != null) {
              // Convert to PH time (UTC+8)
              final phTime = parsedUtc.add(const Duration(hours: 8));
              data['submitted_at_datetime'] = phTime;
              // Format for display
              data['submitted_at_formatted'] = _formatDateTime(submittedAtStr);
            }
          }

          submissions.add(data);
        }

        // Sort all submissions by local submitted_at descending (latest first)
        submissions.sort((a, b) {
          final aDate =
              a['submitted_at_datetime'] as DateTime? ?? DateTime.now();
          final bDate =
              b['submitted_at_datetime'] as DateTime? ?? DateTime.now();
          return bDate.compareTo(aDate);
        });

        _quizSubmissions = submissions;
        _recentSubmissions = _quizSubmissions.take(5).toList();
        debugPrint(
          'QUIZ SUBMISSIONS JSON:\n${const JsonEncoder.withIndent('  ').convert(_quizSubmissions.map((e) {
            final copy = Map<String, dynamic>.from(e);
            if (copy['submitted_at_datetime'] != null) {
              copy['submitted_at_datetime'] = copy['submitted_at_datetime'].toIso8601String();
            }
            return copy;
          }).toList())}',
        );
      }
      debugPrint(
        'READING GRADES:\n${const JsonEncoder.withIndent('  ').convert(readingGrades)}',
      );
    } catch (e) {
      debugPrint('Error loading data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final background = Theme.of(context).colorScheme.background;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surfaceVariant = Theme.of(context).colorScheme.surfaceVariant;
    final outline = Theme.of(context).colorScheme.outline;
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;
    final onPrimaryContainer = Theme.of(context).colorScheme.onPrimaryContainer;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.studentName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: onPrimary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: onPrimary,
          unselectedLabelColor: onPrimary.withOpacity(0.7),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 13,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.trending_up, size: 20), text: 'Progress'),
            Tab(icon: Icon(Icons.quiz, size: 20), text: 'Quiz Scores'),
            Tab(icon: Icon(Icons.book, size: 20), text: 'Reading Grades'),
            Tab(icon: Icon(Icons.assessment, size: 20), text: 'Reports'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor.withOpacity(0.05), background],
          ),
        ),
        child:
            _isLoading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading Student Data...',
                        style: TextStyle(
                          color: onSurface.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProgressTab(),
                    _buildQuizScoresTab(),
                    _buildReadingGradesTab(),
                    _buildReportsTab(),
                  ],
                ),
      ),
    );
  }

  Widget _buildProgressTab() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;
    final outline = Theme.of(context).colorScheme.outline;
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;
    final secondary = Theme.of(context).colorScheme.secondary;
    final tertiary = Theme.of(context).colorScheme.tertiary;

    final completionPercent =
        _totalTasks > 0 ? (_completedTasks / _totalTasks).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reading Level Card (Most Important)
          _buildGradientCard(
            colors: [
              primaryColor.withOpacity(0.1),
              primaryContainer.withOpacity(0.1),
            ],
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.school, size: 32, color: primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Reading Level',
                          style: TextStyle(
                            fontSize: 14,
                            color: onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _readingLevel,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        if (_readingLevel != 'Not Set') ...[
                          const SizedBox(height: 8),
                          Text(
                            'Based on reading assessments and performance',
                            style: TextStyle(
                              fontSize: 12,
                              color: onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Reading Task Progress
          _buildSectionTitle('Reading Task Progress'),
          const SizedBox(height: 16),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Task Completion',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      Text(
                        '$_completedTasks/$_totalTasks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearPercentIndicator(
                    lineHeight: 8.0,
                    percent: completionPercent,
                    backgroundColor: outline.withOpacity(0.2),
                    progressColor: primaryColor,
                    barRadius: const Radius.circular(4),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(completionPercent * 100).toInt()}% Complete',
                        style: TextStyle(
                          fontSize: 14,
                          color: onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '${_pendingTasks} Pending',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Reading Performance Metrics
          _buildSectionTitle('Reading Performance'),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Accuracy',
                  _totalCorrect + _totalWrong > 0
                      ? '${((_totalCorrect / (_totalCorrect + _totalWrong)) * 100).toInt()}%'
                      : '0%',
                  Icons.flag,
                  Colors.blue.shade600,
                  Colors.blue.shade50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Tasks',
                  '$_totalTasks',
                  Icons.book,
                  primaryColor,
                  primaryColor.withOpacity(0.05),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Correct',
                  '$_totalCorrect',
                  Icons.check_circle,
                  Colors.green.shade600,
                  Colors.green.shade50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Needs Review',
                  '$_totalWrong',
                  Icons.warning,
                  Colors.orange.shade600,
                  Colors.orange.shade50,
                ),
              ),
            ],
          ),

          // Only show quiz section if there are quizzes
          if (_totalQuizzes > 0) ...[
            const SizedBox(height: 32),
            _buildSectionTitle('Quiz Progress'),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tertiary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.quiz, color: tertiary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quiz Completion',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface,
                                ),
                              ),
                              Text(
                                '$_completedQuizzes/$_totalQuizzes completed',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_quizAverage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearPercentIndicator(
                      lineHeight: 6.0,
                      percent: (_completedQuizzes / _totalQuizzes).clamp(
                        0.0,
                        1.0,
                      ),
                      backgroundColor: outline.withOpacity(0.2),
                      progressColor: tertiary,
                      barRadius: const Radius.circular(3),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Recent Progress Summary
          const SizedBox(height: 32),
          _buildSectionTitle('Progress Summary'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outline.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.insights, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Key Insights',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInsightItem(
                  'Reading Level',
                  _readingLevel,
                  _readingLevel != 'Not Set' ? Icons.check_circle : Icons.info,
                  _readingLevel != 'Not Set' ? Colors.green : Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildInsightItem(
                  'Task Completion',
                  '${(completionPercent * 100).toInt()}%',
                  completionPercent >= 0.7
                      ? Icons.trending_up
                      : completionPercent >= 0.3
                      ? Icons.trending_flat
                      : Icons.trending_down,
                  completionPercent >= 0.7
                      ? Colors.green
                      : completionPercent >= 0.3
                      ? Colors.orange
                      : Colors.red,
                ),
                const SizedBox(height: 12),
                if (_totalQuizzes > 0)
                  _buildInsightItem(
                    'Quiz Performance',
                    '${_quizAverage.toStringAsFixed(0)}%',
                    _quizAverage >= 75
                        ? Icons.star
                        : _quizAverage >= 50
                        ? Icons.check_circle
                        : Icons.warning,
                    _quizAverage >= 75
                        ? Colors.green
                        : _quizAverage >= 50
                        ? Colors.orange
                        : Colors.red,
                  ),
              ],
            ),
          ),

          // Empty state if no progress data
          if (_totalTasks == 0 && _totalQuizzes == 0) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.timeline,
                    size: 60,
                    color: outline.withOpacity(0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No progress data yet',
                    style: TextStyle(
                      color: onSurface.withOpacity(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete reading tasks to track progress',
                    style: TextStyle(color: outline, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Add this helper method for insight items
  Widget _buildInsightItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizScoresTab() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final outline = Theme.of(context).colorScheme.outline;
    final surfaceVariant = Theme.of(context).colorScheme.surfaceVariant;
    final surface = Theme.of(context).colorScheme.surface;

    if (_quizSubmissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 80,
              color: outline.withOpacity(0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'No quiz submissions yet',
              style: TextStyle(
                color: onSurface.withOpacity(0.6),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed quizzes will appear here',
              style: TextStyle(color: outline, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: _quizSubmissions.length,
        itemBuilder: (context, index) {
          final submission = _quizSubmissions[index];
          final quizTitle = submission['quiz_title'] ?? 'Quiz';
          final score = (submission['score'] ?? 0).toDouble();
          final maxScore = (submission['max_score'] ?? 0).toDouble();
          final scorePercent = maxScore > 0 ? (score / maxScore) : 0;

          // Use already parsed DateTime if available
          DateTime? submittedAt =
              submission['submitted_at_datetime'] as DateTime?;
          // Fallback to parse the string if DateTime not set
          submittedAt ??=
              DateTime.tryParse(submission['submitted_at'] ?? '')?.toLocal();

          Color scoreColor;
          IconData scoreIcon;
          if (scorePercent >= 0.8) {
            scoreColor = Colors.green.shade600;
            scoreIcon = Icons.star;
          } else if (scorePercent >= 0.6) {
            scoreColor = Colors.orange.shade600;
            scoreIcon = Icons.check_circle;
          } else {
            scoreColor = Colors.red.shade600;
            scoreIcon = Icons.warning;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                childrenPadding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(scoreIcon, color: scoreColor, size: 22),
                ),
                title: Text(
                  quizTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: onSurface,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    LinearPercentIndicator(
                      lineHeight: 6.0,
                      percent: scorePercent.clamp(0.0, 1.0),
                      backgroundColor: outline.withOpacity(0.2),
                      progressColor: scoreColor,
                      barRadius: const Radius.circular(3),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(scorePercent * 100).toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, color: outline),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${score.toInt()}/${maxScore.toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: scoreColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.expand_more, color: outline),
                  ],
                ),
                children: [
                  if (submittedAt != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: outline),
                          const SizedBox(width: 8),
                          Text(
                            "Submitted: ${_formatDateTime(submission['submitted_at'] as String?)}",
                            style: TextStyle(
                              color: outline,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
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

  Widget _buildReportsTab() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;
    final outline = Theme.of(context).colorScheme.outline;
    final secondary = Theme.of(context).colorScheme.secondary;
    final tertiary = Theme.of(context).colorScheme.tertiary;
    final surfaceVariant = Theme.of(context).colorScheme.surfaceVariant;

    // Calculate reading performance
    double readingAverageScore = 0;
    int totalReadingGrades = readingGrades.length;

    if (totalReadingGrades > 0) {
      double totalScore = 0;
      for (var grade in readingGrades) {
        final score = (grade['score'] ?? 0).toDouble();
        totalScore += score;
      }
      readingAverageScore = totalScore / totalReadingGrades;
    }

    // Calculate reading performance rating
    String readingGradeText;
    Color readingGradeColor;
    if (readingAverageScore >= 4) {
      readingGradeText = 'Excellent';
      readingGradeColor = Colors.green.shade600;
    } else if (readingAverageScore >= 3) {
      readingGradeText = 'Good';
      readingGradeColor = Colors.orange.shade600;
    } else if (readingAverageScore >= 2) {
      readingGradeText = 'Fair';
      readingGradeColor = Colors.orange.shade400;
    } else {
      readingGradeText = 'Needs Improvement';
      readingGradeColor = Colors.red.shade600;
    }

    // Calculate quiz performance rating
    String quizGradeText;
    Color quizGradeColor;
    if (_quizAverage >= 90) {
      quizGradeText = 'Excellent';
      quizGradeColor = Colors.green.shade600;
    } else if (_quizAverage >= 75) {
      quizGradeText = 'Good';
      quizGradeColor = secondary;
    } else if (_quizAverage >= 60) {
      quizGradeText = 'Fair';
      quizGradeColor = Colors.orange.shade600;
    } else {
      quizGradeText = 'Needs Improvement';
      quizGradeColor = Colors.red.shade600;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reading Performance Card
          _buildGradientCard(
            colors: [
              readingGradeColor.withOpacity(0.2),
              readingGradeColor.withOpacity(0.05),
            ],
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book, size: 24, color: readingGradeColor),
                      const SizedBox(width: 8),
                      Text(
                        'Reading Performance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    readingAverageScore > 0
                        ? readingAverageScore.toStringAsFixed(1)
                        : 'N/A',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: readingGradeColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'out of 5',
                    style: TextStyle(
                      fontSize: 16,
                      color: onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: readingGradeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      readingAverageScore > 0
                          ? readingGradeText
                          : 'No Grades Yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: readingGradeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on $totalReadingGrades reading assessments',
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quiz Performance Card
          _buildGradientCard(
            colors: [
              quizGradeColor.withOpacity(0.2),
              quizGradeColor.withOpacity(0.05),
            ],
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.quiz, size: 24, color: quizGradeColor),
                      const SizedBox(width: 8),
                      Text(
                        'Quiz Performance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _quizAverage > 0
                        ? '${_quizAverage.toStringAsFixed(1)}%'
                        : 'N/A',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: quizGradeColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: quizGradeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _quizAverage > 0 ? quizGradeText : 'No Quizzes Yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: quizGradeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on $_completedQuizzes/$_totalQuizzes completed quizzes',
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Overall Performance Summary
          _buildSectionTitle('Overall Performance Summary'),
          const SizedBox(height: 16),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Reading Performance Stats
              if (totalReadingGrades > 0) ...[
                _reportStatCard(
                  'Reading Assessments',
                  '$totalReadingGrades',
                  Icons.book,
                  primaryColor,
                ),
                _reportStatCard(
                  'Avg. Reading Score',
                  '${readingAverageScore.toStringAsFixed(1)}/5',
                  Icons.star,
                  primaryColor.withOpacity(0.8),
                ),
              ] else ...[
                _reportStatCard(
                  'Reading Assessments',
                  '0',
                  Icons.book,
                  outline,
                ),
              ],

              // Quiz Performance Stats
              if (_totalQuizzes > 0) ...[
                _reportStatCard(
                  'Total Quizzes',
                  '$_totalQuizzes',
                  Icons.quiz,
                  tertiary,
                ),
                _reportStatCard(
                  'Completed Quizzes',
                  '$_completedQuizzes',
                  Icons.assignment_turned_in,
                  tertiary.withOpacity(0.8),
                ),
                _reportStatCard(
                  'Quiz Average',
                  '${_quizAverage.toStringAsFixed(1)}%',
                  Icons.star,
                  secondary,
                ),
              ] else ...[
                _reportStatCard('Total Quizzes', '0', Icons.quiz, outline),
              ],

              // General Stats
              _reportStatCard(
                'Correct Answers',
                '$_totalCorrect',
                Icons.check_circle,
                Colors.green.shade600,
              ),
              _reportStatCard(
                'Wrong Answers',
                '$_totalWrong',
                Icons.cancel,
                Colors.red.shade600,
              ),
              _reportStatCard(
                'Accuracy Rate',
                _totalCorrect + _totalWrong > 0
                    ? '${((_totalCorrect / (_totalCorrect + _totalWrong)) * 100).toStringAsFixed(1)}%'
                    : '0%',
                Icons.trending_up,
                primaryColor,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Recent Reading Assessments - with empty state message
          if (readingGrades.isNotEmpty) ...[
            _buildSectionTitle('Recent Reading Assessments'),
            const SizedBox(height: 16),
            ...readingGrades
                .take(3)
                .map(
                  (grade) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.book,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          grade['title'] ?? 'Reading Assessment',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: onSurface,
                          ),
                        ),
                        subtitle:
                            grade['graded_at'] != null
                                ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _formatDateTime(
                                      grade['graded_at'] as String,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: outline,
                                    ),
                                  ),
                                )
                                : null,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getReadingScoreColor(
                              (grade['score'] ?? 0).toDouble(),
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(grade['score'] ?? 0).toDouble()}/5',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _getReadingScoreColor(
                                (grade['score'] ?? 0).toDouble(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          ] else ...[
            // Show empty message for reading assessments
            _buildSectionTitle('Recent Reading Assessments'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 60,
                    color: outline.withOpacity(0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No reading assessments yet',
                    style: TextStyle(
                      color: onSurface.withOpacity(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Graded reading tasks will appear here',
                    style: TextStyle(color: outline, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Recent Quiz Activity
          // Recent Quiz Activity - with empty state message
          if (_recentSubmissions.isNotEmpty) ...[
            _buildSectionTitle('Recent Quiz Activity'),
            const SizedBox(height: 16),
            ..._recentSubmissions
                .take(3)
                .map(
                  (submission) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: tertiary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.quiz, color: tertiary, size: 20),
                        ),
                        title: Text(
                          submission['quiz_title'] ?? 'Quiz Submission',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: onSurface,
                          ),
                        ),
                        subtitle:
                            submission['submitted_at'] != null
                                ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _formatDateTime(
                                      submission['submitted_at'] as String,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: outline,
                                    ),
                                  ),
                                )
                                : null,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getScoreColor(
                              (submission['score'] ?? 0) /
                                  (submission['max_score'] ?? 1),
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${((submission['score'] ?? 0) / (submission['max_score'] ?? 1) * 100).toInt()}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _getScoreColor(
                                (submission['score'] ?? 0) /
                                    (submission['max_score'] ?? 1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          ] else if (_quizSubmissions.isEmpty) ...[
            // Show empty message for quiz activities
            _buildSectionTitle('Recent Quiz Activity'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 60,
                    color: outline.withOpacity(0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No quiz activities yet',
                    style: TextStyle(
                      color: onSurface.withOpacity(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Completed quizzes will appear here',
                    style: TextStyle(color: outline, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          // Empty state messages
          if (readingGrades.isEmpty && _quizSubmissions.isEmpty) ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.assessment,
                    size: 80,
                    color: outline.withOpacity(0.4),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No performance data yet',
                    style: TextStyle(
                      color: onSurface.withOpacity(0.6),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete reading tasks and quizzes to see performance reports',
                    style: TextStyle(color: outline, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Add this helper method for reading score colors (0-5 scale)
  Color _getReadingScoreColor(double score) {
    if (score >= 4) return Colors.green.shade600;
    if (score >= 3) return Colors.orange.shade600;
    if (score >= 2) return Colors.orange.shade400;
    return Colors.red.shade600;
  }

  Widget _buildReadingGradesTab() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final outline = Theme.of(context).colorScheme.outline;
    final surfaceVariant = Theme.of(context).colorScheme.surfaceVariant;
    final surface = Theme.of(context).colorScheme.surface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (readingGrades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: outline.withOpacity(0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'No reading grades yet',
              style: TextStyle(
                color: onSurface.withOpacity(0.6),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reading task grades will appear here',
              style: TextStyle(color: outline, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: readingGrades.length,
        itemBuilder: (context, index) {
          final grade = readingGrades[index];

          final title = grade['title'] ?? 'Reading Task';
          final description = grade['description'] ?? '';

          final score = (grade['score'] ?? 0).toDouble();
          final maxScore = 5.0; // CHANGED: Always use 5 as max score
          final percent = maxScore > 0 ? (score / maxScore) : 0;

          final gradedBy = grade['graded_by_name'] ?? 'Teacher';
          final gradedAtStr = grade['graded_at'];
          DateTime? gradedAt =
              gradedAtStr != null
                  ? DateTime.tryParse(gradedAtStr)?.toLocal()
                  : null;

          final teacherComments = grade['teacher_comments'] ?? '';

          // Calculate star rating (0-5 stars)
          final starRating = score;
          final fullStars = starRating.floor();
          final hasHalfStar = (starRating - fullStars) >= 0.5;

          // Determine color based on 5-point scale
          Color color;
          IconData icon;
          if (score >= 4) {
            color = Colors.green.shade600; // 4-5: Excellent
            icon = Icons.star;
          } else if (score >= 3) {
            color = Colors.orange.shade600; // 3-3.9: Good
            icon = Icons.check_circle;
          } else if (score >= 2) {
            color = Colors.orange.shade400; // 2-2.9: Fair
            icon = Icons.info;
          } else {
            color = Colors.red.shade600; // 0-1.9: Needs Improvement
            icon = Icons.warning;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: StatefulBuilder(
                builder: (context, setTileState) {
                  bool isExpanded = false;

                  return ExpansionTile(
                    onExpansionChanged: (expanded) {
                      setTileState(() => isExpanded = expanded);
                    },
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    childrenPadding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),

                    // Leading icon
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),

                    // COLLAPSED TITLE AREA
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Star rating display
                            if (gradedBy != 'N/A')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    // Show star rating
                                    ...List.generate(5, (starIndex) {
                                      if (starIndex < fullStars) {
                                        return Icon(
                                          Icons.star,
                                          size: 16,
                                          color: color,
                                        );
                                      } else if (starIndex == fullStars &&
                                          hasHalfStar) {
                                        return Icon(
                                          Icons.star_half,
                                          size: 16,
                                          color: color,
                                        );
                                      } else {
                                        return Icon(
                                          Icons.star_border,
                                          size: 16,
                                          color: outline.withOpacity(0.4),
                                        );
                                      }
                                    }),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${score.toStringAsFixed(1)}/5',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: outline.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Not Yet Graded',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: outline,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Only show progress indicator if graded (not "N/A")
                        if (gradedBy != 'N/A')
                          LinearPercentIndicator(
                            lineHeight: 6.0,
                            percent: percent.clamp(0.0, 1.0),
                            backgroundColor: outline.withOpacity(0.2),
                            progressColor: color,
                            barRadius: const Radius.circular(3),
                            padding: EdgeInsets.zero,
                          )
                        else
                          const SizedBox(height: 6),
                      ],
                    ),

                    // Arrow Up / Down
                    trailing: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 24,
                      color: outline,
                    ),

                    // EXPANDED CONTENT
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Score breakdown with stars
                            if (gradedBy != 'N/A')
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: color.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Reading Assessment Score',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: outline,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${score.toStringAsFixed(1)} out of 5',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Row(
                                          children: List.generate(5, (
                                            starIndex,
                                          ) {
                                            if (starIndex < fullStars) {
                                              return Icon(
                                                Icons.star,
                                                size: 20,
                                                color: color,
                                              );
                                            } else if (starIndex == fullStars &&
                                                hasHalfStar) {
                                              return Icon(
                                                Icons.star_half,
                                                size: 20,
                                                color: color,
                                              );
                                            } else {
                                              return Icon(
                                                Icons.star_border,
                                                size: 20,
                                                color: outline.withOpacity(0.3),
                                              );
                                            }
                                          }),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(percent * 100).toInt()}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: outline,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                            if (description.isNotEmpty) ...[
                              Text(
                                'Description:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: outline,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(fontSize: 13, color: outline),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                Icon(Icons.person, size: 16, color: outline),
                                const SizedBox(width: 8),
                                Text(
                                  "Graded by: $gradedBy",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: outline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (teacherComments.isNotEmpty) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.comment, size: 16, color: outline),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Comments: $teacherComments',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: outline,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (gradedAt != null && gradedBy != 'N/A') ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: outline,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Graded at: ${_formatDateTime(gradedAtStr)}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: outline,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper Methods for Enhanced Styling
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildGradientCard({
    required List<Color> colors,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color backgroundColor,
  ) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;

    return SizedBox(
      width: 160,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double scorePercent) {
    if (scorePercent >= 0.8) return Colors.green.shade600;
    if (scorePercent >= 0.6) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  Widget _buildReportItem(String label, String value) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: onSurface)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return 'Unknown';

    try {
      // Parse the timestamp from database (usually UTC)
      final dt = DateTime.parse(dateTime);

      // Convert to Philippine Time (UTC+8)
      final phTime = dt.add(const Duration(hours: 8));

      // Format using intl for PH time
      final formatted = DateFormat('MMMM d, y h:mm a').format(phTime);

      return formatted; // e.g., "November 28, 2025 6:45 PM"
    } catch (_) {
      return 'Invalid date';
    }
  }
}
