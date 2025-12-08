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
    _badgesFuture = _loadBadgesFromSubmissions();
  }

  Future<List<Map<String, dynamic>>> _loadBadgesFromSubmissions() async {
    final supabase = Supabase.instance.client;
    final authUserId = supabase.auth.currentUser?.id;
    if (authUserId == null) return [];

    // Fetch all submissions by this student
    final submissions = await supabase
        .from('student_submissions')
        .select('id, assignment_id, score, max_score, submitted_at')
        .eq('student_id', authUserId)
        .order('submitted_at', ascending: true);

    // Themed badge names
    final badgeNames = [
      'Star Badge',
      'Diamond Badge',
      'Gold Badge',
      'Bookworm Badge',
      'Reading Champ',
      'Silver Badge',
      'Ruby Badge',
      'Scholar Badge',
      'Platinum Badge',
      'Emerald Badge',
      'Crystal Badge',
      'Sapphire Badge',
      'Pearl Badge',
      'Top Reader',
      'Literacy Hero',
      'Page Turner',
      'Story Explorer',
      'Book Collector',
      'Knowledge Seeker',
      'Reading Star',
      'Library Champion',
      'Wisdom Badge',
      'Book Adventurer',
      'Treasure Reader',
      'Ink Master',
      'Text Conqueror',
      'Word Wizard',
      'Literary Ace',
      'Epic Reader',
      'Novel Master',
      'Reading Genius',
      'Learning Star',
      'Story Hero',
      'Book Knight',
      'Tale Hunter',
      'Pro Reader',
      'Golden Pen',
      'Reading Explorer',
      'Knowledge Knight',
      'Epic Scholar',
      'Story Collector',
      'Book Sage',
      'Text Champion',
      'Learning Gem',
      'Reading Legend',
      'Book Titan',
      'Wisdom Warrior',
      'Story Conqueror',
      'Literacy Legend',
      'Word Star',
      'Ink Champion',
      'Novel Hero',
      'Page Master',
      'Literary Star',
      'Reading Titan',
      'Book Explorer',
      'Knowledge Hero',
      'Pro Scholar',
      'Epic Tale Badge',
      'Silver Pen',
      'Golden Book',
      'Story Wizard',
      'Page Hero',
      'Learning Knight',
      'Book Genius',
      'Reading Ace',
      'Word Hunter',
      'Tale Explorer',
      'Ink Hero',
      'Novel Legend',
      'Library Titan',
      'Story Knight',
      'Knowledge Star',
      'Reading Conqueror',
      'Book Wizard',
      'Text Hero',
      'Literary Champion',
      'Page Legend',
      'Reading Warrior',
      'Book Star',
      'Golden Reader',
      'Diamond Reader',
      'Epic Reader Badge',
      'Silver Reader',
      'Ruby Reader',
      'Scholar Star',
      'Reading Adventurer',
      'Story Master',
      'Knowledge Explorer',
      'Pro Reader Badge',
      'Tale Collector',
      'Ink Master Badge',
      'Literary Hero',
      'Page Collector',
      'Book Explorer Badge',
      'Reading Knight',
      'Word Hero',
      'Story Titan',
      'Learning Legend',
      'Book Ace',
    ];

    // Badge colors corresponding to names
    final badgeColors = [
      Colors.amber.shade600,
      Colors.blue.shade400,
      Colors.yellow.shade700,
      Colors.green.shade400,
      Colors.purple.shade400,
      Colors.grey.shade500,
      Colors.red.shade400,
      Colors.indigo.shade400,
    ];

    List<Map<String, dynamic>> badges = [];
    int badgeIndex = 0;

    for (final sub in submissions) {
      final int score = (sub['score'] ?? 0) as int;
      final int maxScore = (sub['max_score'] ?? 0) as int;

      if (maxScore <= 0) continue;

      // Assign themed badge name and color
      final badgeName = badgeNames[badgeIndex % badgeNames.length];
      final badgeColor = badgeColors[badgeIndex % badgeColors.length];

      final badge = {
        'title': badgeName,
        'score': score,
        'max_score': maxScore,
        'earned_at': sub['submitted_at'],
        'badge_icon': Icons.emoji_events,
        'badge_color': badgeColor,
      };

      badges.add(badge);
      badgeIndex++;
    }

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Badges')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _badgesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading badges...');
          }

          if (snapshot.hasError) {
            return ErrorState(
              message: 'Failed to load badges',
              onRetry: () {
                setState(() => _badgesFuture = _loadBadgesFromSubmissions());
              },
            );
          }

          final badges = snapshot.data ?? [];

          if (badges.isEmpty) {
            return const EmptyState(
              title: 'No badges yet',
              subtitle: 'Complete tasks to earn badges!',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final b = badges[index];
              final score = b['score'] as int;
              final max = b['max_score'] as int;
              final ratio = max > 0 ? (score / max) : 0.0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: b['badge_color'] as Color,
                  child: Icon(b['badge_icon'] as IconData, color: Colors.white),
                ),
                title: Text(b['title'] ?? 'Task'),
                subtitle: Text(
                  'Score: $score / $max (${(ratio * 100).toStringAsFixed(0)}%)',
                ),
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
