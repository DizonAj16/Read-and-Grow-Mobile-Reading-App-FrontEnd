import 'package:deped_reading_app_laravel/pages/teacher%20pages/student_answers_page.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'feedback_and_remedial_page.dart';

class StudentSubmissionsPage extends StatefulWidget {
  const StudentSubmissionsPage({super.key});

  @override
  State<StudentSubmissionsPage> createState() => _StudentSubmissionsPageState();
}

class _StudentSubmissionsPageState extends State<StudentSubmissionsPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool loading = true;
  List<Map<String, dynamic>> submissions = [];
  Map<String, String> studentNames = {};
  Map<String, Map<String, dynamic>> studentProgress = {};
  String? _searchQuery;
  String? _selectedStudent;
  Map<String, String?> studentPictures = {};
  Map<String, String> quizTitles = {}; // NEW: Store quiz titles
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSubmissions();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmissions() async {
    setState(() => loading = true);

    try {
      // Fetch all submissions
      final subsRes = await supabase
          .from('student_submissions')
          .select('*')
          .order('submitted_at', ascending: false);

      final List<Map<String, dynamic>> subs = List<Map<String, dynamic>>.from(
        subsRes,
      );

      // Get unique student IDs
      final userIds =
          subs.map((s) => s['student_id']).whereType<String>().toSet().toList();

      // Fetch student names
      final usersRes = await supabase
          .from('students')
          .select('id, student_name, profile_picture')
          .filter('id', 'in', userIds);

      final Map<String, String> names = {
        for (var u in usersRes) u['id'] as String: u['student_name'] as String,
      };
      final Map<String, String?> pictures = {};
      for (var u in usersRes) {
        final id = u['id'] as String;
        names[id] = u['student_name'] as String;
        pictures[id] = u['profile_picture']?.toString();
      }

      // NEW: Get assignment IDs and fetch assignments with quiz data
      final assignmentIds =
          subs
              .map((s) => s['assignment_id'])
              .whereType<String>()
              .toSet()
              .toList();
      final Map<String, String> assignmentQuizTitles = {};

      if (assignmentIds.isNotEmpty) {
        final assignmentsRes = await supabase
            .from('assignments')
            .select('id, quiz_id, quizzes!inner(id, title)')
            .inFilter('id', assignmentIds);

        for (var assignment in assignmentsRes) {
          final assignmentId = assignment['id']?.toString();
          final quizData = assignment['quizzes'];
          if (assignmentId != null && quizData is Map<String, dynamic>) {
            final quizTitle = quizData['title']?.toString();
            if (quizTitle != null) {
              assignmentQuizTitles[assignmentId] = quizTitle;
            }
          }
        }
      }

      // NEW: Add quiz titles to submissions
      for (var submission in subs) {
        final assignmentId = submission['assignment_id']?.toString();
        if (assignmentId != null &&
            assignmentQuizTitles.containsKey(assignmentId)) {
          submission['quiz_title'] = assignmentQuizTitles[assignmentId];
        }
      }

      // Calculate student progress (same as before)
      final Map<String, Map<String, dynamic>> progress = {};
      for (var studentId in userIds) {
        final studentSubs =
            subs.where((s) => s['student_id'] == studentId).toList();

        int totalQuizzes = studentSubs.length;
        int correctAnswers = studentSubs.fold<int>(
          0,
          (sum, s) => sum + ((s['score'] ?? 0) as int),
        );
        int maxPossible = studentSubs.fold<int>(
          0,
          (sum, s) => sum + ((s['max_score'] ?? 0) as int),
        );
        int miscues = studentSubs.fold<int>(
          0,
          (sum, s) =>
              sum + ((s['max_score'] ?? 0) as int) - ((s['score'] ?? 0) as int),
        );

        progress[studentId] = {
          'totalQuizzes': totalQuizzes,
          'averageScore':
              maxPossible > 0 ? (correctAnswers / maxPossible) * 100 : 0.0,
          'totalCorrect': correctAnswers,
          'totalMiscues': miscues,
          'needsHelp':
              (maxPossible > 0 &&
                  ((correctAnswers / maxPossible) * 100) <
                      75) || // Changed to 75%
              totalQuizzes == 0,
        };
      }

      setState(() {
        submissions = subs;
        studentNames = names;
        studentPictures = pictures;
        studentProgress = progress;
        quizTitles = assignmentQuizTitles;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error loading submissions: $e");
      setState(() => loading = false);
    }
  }

  // NEW: Helper method to get quiz title for a submission
  String _getQuizTitle(Map<String, dynamic> submission) {
    return submission['quiz_title'] as String? ?? 'Quiz Submission';
  }

  // NEW: Helper method to check if submission has a quiz
  bool _hasQuiz(Map<String, dynamic> submission) {
    return submission['quiz_title'] != null;
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      HapticFeedback.lightImpact();
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
  }

  List<Map<String, dynamic>> get _filteredSubmissions {
    var filtered = submissions;

    if (_selectedStudent != null) {
      filtered =
          filtered.where((s) => s['student_id'] == _selectedStudent).toList();
    }

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filtered =
          filtered.where((s) {
            final studentName =
                (studentNames[s['student_id']] ?? 'Unknown').toLowerCase();
            return studentName.contains(_searchQuery!.toLowerCase());
          }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final primaryLight = Color.alphaBlend(
      primaryColor.withOpacity(0.1),
      Colors.white,
    );
    final primaryMedium = Color.alphaBlend(
      primaryColor.withOpacity(0.3),
      Colors.white,
    );

    if (loading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              Text(
                'Loading Submissions...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Custom TabBar Header
          Container(
            color: primaryColor,
            child: Column(
              children: [
                // TabBar
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  tabs: const [
                    Tab(text: 'All Submissions', icon: Icon(Icons.list_alt)),
                    Tab(
                      text: 'Analytics',
                      icon: Icon(Icons.analytics_outlined),
                    ),
                    Tab(text: 'Need Help', icon: Icon(Icons.flag_outlined)),
                  ],
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadSubmissions,
              color: primaryColor,
              backgroundColor: Colors.white,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSubmissionsTab(),
                  _buildAnalyticsTab(),
                  _buildNeedsHelpTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsTab() {
    final filtered = _filteredSubmissions;

    return Column(
      children: [
        _buildSearchAndFilterBar(),
        Expanded(
          child:
              filtered.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No submissions found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery != null || _selectedStudent != null
                              ? 'Try adjusting your search or filters'
                              : 'Student submissions will appear here',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder:
                        (context, index) =>
                            _buildSubmissionCard(filtered[index]),
                  ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final primaryLight = Color.alphaBlend(
      primaryColor.withOpacity(0.1),
      Colors.white,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallStats(),
          const SizedBox(height: 24),
          _buildStudentPerformanceChart(),
        ],
      ),
    );
  }

  Widget _buildNeedsHelpTab() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final primaryLight = Color.alphaBlend(
      primaryColor.withOpacity(0.1),
      Colors.white,
    );
    final needsHelpData =
        studentProgress.entries
            .where((entry) => entry.value['needsHelp'] == true)
            .toList();

    return needsHelpData.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.1),
                      Colors.lightGreen.withOpacity(0.1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 70,
                  color: Colors.green[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'All Students Are Performing Well!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.green[700],
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'No students currently need remedial help. Keep up the great work!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(0),
                  icon: const Icon(Iconsax.document_text, size: 20),
                  label: const Text(
                    'View All Submissions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        )
        : Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.1),
                    primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Iconsax.flag, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Students Needing Help',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.blueGrey[900],
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${needsHelpData.length} ${needsHelpData.length == 1 ? 'student' : 'students'} need additional support',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: needsHelpData.length,
                itemBuilder: (context, index) {
                  final entry = needsHelpData[index];
                  final studentId = entry.key;
                  final data = entry.value;
                  final studentName = studentNames[studentId] ?? 'Unknown';
                  final avgScore = data['averageScore'] as double;

                  Color scoreColor;
                  if (avgScore >= 80) {
                    scoreColor = Colors.green;
                  } else if (avgScore >= 60) {
                    scoreColor = Colors.orange;
                  } else {
                    scoreColor = primaryColor;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Material(
                      borderRadius: BorderRadius.circular(20),
                      elevation: 3,
                      color: Colors.white,
                      shadowColor: Colors.black.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image:
                                        studentPictures[studentId] != null
                                            ? DecorationImage(
                                              image: NetworkImage(
                                                studentPictures[studentId]!,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                            : null,
                                    color:
                                        studentPictures[studentId] == null
                                            ? primaryColor.withOpacity(0.1)
                                            : Colors.transparent,
                                  ),
                                  child:
                                      studentPictures[studentId] == null
                                          ? Center(
                                            child: Text(
                                              studentName.isNotEmpty
                                                  ? studentName[0].toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: primaryColor,
                                              ),
                                            ),
                                          )
                                          : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        studentName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          color: Colors.blueGrey[900],
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: scoreColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Iconsax.star,
                                              size: 14,
                                              color: scoreColor,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${avgScore.toStringAsFixed(1)}% Average Score',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: scoreColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: PopupMenuButton<String>(
                                    icon: Icon(
                                      Iconsax.more,
                                      color: primaryColor,
                                    ),
                                    onSelected: (value) {
                                      if (value == 'view_details') {
                                        setState(
                                          () => _selectedStudent = studentId,
                                        );
                                        _tabController.animateTo(0);
                                      } else if (value == 'provide_feedback') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => FeedbackAndRemedialPage(
                                                  studentId: studentId,
                                                  studentName: studentName,
                                                  studentProgress: data,
                                                ),
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder:
                                        (context) => [
                                          PopupMenuItem(
                                            value: 'view_details',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Iconsax.eye,
                                                  size: 18,
                                                  color: primaryColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'View Details',
                                                  style: TextStyle(
                                                    color: Colors.blueGrey[800],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'provide_feedback',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Iconsax.message_text,
                                                  size: 18,
                                                  color: primaryColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Provide Feedback',
                                                  style: TextStyle(
                                                    color: Colors.blueGrey[800],
                                                    fontWeight: FontWeight.w500,
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
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProgressIndicator(
                                    'Average Score',
                                    '${avgScore.toStringAsFixed(1)}%',
                                    avgScore / 100,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildMiniStat(
                                        'Quizzes',
                                        data['totalQuizzes'].toString(),
                                        Iconsax.document_text,
                                      ),
                                      _buildMiniStat(
                                        'Miscues',
                                        data['totalMiscues'].toString(),
                                        Iconsax.warning_2,
                                      ),
                                      _buildMiniStat(
                                        'Correct',
                                        data['totalCorrect'].toString(),
                                        Iconsax.tick_circle,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // const SizedBox(height: 16),
                            // SizedBox(
                            //   width: double.infinity,
                            //   child: ElevatedButton.icon(
                            //     onPressed: () {
                            //       Navigator.push(
                            //         context,
                            //         MaterialPageRoute(
                            //           builder:
                            //               (_) => FeedbackAndRemedialPage(
                            //                 studentId: studentId,
                            //                 studentName: studentName,
                            //                 studentProgress: data,
                            //               ),
                            //         ),
                            //       );
                            //     },
                            //     icon: Icon(Iconsax.message_text, size: 20),
                            //     label: const Text(
                            //       'Provide Detailed Feedback',
                            //       style: TextStyle(
                            //         fontSize: 15,
                            //         fontWeight: FontWeight.w700,
                            //         letterSpacing: 0.3,
                            //       ),
                            //     ),
                            //     style: ElevatedButton.styleFrom(
                            //       backgroundColor: primaryColor,
                            //       foregroundColor: Colors.white,
                            //       padding: const EdgeInsets.symmetric(
                            //         vertical: 16,
                            //       ),
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(14),
                            //       ),
                            //       elevation: 3,
                            //       shadowColor: primaryColor.withOpacity(0.4),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
  }

  Widget _buildProgressIndicator(String label, String value, double progress) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    Color color;
    if (progress >= 0.8) {
      color = Colors.green;
    } else if (progress >= 0.6) {
      color = Colors.orange;
    } else {
      color = primaryColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation(color),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, IconData warning_2) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final primaryLight = Color.alphaBlend(
      primaryColor.withOpacity(0.1),
      Colors.white,
    );
    final primaryMedium = Color.alphaBlend(
      primaryColor.withOpacity(0.3),
      Colors.white,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryLight, primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by student name...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[500]),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                if (_searchQuery != null && _searchQuery!.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[500]),
                    onPressed: () => setState(() => _searchQuery = null),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Filter by Student',
                border: InputBorder.none,
                labelStyle: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: _selectedStudent,
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(
                    'All Students',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ...studentNames.entries.map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: TextStyle(color: Colors.blueGrey[800]),
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _selectedStudent = value),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> sub) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final primaryLight = Color.alphaBlend(
      primaryColor.withOpacity(0.1),
      Colors.white,
    );
    final primaryMedium = Color.alphaBlend(
      primaryColor.withOpacity(0.3),
      Colors.white,
    );

    final studentName = studentNames[sub['student_id']] ?? 'Unknown';
    final score = sub['score'] ?? 0;
    final maxScore = sub['max_score'] ?? 0;
    final hasAudio = sub['audio_file_path'] != null;
    final scorePercent = maxScore > 0 ? (score / maxScore) : 0.0;
    final hasQuiz = _hasQuiz(sub); // NEW: Check if submission has a quiz
    final quizTitle = hasQuiz ? _getQuizTitle(sub) : ''; // NEW: Get quiz title

    Color scoreColor;
    if (scorePercent >= 0.8) {
      scoreColor = Colors.green;
    } else if (scorePercent >= 0.6) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = primaryColor;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => StudentAnswersPage(
                  submissionId: sub['id'], // or 'submission_id'
                  studentId: sub['student_id'], // needed by your review page
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with student info
                Row(
                  children: [
                    _buildAvatar(
                      studentPictures[sub['student_id']],
                      studentName.substring(0, 1).toUpperCase(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blueGrey[800],
                            ),
                          ),
                          // NEW: Display quiz title if available
                          if (hasQuiz) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.quiz,
                                    size: 12,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    quizTitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (sub['submitted_at'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Submitted: ${_formatDate(DateTime.parse(sub['submitted_at']))}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: scoreColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${(scorePercent * 100).toInt()}%',
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatChip(
                        Icons.quiz_outlined,
                        'Score',
                        '${(score is num ? score.toDouble() : double.tryParse(score.toString()) ?? 0.0).toInt()} / ${(maxScore is num ? maxScore.toDouble() : double.tryParse(maxScore.toString()) ?? 0.0).toInt()}',
                        primaryColor,
                      ),
                      _buildStatChip(
                        Icons.refresh_outlined,
                        'Attempt',
                        getAttemptSuffix(sub['attempt_number'] ?? 1),
                        primaryMedium,
                      ),
                    ],
                  ),
                ),

                // Audio recording section
                if (hasAudio) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.mic_none, color: primaryColor),
                        const SizedBox(width: 12),
                        const Text(
                          'Student Recording:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        StreamBuilder<PlayerState>(
                          stream: _audioPlayer.onPlayerStateChanged,
                          builder: (context, snapshot) {
                            final isPlaying =
                                snapshot.data == PlayerState.playing;
                            return Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  final audioUrl =
                                      sub['audio_file_path'] as String;
                                  if (isPlaying) {
                                    _pauseAudio();
                                  } else {
                                    _playAudio(audioUrl);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                // Feedback button
                // const SizedBox(height: 16),
                // SizedBox(
                //   width: double.infinity,
                //   child: ElevatedButton.icon(
                //     onPressed: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder:
                //               (_) => FeedbackAndRemedialPage(
                //                 studentId: sub['student_id'],
                //                 studentName: studentName,
                //                 studentProgress:
                //                     studentProgress[sub['student_id']] ?? {},
                //               ),
                //         ),
                //       );
                //     },
                //     icon: const Icon(Icons.feedback_outlined, size: 20),
                //     label: const Text(
                //       'Provide Feedback & Assign Tasks',
                //       style: TextStyle(
                //         fontSize: 14,
                //         fontWeight: FontWeight.w600,
                //       ),
                //     ),
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: primaryColor,
                //       foregroundColor: Colors.white,
                //       padding: const EdgeInsets.symmetric(vertical: 16),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       elevation: 2,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildOverallStats() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final primaryLight = Color.alphaBlend(
      primaryColor.withOpacity(0.1),
      Colors.white,
    );

    final totalStudents = studentProgress.length;
    final totalSubmissions = submissions.length;
    final avgScore =
        studentProgress.values.isEmpty
            ? 0.0
            : studentProgress.values
                    .map((p) => p['averageScore'] as double)
                    .reduce((a, b) => a + b) /
                studentProgress.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryLight, primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
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
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.analytics, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Overall Statistics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox(
                'Total Students',
                totalStudents.toString(),
                Icons.people_outline,
                primaryColor,
              ),
              _buildStatBox(
                'Total Submissions',
                totalSubmissions.toString(),
                Icons.assignment_outlined,
                Color.alphaBlend(primaryColor.withOpacity(0.7), Colors.purple),
              ),
              _buildStatBox(
                'Average Score',
                '${avgScore.toStringAsFixed(1)}%',
                Icons.trending_up_outlined,
                Color.alphaBlend(primaryColor.withOpacity(0.7), Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 28, color: color),
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
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStudentPerformanceChart() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
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
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bar_chart, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Student Performance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...studentProgress.entries.map((entry) {
            final studentName = studentNames[entry.key] ?? 'Unknown';
            final data = entry.value;
            final avgScore = data['averageScore'] as double;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${avgScore.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              avgScore >= 80
                                  ? Colors.green
                                  : avgScore >= 60
                                  ? Colors.orange
                                  : primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: avgScore / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(
                      avgScore >= 80
                          ? Colors.green
                          : avgScore >= 60
                          ? Colors.orange
                          : primaryColor,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAvatar(String? url, String fallbackLetter) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (url == null || url.isEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: primaryColor.withOpacity(0.1),
        child: Text(
          fallbackLetter,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: primaryColor,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey[200],
      child: ClipOval(
        child: FadeInImage.assetNetwork(
          placeholder: 'assets/placeholder/avatar_placeholder.jpg',
          image: url,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          imageErrorBuilder:
              (_, __, ___) => CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Text(
                  fallbackLetter,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

String getAttemptSuffix(int attempt) {
  if (attempt >= 11 && attempt <= 13) return '${attempt}th';
  switch (attempt % 10) {
    case 1:
      return '${attempt}st';
    case 2:
      return '${attempt}nd';
    case 3:
      return '${attempt}rd';
    default:
      return '${attempt}th';
  }
}
