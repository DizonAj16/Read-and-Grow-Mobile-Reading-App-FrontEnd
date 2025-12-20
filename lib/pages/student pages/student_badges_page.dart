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
  final List<Color> _badgeLevelColors = [
    Colors.grey.shade400,      // Level 1
    Colors.blue.shade300,      // Level 2
    Colors.green.shade400,     // Level 3
    Colors.orange.shade400,    // Level 4
    Colors.purple.shade400,    // Level 5
    Colors.red.shade400,       // Level 6
    Colors.amber.shade600,     // Level 7
    Colors.teal.shade400,      // Level 8
    Colors.pink.shade400,      // Level 9
    Colors.indigo.shade400,    // Level 10
    Colors.cyan.shade400,      // Level 11
    Colors.deepOrange.shade400,// Level 12
    Colors.lime.shade600,      // Level 13
    Colors.deepPurple.shade400,// Level 14
    Colors.brown.shade400,     // Level 15
  ];

  final List<IconData> _badgeIcons = [
    Icons.star_border,
    Icons.star_half,
    Icons.star,
    Icons.emoji_events_outlined,
    Icons.workspace_premium_outlined,
    Icons.diamond_outlined,
    Icons.military_tech_outlined,
    Icons.verified_outlined,
    Icons.bolt_outlined,
    Icons.whatshot_outlined,
    Icons.auto_awesome_outlined,
    Icons.diamond,
    Icons.circle_outlined,
    Icons.hexagon_outlined,
    Icons.ac_unit_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _badgesFuture = _loadBadgesFromSubmissions();
  }

  // Progressive badge naming system based on performance
  String _getBadgeName(int index, double scoreRatio) {
    // Base badge names organized by difficulty level
    final List<List<String>> badgeLevels = [
      // Level 1: Beginner (1-3 badges)
      ['New Reader', 'Story Starter', 'Page Explorer'],
      
      // Level 2: Novice (4-7 badges)
      ['Word Learner', 'Book Beginner', 'Reading Seed', 'Story Sprout'],
      
      // Level 3: Intermediate (8-12 badges)
      ['Paragraph Pioneer', 'Chapter Champion', 'Book Adventurer', 'Text Traveler', 'Page Pioneer'],
      
      // Level 4: Proficient (13-18 badges)
      ['Reading Ranger', 'Story Scout', 'Book Knight', 'Literary Learner', 'Word Warrior', 'Page Knight'],
      
      // Level 5: Advanced (19-25 badges)
      ['Epic Reader', 'Novel Navigator', 'Tale Tamer', 'Prose Pro', 'Literacy Leader', 'Story Sage', 'Book Baron'],
      
      // Level 6: Expert (26-33 badges)
      ['Reading Royalty', 'Text Titan', 'Page Prince/Princess', 'Word Wizard', 'Literary Legend', 'Story Sovereign', 'Book Emperor', 'Prose Paladin'],
      
      // Level 7: Master (34-42 badges)
      ['Master Reader', 'Grand Librarian', 'Ultimate Storyteller', 'Literacy Luminary', 'Epic Wordsmith', 'Tale Archmage', 'Book Oracle', 'Reading Philosopher', 'Story Alchemist'],
      
      // Level 8: Grandmaster (43-52 badges)
      ['Reading Deity', 'Bibliophile Deity', 'Word Deity', 'Story Deity', 'Literary Deity', 'Page Deity', 'Text Deity', 'Prose Deity', 'Book Deity', 'Chapter Deity'],
      
      // Level 9: Legendary (53-63 badges)
      ['Mythic Reader', 'Legendary Librarian', 'Timeless Tale Teller', 'Eternal Word Master', 'Infinite Page Turner', 'Celestial Story Weaver', 'Divine Book Binder', 'Universal Reader', 'Cosmic Storyteller', 'Galactic Librarian', 'Omnipotent Reader'],
      
      // Level 10: Mythic (64+ badges)
      ['Phoenix Reader', 'Dragon Storyteller', 'Griffin Librarian', 'Unicorn Wordsmith', 'Mermaid Tale Weaver', 'Centaur Page Master', 'Sphinx Book Guardian', 'Pegasus Story Flyer', 'Kraken Deep Reader'],
    ];

    // Determine which level this badge belongs to based on index
    int level = 0;
    int cumulativeCount = 0;
    
    for (int i = 0; i < badgeLevels.length; i++) {
      cumulativeCount += badgeLevels[i].length;
      if (index < cumulativeCount) {
        level = i;
        break;
      }
    }

    // Get the specific badge within the level
    int positionInLevel = index;
    for (int i = 0; i < level; i++) {
      positionInLevel -= badgeLevels[i].length;
    }

    // Ensure we don't go out of bounds
    if (positionInLevel >= badgeLevels[level].length) {
      positionInLevel = badgeLevels[level].length - 1;
    }

    String baseName = badgeLevels[level][positionInLevel];
    
    // Add performance modifier based on score ratio
    String performanceModifier = '';
    if (scoreRatio >= 0.9) {
      performanceModifier = '🌟 ';
    } else if (scoreRatio >= 0.8) {
      performanceModifier = '✨ ';
    } else if (scoreRatio >= 0.7) {
      performanceModifier = '⭐ ';
    }

    return '$performanceModifier$baseName';
  }

  Future<List<Map<String, dynamic>>> _loadBadgesFromSubmissions() async {
    final supabase = Supabase.instance.client;
    final authUserId = supabase.auth.currentUser?.id;
    if (authUserId == null) return [];

    try {
      // Fetch all submissions by this student with assignment details
      final submissions = await supabase
          .from('student_submissions')
          .select('''
            id, 
            assignment_id, 
            score, 
            max_score, 
            submitted_at,
            assignments!inner(
              quiz_id,
              tasks!inner(
                title,
                quizzes!inner(title)
              )
            )
          ''')
          .eq('student_id', authUserId)
          .order('submitted_at', ascending: true);

      if (submissions.isEmpty) return [];

      List<Map<String, dynamic>> badges = [];
      int totalSubmissions = submissions.length;

      for (int i = 0; i < submissions.length; i++) {
        final sub = submissions[i];
        final int score = (sub['score'] ?? 0) as int;
        final int maxScore = (sub['max_score'] ?? 0) as int;
        
        if (maxScore <= 0) continue;

        final double scoreRatio = score / maxScore;
        final String badgeName = _getBadgeName(i, scoreRatio);
        final Color badgeColor = _badgeLevelColors[i % _badgeLevelColors.length];
        final IconData badgeIcon = _badgeIcons[i % _badgeIcons.length];

        // Get quiz/task title
        String activityTitle = 'Quiz';
        final assignments = sub['assignments'] as Map<String, dynamic>?;
        if (assignments != null) {
          final tasks = assignments['tasks'] as Map<String, dynamic>?;
          if (tasks != null) {
            activityTitle = tasks['title'] as String? ?? 'Task';
            final quizzes = tasks['quizzes'] as List<dynamic>?;
            if (quizzes != null && quizzes.isNotEmpty) {
              final quiz = quizzes[0] as Map<String, dynamic>?;
              if (quiz != null) {
                activityTitle = quiz['title'] as String? ?? 'Quiz';
              }
            }
          }
        }

        final badge = {
          'id': sub['id'],
          'title': badgeName,
          'activity_title': activityTitle,
          'score': score,
          'max_score': maxScore,
          'score_ratio': scoreRatio,
          'percentage': (scoreRatio * 100).toInt(),
          'earned_at': sub['submitted_at'],
          'badge_icon': badgeIcon,
          'badge_color': badgeColor,
          'badge_level': (i ~/ 10) + 1, // Every 10 badges = new level
          'badge_number': i + 1,
          'is_recent': i == submissions.length - 1, // Latest badge
        };

        badges.add(badge);
      }

      // Reverse so newest badges appear first
      return badges.reversed.toList();
    } catch (e) {
      debugPrint('Error loading badges: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Badges'),
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.05),
              colorScheme.surface,
            ],
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _badgesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingState(message: 'Loading your badges...');
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
              return EmptyState(
                title: 'No Badges Yet',
                subtitle: 'Complete quizzes and tasks to earn badges!',
                icon: Icons.emoji_events_outlined,
                buttonText: 'Start Learning',
                onPressed: () {
                  // You can add navigation here if needed
                },
              );
            }

            final totalBadges = badges.length;
            final latestBadge = badges.firstWhere(
              (badge) => badge['is_recent'] == true,
              orElse: () => badges.first,
            );

            return CustomScrollView(
              slivers: [
                // Header with stats
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withOpacity(0.8),
                          colorScheme.secondary.withOpacity(0.6),
                        ],
                      ),
                      // borderRadius: const BorderRadius.only(
                      //   bottomLeft: Radius.circular(30),
                      //   bottomRight: Radius.circular(30),
                      // ),
                    ),
                    child: Column(
                      children: [
                        // Badge count and level
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard(
                              icon: Icons.emoji_events,
                              value: totalBadges.toString(),
                              label: 'Total Badges',
                              color: Colors.white,
                            ),
                            _buildStatCard(
                              icon: Icons.star,
                              value: 'Level ${(totalBadges ~/ 10) + 1}',
                              label: 'Current Level',
                              color: Colors.white,
                            ),

                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Latest badge highlight
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: latestBadge['badge_color'] as Color,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  latestBadge['badge_icon'] as IconData,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Latest Achievement',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    Text(
                                      latestBadge['title'] as String,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '${latestBadge['activity_title']} - ${latestBadge['percentage']}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.celebration,
                                color: Colors.white,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Badges grid
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.7,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final badge = badges[index];
                        final badgeColor = badge['badge_color'] as Color;
                        final badgeLevel = badge['badge_level'] as int;
                        final badgeNumber = badge['badge_number'] as int;
                        final scoreRatio = badge['score_ratio'] as double;

                        return Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: badgeColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Badge content
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Badge icon
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          badge['badge_icon'] as IconData,
                                          color: badgeColor,
                                          size: 36,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Badge name
                                      Text(
                                        badge['title'] as String,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                          height: 1.2,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      // Activity info
                                      Text(
                                        badge['activity_title'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      // Score indicator
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getScoreColor(scoreRatio).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getScoreIcon(scoreRatio),
                                              size: 12,
                                              color: _getScoreColor(scoreRatio),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${badge['percentage']}%',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _getScoreColor(scoreRatio),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      // Badge number and level
                                      Text(
                                        'Badge #$badgeNumber • Level $badgeLevel',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Top-right indicator for latest badge
                                if (badge['is_recent'] == true)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'NEW',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: badges.length,
                    ),
                  ),
                ),

                // Empty space at bottom
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double ratio) {
    if (ratio >= 0.9) return Colors.green;
    if (ratio >= 0.8) return Colors.blue;
    if (ratio >= 0.7) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(double ratio) {
    if (ratio >= 0.9) return Icons.star;
    if (ratio >= 0.8) return Icons.thumb_up;
    if (ratio >= 0.7) return Icons.check_circle;
    return Icons.tips_and_updates;
  }
}