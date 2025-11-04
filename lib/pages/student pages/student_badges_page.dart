import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/ui_states.dart';

class StudentBadgesPage extends StatefulWidget {
  const StudentBadgesPage({super.key});

  @override
  State<StudentBadgesPage> createState() => _StudentBadgesPageState();
}

class _StudentBadgesPageState extends State<StudentBadgesPage> {
  late Future<List<Map<String, dynamic>>> _badgesFuture;

  @override
  void initState() {
    super.initState();
    _badgesFuture = _loadBadges();
  }

  Future<List<Map<String, dynamic>>> _loadBadges() async {
    final supabase = Supabase.instance.client;
    final authUserId = supabase.auth.currentUser?.id;
    if (authUserId == null) return [];

    // A badge is a submission with score/max_score >= 0.8
    final submissions = await supabase
        .from('student_submissions')
        .select('score, max_score, assignment_id, submitted_at')
        .eq('student_id', authUserId)
        .order('submitted_at', ascending: false);

    List<Map<String, dynamic>> badges = [];
    for (final row in submissions) {
      final int score = (row['score'] ?? 0) as int;
      final int maxScore = (row['max_score'] ?? 0) as int;
      if (maxScore <= 0) continue;
      final ratio = score / maxScore;
      if (ratio >= 0.8) {
        badges.add({
          'score': score,
          'max_score': maxScore,
          'assignment_id': row['assignment_id'],
          'submitted_at': row['submitted_at'],
        });
      }
    }

    // Optionally enrich with assignment/quiz titles
    for (final b in badges) {
      final assignment = await supabase
          .from('assignments')
          .select('id, task:tasks(title)')
          .eq('id', b['assignment_id'])
          .maybeSingle();
      b['title'] = assignment != null ? (assignment['task']?['title'] ?? 'Task') : 'Task';
    }

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Badges'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _badgesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading badges...');
          }
          if (snapshot.hasError) {
            return ErrorState(message: 'Failed to load badges', onRetry: () {
              setState(() => _badgesFuture = _loadBadges());
            });
          }
          final badges = snapshot.data ?? [];
          if (badges.isEmpty) {
            return const EmptyState(title: 'No badges yet', subtitle: 'Complete tasks with high scores to earn badges!');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final b = badges[index];
              final score = b['score'] as int;
              final max = b['max_score'] as int;
              final ratio = (max > 0) ? (score / max) : 0.0;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber.shade600,
                  child: const Icon(Icons.emoji_events, color: Colors.white),
                ),
                title: Text(b['title'] ?? 'Task'),
                subtitle: Text('Score: $score / $max (${(ratio * 100).toStringAsFixed(0)}%)'),
                trailing: const Icon(Icons.chevron_right),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: badges.length,
          );
        },
      ),
    );
  }
}


