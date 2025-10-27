import 'package:flutter/material.dart';
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
      // Fetch all submissions with details
      final subsRes = await supabase
          .from('student_submissions')
          .select('*')
          .order('submitted_at', ascending: false);

      final List<Map<String, dynamic>> subs =
          List<Map<String, dynamic>>.from(subsRes);

      // Get unique student IDs
      final userIds = subs.map((s) => s['student_id']).toSet().toList();

      // Fetch student names
      final usersRes = await supabase
          .from('students')
          .select('user_id, student_name')
          .filter('user_id', 'in', userIds);

      final Map<String, String> names = {
        for (var u in usersRes)
          u['user_id'] as String: u['student_name'] as String
      };

      // Calculate student progress
      final Map<String, Map<String, dynamic>> progress = {};
      for (var studentId in userIds) {
        final studentSubs = subs.where((s) => s['student_id'] == studentId).toList();
        
        // Calculate metrics
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
          (sum, s) => sum + ((s['max_score'] ?? 0) as int) - ((s['score'] ?? 0) as int),
        );

        progress[studentId] = {
          'totalQuizzes': totalQuizzes,
          'averageScore': maxPossible > 0 ? (correctAnswers / maxPossible) * 100 : 0.0,
          'totalCorrect': correctAnswers,
          'totalMiscues': miscues,
          'needsHelp': (maxPossible > 0 && (correctAnswers / maxPossible) < 60) || totalQuizzes == 0,
        };
      }

      setState(() {
        submissions = subs;
        studentNames = names;
        studentProgress = progress;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error loading submissions: $e");
      setState(() => loading = false);
    }
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      HapticFeedback.lightImpact();
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
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
      filtered = filtered.where((s) => s['student_id'] == _selectedStudent).toList();
    }

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filtered = filtered.where((s) {
        final studentName = (studentNames[s['student_id']] ?? 'Unknown').toLowerCase();
        return studentName.contains(_searchQuery!.toLowerCase());
      }).toList();
    }

    return filtered;
  }


  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("📊 Pupil Submissions & Reports")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Pupil Submissions & Reports"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Submissions', icon: Icon(Icons.list)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            Tab(text: 'Students Needing Help', icon: Icon(Icons.flag)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubmissions,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSubmissionsTab(),
            _buildAnalyticsTab(),
            _buildNeedsHelpTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionsTab() {
    final filtered = _filteredSubmissions;

    return Column(
      children: [
        _buildSearchAndFilterBar(),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No submissions found',
                        style: TextStyle(color: Colors.grey[600], fontSize: 18),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildSubmissionCard(filtered[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
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
    final needsHelpData = studentProgress.entries
        .where((entry) => entry.value['needsHelp'] == true)
        .toList();

    return needsHelpData.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 80, color: Colors.green[400]),
                const SizedBox(height: 16),
                Text(
                  'All students are performing well!',
                  style: TextStyle(color: Colors.green[700], fontSize: 18),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: needsHelpData.length,
        itemBuilder: (context, index) {
              final entry = needsHelpData[index];
              final studentId = entry.key;
              final data = entry.value;
              final studentName = studentNames[studentId] ?? 'Unknown';

              return Card(
                color: Colors.orange.shade50,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade200,
                    child: Icon(Icons.person, color: Colors.orange.shade800),
                  ),
                  title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Average Score: ${data['averageScore'].toStringAsFixed(1)}%'),
                      Text('Total Quizzes: ${data['totalQuizzes']}'),
                      Text('Total Miscues: ${data['totalMiscues']}'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.visibility, size: 20),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _selectedStudent = studentId);
                          _tabController.animateTo(0);
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.feedback, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text('Provide Feedback'),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FeedbackAndRemedialPage(
                                studentId: studentId,
                                studentName: studentName,
                                studentProgress: data,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by student name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery != null && _searchQuery!.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = null),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Filter by Student',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            value: _selectedStudent,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Students')),
              ...studentNames.entries.map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _selectedStudent = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> sub) {
    final studentName = studentNames[sub['student_id']] ?? 'Unknown';
    final score = sub['score'] ?? 0;
    final maxScore = sub['max_score'] ?? 0;
    final hasAudio = sub['audio_file_path'] != null;
    final scorePercent = maxScore > 0 ? (score / maxScore) : 0.0;

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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(studentName.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (sub['submitted_at'] != null)
                        Text(
                          'Submitted: ${DateTime.parse(sub['submitted_at']).toLocal().toString().split('.')[0]}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(scorePercent * 100).toInt()}%',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(Icons.quiz, 'Score', '$score / $maxScore'),
                _buildStatChip(Icons.refresh, 'Attempt', '${sub['attempt_number']}'),
              ],
            ),
            if (hasAudio) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.mic, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('Student Recording:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  StreamBuilder<PlayerState>(
                    stream: _audioPlayer.onPlayerStateChanged,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data == PlayerState.playing;
                      return IconButton(
                        icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
                        color: Colors.blue,
                        iconSize: 32,
                        onPressed: () {
                          final audioUrl = sub['audio_file_path'] as String;
                          if (isPlaying) {
                            _pauseAudio();
                          } else {
                            _playAudio(audioUrl);
                          }
                        },
                      );
                    },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeedbackAndRemedialPage(
                      studentId: sub['student_id'],
                      studentName: studentName,
                      studentProgress: studentProgress[sub['student_id']] ?? {},
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.feedback),
              label: const Text('Provide Feedback & Assign Tasks'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildOverallStats() {
    final totalStudents = studentProgress.length;
    final totalSubmissions = submissions.length;
    final avgScore = studentProgress.values.isEmpty
        ? 0.0
        : studentProgress.values
                .map((p) => p['averageScore'] as double)
                .reduce((a, b) => a + b) /
            studentProgress.length;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Overall Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox('Total Students', totalStudents.toString(), Icons.people),
                _buildStatBox('Total Submissions', totalSubmissions.toString(), Icons.assignment),
                _buildStatBox('Average Score', '${avgScore.toStringAsFixed(1)}%', Icons.trending_up),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue.shade700),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStudentPerformanceChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...studentProgress.entries.map((entry) {
              final studentName = studentNames[entry.key] ?? 'Unknown';
              final data = entry.value;
              final avgScore = data['averageScore'] as double;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                            color: avgScore >= 80
                                ? Colors.green
                                : avgScore >= 60
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: avgScore / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                        avgScore >= 80
                            ? Colors.green
                            : avgScore >= 60
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
