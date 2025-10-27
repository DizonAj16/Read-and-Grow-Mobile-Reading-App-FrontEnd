import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'comprehension_and_quiz.dart';

class EnhancedReadingTaskPage extends StatefulWidget {
  final Map<String, dynamic> task;

  const EnhancedReadingTaskPage({super.key, required this.task});

  @override
  State<EnhancedReadingTaskPage> createState() => _EnhancedReadingTaskPageState();
}

class _EnhancedReadingTaskPageState extends State<EnhancedReadingTaskPage> {
  final supabase = Supabase.instance.client;
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  bool isLoading = true;
  bool isRecording = false;
  bool hasRecording = false;
  String? recordingPath;
  
  int attemptsLeft = 3;
  bool completed = false;
  int currentAttempt = 1;

  @override
  void initState() {
    super.initState();
    _loadTaskData();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadTaskData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Load progress
      final progressRes = await supabase
          .from('student_task_progress')
          .select('attempts_left, completed')
          .eq('student_id', user.id)
          .eq('task_id', widget.task['id'])
          .maybeSingle();

      if (progressRes != null) {
        attemptsLeft = progressRes['attempts_left'] ?? 3;
        completed = progressRes['completed'] ?? false;
        currentAttempt = 4 - attemptsLeft;
      }
    } catch (e) {
      debugPrint('Error loading task data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _startRecording() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/reading_${user.id}_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(const RecordConfig(), path: filePath);

      setState(() {
        isRecording = true;
        recordingPath = filePath;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎤 Recording started...')),
      );
    } catch (e) {
      debugPrint('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      setState(() {
        isRecording = false;
        hasRecording = path != null;
        if (hasRecording) {
          recordingPath = path;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hasRecording ? '✅ Recording saved!' : 'Failed to save recording')),
      );
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _uploadAndSubmit() async {
    if (attemptsLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ No attempts left')),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Upload recording if exists
      if (recordingPath != null && File(recordingPath!).existsSync()) {
        try {
          final file = File(recordingPath!);
          final fileName = 'reading_${user.id}_${DateTime.now().millisecondsSinceEpoch}.m4a';
          final storagePath = 'student_voice/$fileName';

          await supabase.storage
              .from('student_voice')
              .upload(storagePath, file);

          final audioUrl = supabase.storage
              .from('student_voice')
              .getPublicUrl(storagePath);
          
          debugPrint('✅ Recording uploaded: $audioUrl');
        } catch (e) {
          debugPrint('⚠️ Failed to upload recording: $e');
        }
      }

      // Update progress
      await supabase.from('student_task_progress').upsert({
        'student_id': user.id,
        'task_id': widget.task['id'],
        'attempts_left': attemptsLeft - 1,
        'completed': false,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      
      // Navigate to quiz
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComprehensionQuizPage(
            studentId: user.id,
            storyId: widget.task['id'],
            levelId: widget.task['reading_level_id'] ?? '',
          ),
        ),
      ).then((_) => Navigator.pop(context));
    } catch (e) {
      debugPrint('Error uploading: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task['title'] ?? 'Reading Task'),
        actions: [
          _buildAttemptsChip(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Description
            if (widget.task['description'] != null)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    widget.task['description']!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Reading Passage
            const Text(
              '📖 Reading Passage',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.task['passage_text'] ?? 'No passage available',
                  style: const TextStyle(fontSize: 18, height: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Voice Recording Section
            const Text(
              '🎤 Record Your Reading',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          isRecording ? Icons.fiber_manual_record : Icons.mic,
                          color: isRecording ? Colors.red : Colors.purple,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isRecording
                                ? '🎙️ Recording in progress...'
                                : hasRecording
                                    ? '✅ Recording saved'
                                    : 'Tap to record your reading',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isRecording ? Colors.red : Colors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isRecording ? _stopRecording : _startRecording,
                          icon: Icon(isRecording ? Icons.stop : Icons.mic),
                          label: Text(isRecording ? 'Stop' : 'Record'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRecording ? Colors.red : Colors.purple,
                            minimumSize: const Size(140, 48),
                          ),
                        ),
                        if (hasRecording)
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                hasRecording = false;
                                recordingPath = null;
                              });
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Clear'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              minimumSize: const Size(140, 48),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: attemptsLeft > 0
                    ? _uploadAndSubmit
                    : null,
                icon: const Icon(Icons.quiz),
                label: const Text('Continue to Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            if (attemptsLeft <= 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have used all attempts. Contact your teacher for support.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptsChip() {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: attemptsLeft > 0 ? Colors.orange.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: attemptsLeft > 0 ? Colors.orange : Colors.red,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.refresh,
            size: 16,
            color: attemptsLeft > 0 ? Colors.orange : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            '$attemptsLeft left',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: attemptsLeft > 0 ? Colors.orange.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
