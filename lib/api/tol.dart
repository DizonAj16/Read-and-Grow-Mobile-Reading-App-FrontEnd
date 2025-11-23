import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';


Future<List<void>> getReadingLevels() async {
  try {
    final supabase = Supabase.instance.client;

    final response = await supabase.from('reading_levels').select();

    final List<dynamic> list = response ?? [];
    return list
        .map((json) => Student.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  } catch (e) {
    print('Error fetching all reading levels: $e');
    throw Exception('Failed to fetch levels');
  }
}

class StudentVoiceAssessmentPage extends StatefulWidget {
  final Student student;
  final String? profileUrl;
  final ColorScheme colorScheme;
  final String recordingFilePath;
  final String assignmentId;

  const StudentVoiceAssessmentPage({
    Key? key,
    required this.student,
    required this.profileUrl,
    required this.colorScheme,
    required this.recordingFilePath,
    required this.assignmentId,
  }) : super(key: key);

  @override
  _StudentVoiceAssessmentPageState createState() =>
      _StudentVoiceAssessmentPageState();
}

class _StudentVoiceAssessmentPageState
    extends State<StudentVoiceAssessmentPage> {
  late final AudioPlayer _audioPlayer;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _score = 0.0;
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    if (widget.recordingFilePath.isNotEmpty) {
      try {
        if (widget.recordingFilePath.startsWith('http')) {
          await _audioPlayer.setUrl(widget.recordingFilePath);
        } else {
          await _audioPlayer.setFilePath(widget.recordingFilePath);
        }
        _duration = _audioPlayer.duration ?? Duration.zero;

        _audioPlayer.positionStream.listen((pos) {
          setState(() {
            _position = pos;
          });
        });
      } catch (e) {
        debugPrint('Error loading audio: $e');
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _saveScore() async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.from('reading_levels').select();
      final List<dynamic> list = response ?? [];
      final matchedLevel = list
          .map((json) => Map<String, dynamic>.from(json))
          .firstWhere(
            (level) => (level['level_number'] as num).toDouble() == _score,
        orElse: () => {},
      );

      if (matchedLevel.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No matching reading level found.')),
        );
        return;
      }

      final String levelId = matchedLevel['id'];

      await supabase.from('students').update({
        'current_reading_level_id': levelId,
      }).eq('id', widget.student.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Score saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving score: $e')),
      );
    }
  }

  Future<void> _submitRemarks() async {
    final supabase = Supabase.instance.client;
    if (_remarksController.text.trim().isEmpty) return;
    try {
      await supabase.from('student_submissions').insert({
        'assignment_id': widget.assignmentId,
        'student_id': widget.student.id,
        'attempt_number': 0,
        'score': null,
        'teacher_feedback': _remarksController.text.trim(),
        'submitted_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remarks submitted successfully!')),
      );

      _remarksController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting remarks: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.studentName} - Voice Assessment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: widget.profileUrl != null
                  ? NetworkImage(widget.profileUrl!)
                  : null,
              child: widget.profileUrl == null
                  ? Text(widget.student.avatarLetter)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(widget.student.studentName,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),

            if (widget.recordingFilePath.isNotEmpty) ...[
              Slider(
                value: _position.inMilliseconds.toDouble(),
                max: _duration.inMilliseconds.toDouble(),
                onChanged: (value) {
                  _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position)),
                  Text(_formatDuration(_duration)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => _audioPlayer.play(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.pause),
                    onPressed: () => _audioPlayer.pause(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: () => _audioPlayer.stop(),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Score:'),
                Expanded(
                  child: Slider(
                    value: _score,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _score.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _score = value;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Teacher Remarks:'),
                const SizedBox(height: 8),
                TextField(
                  controller: _remarksController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Leave feedback or assign remedial tasks...',
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    await _saveScore();
                    await _submitRemarks();
                  },
                  child: const Text('Save Score & Submit Remarks'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
