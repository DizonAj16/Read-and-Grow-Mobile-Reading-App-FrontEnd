import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';

class ReadingRecordingsGradingPage extends StatefulWidget {
  const ReadingRecordingsGradingPage({super.key});

  @override
  State<ReadingRecordingsGradingPage> createState() =>
      _ReadingRecordingsGradingPageState();
}

class _ReadingRecordingsGradingPageState
    extends State<ReadingRecordingsGradingPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> recordings = [];
  Map<String, String> studentNames = {};
  Map<String, Map<String, dynamic>> taskDetails = {};

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    setState(() => isLoading = true);

    try {
      final recordingsRes = await supabase
          .from('student_recordings')
          .select('*')
          .eq('needs_grading', true)
          .order('recorded_at', ascending: false);

      setState(() {
        recordings = List<Map<String, dynamic>>.from(recordingsRes);
      });

      final studentIds = recordings
          .map((r) => r['student_id'])
          .where((id) => id != null)
          .toSet()
          .toList();

      final taskIds = recordings
          .map((r) => r['task_id'])
          .where((id) => id != null)
          .toSet()
          .toList();

      if (studentIds.isNotEmpty) {
        final studentsRes = await supabase
            .from('students')
            .select('id, student_name')
            .inFilter('id', studentIds);

        for (var student in studentsRes) {
          final uid = student['id']?.toString();
          if (uid != null) {
            studentNames[uid] = student['student_name']?.toString() ?? 'Unknown';
          }
        }
      }

      if (taskIds.isNotEmpty) {
        final tasksRes = await supabase
            .from('tasks')
            .select('id, title, description')
            .inFilter('id', taskIds);

        for (var task in tasksRes) {
          final tid = task['id']?.toString();
          if (tid != null) {
            taskDetails[tid] = Map<String, dynamic>.from(task);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading recordings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recordings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 Grade Reading Recordings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecordings,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recordings.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 80, color: Colors.green[400]),
            const SizedBox(height: 16),
            Text(
              'All recordings have been graded!',
              style:
              TextStyle(color: Colors.green[700], fontSize: 18),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadRecordings,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recordings.length,
          itemBuilder: (context, index) =>
              _buildRecordingCard(recordings[index]),
        ),
      ),
    );
  }

  Widget _buildRecordingCard(Map<String, dynamic> recording) {
    final studentId = recording['student_id']?.toString() ?? '';
    final taskId = recording['task_id']?.toString() ?? '';
    final studentName = studentNames[studentId] ?? 'Unknown Student';
    final task = taskDetails[taskId];
    final taskTitle = task?['title']?.toString() ?? 'Unknown Task';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: InkWell(
        onTap: () => _showGradingDialog(recording, studentName, taskTitle, task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.purple.shade200,
                    child: Text(
                      studentName.isNotEmpty
                          ? studentName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          taskTitle,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic,
                            size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Need Grading',
                          style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(recording['recorded_at']?.toString()),
                    style:
                    TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return 'Unknown';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Invalid date';
    }
  }

  void _showGradingDialog(
      Map<String, dynamic> recording,
      String studentName,
      String taskTitle,
      Map<String, dynamic>? task,
      ) {
    showDialog(
      context: context,
      builder: (context) => _GradingDialog(
        recording: recording,
        studentName: studentName,
        taskTitle: taskTitle,
        task: task,
        onGraded: () {
          Navigator.pop(context);
          _loadRecordings();
        },
      ),
    );
  }
}

class _GradingDialog extends StatefulWidget {
  final Map<String, dynamic> recording;
  final String studentName;
  final String taskTitle;
  final Map<String, dynamic>? task;
  final VoidCallback onGraded;

  const _GradingDialog({
    required this.recording,
    required this.studentName,
    required this.taskTitle,
    required this.onGraded,
    this.task,
  });

  @override
  State<_GradingDialog> createState() => _GradingDialogState();
}

class _GradingDialogState extends State<_GradingDialog> {
  final supabase = Supabase.instance.client;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _commentsController = TextEditingController();

  double _score = 5.0;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    final recordingUrl = widget.recording['recording_url']?.toString() ??
        widget.recording['file_url']?.toString() ??
        '';
    if (recordingUrl.isEmpty) return;

    try {
      await _audioPlayer.setUrl(recordingUrl);
      _duration = _audioPlayer.duration ?? Duration.zero;

      _audioPlayer.positionStream.listen((pos) {
        if (mounted) {
          setState(() {
            _position = pos;
            if (_position > _duration) _position = _duration;
          });
        }
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) setState(() => _isPlaying = false);
        }
      });
    } catch (e) {
      debugPrint('Error loading audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading audio: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _saveGrade() async {
    setState(() => _isLoading = true);
    try {
      await supabase
          .from('student_recordings')
          .update({
        'score': _score,
        'teacher_comments': _commentsController.text.trim(),
        'needs_grading': false,
        'graded_at': DateTime.now().toIso8601String(),
      })
          .eq('id', widget.recording['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Grade saved successfully!'),
          backgroundColor: Colors.green,
        ));
        widget.onGraded();
      }
    } catch (e) {
      debugPrint('Error saving grade: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving grade: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _position.inMilliseconds.toDouble();
    final max = _duration.inMilliseconds.toDouble();
    final clampedValue = current.clamp(0.0, max > 0 ? max : 1.0);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.purple.shade200,
                    child: Text(
                      widget.studentName.isNotEmpty
                          ? widget.studentName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.studentName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          widget.taskTitle,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[700]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎤 Recording Playback',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Slider(
                            value: clampedValue,
                            max: max > 0 ? max : 1.0,
                            onChanged: (value) {
                              _audioPlayer.seek(
                                  Duration(milliseconds: value.toInt()));
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(_position)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(_isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow),
                                    onPressed: () async {
                                      if (_isPlaying) {
                                        await _audioPlayer.pause();
                                        setState(() => _isPlaying = false);
                                      } else {
                                        await _audioPlayer.play();
                                        setState(() => _isPlaying = true);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.stop),
                                    onPressed: () async {
                                      await _audioPlayer.stop();
                                      setState(() => _isPlaying = false);
                                    },
                                  ),
                                ],
                              ),
                              Text(_formatDuration(_duration)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('📊 Score',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Score: '),
                        Expanded(
                          child: Slider(
                            value: _score,
                            min: 0,
                            max: 10,
                            divisions: 20,
                            label: _score.toStringAsFixed(1),
                            onChanged: (value) {
                              setState(() => _score = value);
                            },
                          ),
                        ),
                        Container(
                          width: 50,
                          alignment: Alignment.centerRight,
                          child: Text(
                            _score.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('💬 Teacher Comments',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentsController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                        'Provide feedback on pronunciation, pace, expression...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveGrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white)),
                      )
                          : const Text('Save Grade'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
