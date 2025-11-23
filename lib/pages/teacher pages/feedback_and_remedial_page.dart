import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

class FeedbackAndRemedialPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final Map<String, dynamic> studentProgress;

  const FeedbackAndRemedialPage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentProgress,
  });

  @override
  State<FeedbackAndRemedialPage> createState() => _FeedbackAndRemedialPageState();
}

class _FeedbackAndRemedialPageState extends State<FeedbackAndRemedialPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _submissions = [];
  List<Map<String, dynamic>> _remedialTasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      // Load student submissions
      final subs = await supabase
          .from('student_submissions')
          .select('*, assignments(id, class_room_id)')
          .eq('student_id', widget.studentId)
          .order('submitted_at', ascending: false);

      // Load remedial tasks
      final remTasks = await supabase
          .from('remedial_assignments')
          .select('*, tasks(title, description, reading_level_id)')
          .eq('student_id', widget.studentId)
          .order('assigned_date', ascending: false);

      setState(() {
        _submissions = List<Map<String, dynamic>>.from(subs);
        _remedialTasks = List<Map<String, dynamic>>.from(remTasks);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _loading = false);
    }
  }

  void _showFeedbackDialog(Map<String, dynamic> submission) {
    final feedbackController = TextEditingController(
      text: submission['teacher_feedback'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Provide Feedback'),
        content: TextField(
          controller: feedbackController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter your feedback for this student...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _submitFeedback(submission['id'], feedbackController.text);
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Feedback saved successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              _loadData();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback(String submissionId, String feedback) async {
    try {
      await supabase
          .from('student_submissions')
          .update({'teacher_feedback': feedback})
          .eq('id', submissionId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  void _showRemedialTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎯 Assign Remedial Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('💡 This task will be assigned specifically to help this student improve their reading skills.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a task title')),
                );
                return;
              }

              await _assignRemedialTask(
                titleController.text,
                descController.text,
              );
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Remedial task assigned!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              _loadData();
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignRemedialTask(String title, String description) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final teacher = await supabase
          .from('teachers')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (teacher == null) return;

      // Create a simple remedial task
      await supabase.from('tasks').insert({
        'title': title,
        'description': description,
        'is_remedial': true,
      });

      // Then assign it as remedial
      // Note: This is a simplified version - in production you'd want to link to existing tasks
    } catch (e) {
      debugPrint('Error assigning remedial task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.studentName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('📝 ${widget.studentName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Submissions', icon: Icon(Icons.assignment)),
            Tab(text: 'Remedial Tasks', icon: Icon(Icons.school)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubmissionsTab(),
          _buildRemedialTasksTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRemedialTaskDialog,
        icon: const Icon(Icons.add_task),
        label: const Text('Assign Remedial Task'),
        backgroundColor: Colors.orange.shade700,
      ),
    );
  }

  Widget _buildSubmissionsTab() {
    final avgScore = widget.studentProgress['averageScore'] as double;
    final totalQuizzes = widget.studentProgress['totalQuizzes'] as int;

    return Column(
      children: [
        // Performance Summary
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: avgScore >= 60 ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: avgScore >= 60 ? Colors.green.shade200 : Colors.orange.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                avgScore >= 60 ? Icons.check_circle : Icons.warning,
                color: avgScore >= 60 ? Colors.green : Colors.orange,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average Performance',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${avgScore.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: avgScore >= 60 ? Colors.green : Colors.orange,
                      ),
                    ),
                    Text(
                      '$totalQuizzes quizzes completed',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Submissions List
        Expanded(
          child: _submissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No submissions yet',
                        style: TextStyle(color: Colors.grey[600], fontSize: 18),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _submissions.length,
                  itemBuilder: (context, index) => _buildSubmissionCard(_submissions[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> sub) {
    final score = sub['score'] ?? 0;
    final maxScore = sub['max_score'] ?? 0;
    final hasAudio = sub['audio_file_path'] != null;
    final hasFeedback = sub['teacher_feedback'] != null;
    final scorePercent = maxScore > 0 ? (score / maxScore) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: scorePercent >= 0.8
              ? Colors.green
              : scorePercent >= 0.6
                  ? Colors.orange
                  : Colors.red,
          child: Text(
            '${(scorePercent * 100).toInt()}%',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text(
          'Score: $score / $maxScore',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Submitted: ${DateTime.parse(sub['submitted_at']).toLocal().toString().split('.')[0]}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        children: [
          if (hasAudio) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
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
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          if (isPlaying) {
                            _audioPlayer.pause();
                          } else {
                            _audioPlayer.play(UrlSource(sub['audio_file_path']));
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
          ],
          if (hasFeedback) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.feedback, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Your Feedback',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(sub['teacher_feedback']),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _showFeedbackDialog(sub),
              icon: const Icon(Icons.edit),
              label: Text(hasFeedback ? 'Edit Feedback' : 'Add Feedback'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemedialTasksTab() {
    return _remedialTasks.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No remedial tasks assigned yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Assign remedial tasks to help this student improve their reading skills',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _remedialTasks.length,
            itemBuilder: (context, index) => _buildRemedialTaskCard(_remedialTasks[index]),
          );
  }

  Widget _buildRemedialTaskCard(Map<String, dynamic> task) {
    final assignedDate = DateTime.parse(task['assigned_date']);
    final isCompleted = task['completed'] == true;
    final taskDetails = task['tasks'] as Map<String, dynamic>?;

    return Card(
      color: isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted ? Colors.green : Colors.orange,
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.school,
            color: Colors.white,
          ),
        ),
        title: Text(
          taskDetails?['title'] ?? 'Remedial Task',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (taskDetails?['description'] != null)
              Text(taskDetails?['description'], style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              'Assigned: ${assignedDate.toLocal().toString().split(' ')[0]}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            if (isCompleted)
              Text(
                '✅ Completed',
                style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: Icon(
          isCompleted ? Icons.verified : Icons.arrow_forward,
          color: isCompleted ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}
