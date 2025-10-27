import 'package:flutter/material.dart';
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
  int _totalCorrect = 0;
  int _totalWrong = 0;
  double _averageScore = 0;
  List<Map<String, dynamic>> _recentSubmissions = [];

  // Quiz data
  List<Map<String, dynamic>> _quizSubmissions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final progressData = await parentService.getChildProgress(widget.studentId);

      if (progressData != null) {
        _readingLevel = progressData['readingLevel'] as String;
        _totalTasks = progressData['totalTasks'] as int;
        _completedTasks = progressData['completedTasks'] as int;
        _totalCorrect = progressData['totalCorrect'] as int;
        _totalWrong = progressData['totalWrong'] as int;
        _averageScore = progressData['averageScore'] as double;
        
        final submissions = progressData['quizSubmissions'] as List<Map<String, dynamic>>;
        _quizSubmissions = submissions;
        _recentSubmissions = _quizSubmissions.take(5).toList();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.trending_up), text: 'Progress'),
            Tab(icon: Icon(Icons.quiz), text: 'Quiz Scores'),
            Tab(icon: Icon(Icons.assessment), text: 'Reports'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProgressTab(),
                _buildQuizScoresTab(),
                _buildReportsTab(),
              ],
            ),
    );
  }

  Widget _buildProgressTab() {
    final completionPercent = _totalTasks > 0
        ? (_completedTasks / _totalTasks).clamp(0.0, 1.0)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reading Level Card
          Card(
            color: Colors.indigo.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.school, size: 40, color: Colors.indigo.shade700),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Reading Level',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _readingLevel,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Progress Overview
          Text(
            'Progress Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Tasks Completed',
                  '$_completedTasks / $_totalTasks',
                  Icons.task_alt,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Average Score',
                  '${_averageScore.toStringAsFixed(1)}%',
                  Icons.star,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Correct Answers',
                  '$_totalCorrect',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Wrong Answers',
                  '$_totalWrong',
                  Icons.cancel,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Completion Progress
          Text(
            'Task Completion',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          CircularPercentIndicator(
            radius: 100.0,
            lineWidth: 12.0,
            percent: completionPercent,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(completionPercent * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Complete',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            progressColor: Colors.indigo,
            backgroundColor: Colors.grey[200]!,
            circularStrokeCap: CircularStrokeCap.round,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizScoresTab() {
    if (_quizSubmissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No quiz submissions yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quizSubmissions.length,
      itemBuilder: (context, index) {
        final submission = _quizSubmissions[index];
        final score = (submission['score'] ?? 0).toDouble();
        final maxScore = (submission['max_score'] ?? 0).toDouble();
        final date = submission['submitted_at'] as String?;
        final scorePercent = maxScore > 0 ? (score / maxScore) : 0;

        Color scoreColor;
        if (scorePercent >= 0.8) {
          scoreColor = Colors.green;
        } else if (scorePercent >= 0.6) {
          scoreColor = Colors.orange;
        } else {
          scoreColor = Colors.red;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: scoreColor.withOpacity(0.2),
              child: Icon(
                scorePercent >= 0.8
                    ? Icons.star
                    : scorePercent >= 0.6
                        ? Icons.check_circle
                        : Icons.warning,
                color: scoreColor,
              ),
            ),
            title: Text(
              'Quiz #${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (date != null)
                  Text(
                    DateTime.parse(date).toLocal().toString().split(' ')[0],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                const SizedBox(height: 4),
                LinearPercentIndicator(
                  lineHeight: 6.0,
                  percent: scorePercent.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200]!,
                  progressColor: scoreColor,
                  barRadius: const Radius.circular(3),
                ),
              ],
            ),
            trailing: Text(
              '${score.toInt()}/${maxScore.toInt()}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    final recentSubmissions = _recentSubmissions;
    final overallGrade = _averageScore;

    String gradeText;
    Color gradeColor;
    if (overallGrade >= 90) {
      gradeText = 'Excellent';
      gradeColor = Colors.green;
    } else if (overallGrade >= 75) {
      gradeText = 'Good';
      gradeColor = Colors.blue;
    } else if (overallGrade >= 60) {
      gradeText = 'Fair';
      gradeColor = Colors.orange;
    } else {
      gradeText = 'Needs Improvement';
      gradeColor = Colors.red;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Grade Card
          Card(
            color: gradeColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Overall Performance',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    overallGrade.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: gradeColor,
                    ),
                  ),
                  Text(
                    gradeText,
                    style: TextStyle(
                      fontSize: 20,
                      color: gradeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Performance Summary
          Text(
            'Performance Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),

          _buildReportItem('Total Tasks', '$_totalTasks'),
          _buildReportItem('Completed Tasks', '$_completedTasks'),
          _buildReportItem('Completion Rate', '${(_totalTasks > 0 ? (_completedTasks / _totalTasks * 100) : 0).toStringAsFixed(1)}%'),
          _buildReportItem('Average Score', '${_averageScore.toStringAsFixed(1)}%'),
          _buildReportItem('Correct Answers', '$_totalCorrect'),
          _buildReportItem('Wrong Answers', '$_totalWrong'),
          _buildReportItem('Accuracy Rate', _totalCorrect + _totalWrong > 0
              ? '${((_totalCorrect / (_totalCorrect + _totalWrong)) * 100).toStringAsFixed(1)}%'
              : '0%'),

          const SizedBox(height: 24),

          // Recent Activity
          if (recentSubmissions.isNotEmpty) ...[
            Text(
              'Recent Quiz Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...recentSubmissions.map(
              (submission) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.quiz),
                  title: Text(
                    'Quiz Submission',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: submission['submitted_at'] != null
                      ? Text(
                          DateTime.parse(submission['submitted_at'] as String)
                              .toLocal()
                              .toString()
                              .split('.')[0],
                        )
                      : null,
                  trailing: Text(
                    '${((submission['score'] ?? 0) / (submission['max_score'] ?? 1)).toDouble().toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
