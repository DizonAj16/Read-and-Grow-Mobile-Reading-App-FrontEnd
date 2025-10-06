import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';
import 'model.dart';
class ChildDetailPage extends StatelessWidget {
  final StudentProgress progress;

  const ChildDetailPage({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(progress.studentName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: progress.quizSubmissions.isEmpty
            ? const Center(child: Text('No quiz submissions yet.'))
            : ListView.builder(
          itemCount: progress.quizSubmissions.length,
          itemBuilder: (context, index) {
            final sub = progress.quizSubmissions[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(sub.quizTitle),
                subtitle: Text(
                    'Score: ${sub.score.toStringAsFixed(1)} | Submitted: ${sub.submittedAt.toLocal().toString().split(' ')[0]}'),
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<List<StudentProgress>> getParentChildrenProgress(String parentId) async {
  final supabase = Supabase.instance.client;

  final studentsResponse = await supabase
      .from('students')
      .select('id, student_name, current_reading_level_id')
      .eq('parent_id', parentId);

  final List<StudentProgress> progressList = [];

  for (final s in studentsResponse) {
    final studentId = s['id'];
    final studentName = s['student_name'];

    // Fetch reading level
    final levelResp = await supabase
        .from('reading_levels')
        .select('level_number, title')
        .eq('id', s['current_reading_level_id'])
        .single();

    // Fetch quiz submissions
    final submissionsResp = await supabase
        .from('student_submissions')
        .select('score, submitted_at, assignment_id')
        .eq('student_id', studentId);

    final quizSubs = submissionsResp.map<QuizSubmission>((sub) {
      return QuizSubmission(
        quizTitle: sub['assignment_id']?.toString() ?? 'Quiz',
        score: (sub['score'] as num).toDouble(),
        submittedAt: DateTime.parse(sub['submitted_at']),
      );
    }).toList();

    final avgScore = quizSubs.isNotEmpty
        ? quizSubs.map((e) => e.score).reduce((a, b) => a + b) / quizSubs.length
        : 0;

    progressList.add(StudentProgress(
      studentId: studentId,
      studentName: studentName,
      readingLevel: levelResp['title'] ?? '',
      averageScore: avgScore.toDouble(),
      quizSubmissions: quizSubs,
    ));
  }

  return progressList;
}


class ParentDashboardPage extends StatefulWidget {
  final String parentId; // logged-in parent

  const ParentDashboardPage({super.key, required this.parentId});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  bool _isLoading = true;
  List<StudentProgress> _childrenProgress = [];

  @override
  void initState() {
    super.initState();
    _fetchChildrenProgress();
  }

  Future<void> _fetchChildrenProgress() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      final studentsResp = await supabase
          .from('students')
          .select('id, student_name, current_reading_level_id')
          .eq('parent_id', widget.parentId);

      List<StudentProgress> progressList = [];

      for (final s in studentsResp) {
        final studentId = s['id'];
        final studentName = s['student_name'];

        // Fetch reading level
        final levelResp = await supabase
            .from('reading_levels')
            .select('title')
            .eq('id', s['current_reading_level_id'])
            .maybeSingle();

        // Fetch quiz submissions
        final submissionsResp = await supabase
            .from('student_submissions')
            .select('score, submitted_at, assignment_id')
            .eq('student_id', studentId);

        final quizSubs = (submissionsResp as List<dynamic>)
            .map<QuizSubmission>((sub) {
          return QuizSubmission(
            quizTitle: sub['assignment_id']?.toString() ?? 'Quiz',
            score: (sub['score'] as num).toDouble(),
            submittedAt: DateTime.parse(sub['submitted_at']),
          );
        }).toList();

        final avgScore = quizSubs.isNotEmpty
            ? quizSubs.map((e) => e.score).reduce((a, b) => a + b) / quizSubs.length
            : 0.0;

        progressList.add(StudentProgress(
          studentId: studentId,
          studentName: studentName,
          readingLevel: levelResp?['title'] ?? 'Not Set',
          averageScore: avgScore,
          quizSubmissions: quizSubs,
        ));
      }

      setState(() {
        _childrenProgress = progressList;
      });
    } catch (e) {
      debugPrint('Error fetching children progress: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Children')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _childrenProgress.isEmpty
          ? const Center(child: Text('No children found.'))
          : ListView.builder(
        itemCount: _childrenProgress.length,
        itemBuilder: (context, index) {
          final progress = _childrenProgress[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: ListTile(
              title: Text(progress.studentName),
              subtitle: Text(
                  'Level: ${progress.readingLevel} | Avg Score: ${progress.averageScore.toStringAsFixed(1)}'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildDetailPage(progress: progress),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
