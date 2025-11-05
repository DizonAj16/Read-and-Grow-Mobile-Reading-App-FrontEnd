import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyGradesPage extends StatefulWidget {
  const MyGradesPage({super.key});

  @override
  State<MyGradesPage> createState() => _MyGradesPageState();
}

class _MyGradesPageState extends State<MyGradesPage> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  
  bool isLoading = true;
  List<Map<String, dynamic>> quizScores = [];
  List<Map<String, dynamic>> readingGrades = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllGrades();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      ]);
    } catch (e) {
      debugPrint('Error loading grades: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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
      // Fetch graded recordings (both with task_id and without for reading materials)
      final recordingsRes = await supabase
          .from('student_recordings')
          .select('id, task_id, score, teacher_comments, graded_at, recorded_at, tasks(*)')
          .eq('student_id', userId)
          .eq('needs_grading', false)
          .not('score', 'is', null)
          .order('graded_at', ascending: false);

      final List<Map<String, dynamic>> grades = [];

      for (var recording in recordingsRes) {
        final taskId = recording['task_id']?.toString();
        final score = recording['score'];
        final tasksData = recording['tasks'];
        final teacherComments = recording['teacher_comments']?.toString();

        String title;
        String? description;

        if (taskId != null && taskId.isNotEmpty && tasksData != null) {
          // Reading task
          if (tasksData is Map<String, dynamic>) {
            title = tasksData['title']?.toString() ?? 'Reading Task';
            description = tasksData['description']?.toString();
          } else {
            title = 'Reading Task';
          }
        } else {
          // Reading material - try to parse from teacher_comments
          title = 'Reading Material';
          try {
            if (teacherComments != null && teacherComments.startsWith('{')) {
              final materialInfo = jsonDecode(teacherComments);
              title = materialInfo['material_id']?.toString() ?? 'Reading Material';
            }
          } catch (_) {
            // Not JSON, use default
          }
        }

        grades.add({
          'id': recording['id'],
          'title': title,
          'description': description,
          'score': score is num ? score.toDouble() : double.tryParse(score.toString()) ?? 0.0,
          'max_score': 10.0, // Reading recordings are out of 10
          'teacher_comments': teacherComments,
          'graded_at': recording['graded_at'],
          'recorded_at': recording['recorded_at'],
          'type': 'reading',
        });
      }

      if (mounted) {
        setState(() => readingGrades = grades);
      }
    } catch (e) {
      debugPrint('Error loading reading grades: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 My Grades'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.quiz), text: 'Quiz Scores'),
            Tab(icon: Icon(Icons.mic), text: 'Reading Grades'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildQuizScoresTab(),
                _buildReadingGradesTab(),
              ],
            ),
    );
  }

  Widget _buildQuizScoresTab() {
    if (quizScores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No quiz scores yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quizScores.length,
        itemBuilder: (context, index) {
          final score = quizScores[index];
          final scoreValue = ((score['score'] ?? 0) as num).toDouble();
          final maxScore = ((score['max_score'] ?? 0) as num).toDouble();
          final scorePercent = maxScore > 0 ? (scoreValue / maxScore) : 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getScoreColor(scorePercent.toDouble()).withOpacity(0.2),
                child: Icon(
                  _getScoreIcon(scorePercent.toDouble()),
                  color: _getScoreColor(scorePercent.toDouble()),
                ),
              ),
              title: Text(
                score['quiz_title'] ?? 'Untitled Quiz',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (score['task_title'] != null)
                    Text(
                      score['task_title'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(score['submitted_at']),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${scoreValue.toInt()}/${maxScore.toInt()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(scorePercent),
                    ),
                  ),
                  Text(
                    '${(scorePercent * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadingGradesTab() {
    if (readingGrades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No reading grades yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: readingGrades.length,
        itemBuilder: (context, index) {
          final grade = readingGrades[index];
          final score = (grade['score'] ?? 0.0) as double;
          final maxScore = (grade['max_score'] ?? 10.0) as double;
          final scorePercent = maxScore > 0 ? (score / maxScore) : 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: _getScoreColor(scorePercent.toDouble()).withOpacity(0.2),
                child: Icon(
                  Icons.mic,
                  color: _getScoreColor(scorePercent.toDouble()),
                ),
              ),
              title: Text(
                grade['title'] ?? 'Reading Task',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _formatDate(grade['graded_at']),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getScoreColor(scorePercent.toDouble()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${score.toStringAsFixed(1)}/$maxScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              children: [
                if (grade['teacher_comments'] != null && 
                    grade['teacher_comments'].toString().isNotEmpty &&
                    !grade['teacher_comments'].toString().startsWith('{'))
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.comment, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              grade['teacher_comments'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getScoreColor(double percent) {
    if (percent >= 0.8) return Colors.green;
    if (percent >= 0.6) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(double percent) {
    if (percent >= 0.8) return Icons.star;
    if (percent >= 0.6) return Icons.check_circle;
    return Icons.warning;
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

