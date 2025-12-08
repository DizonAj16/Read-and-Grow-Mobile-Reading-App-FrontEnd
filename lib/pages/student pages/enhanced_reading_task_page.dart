import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import '../../../utils/file_validator.dart';

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
  String? pdfUrl;
  String? localPdfPath;
  String? uploadedAudioUrl;

  int attemptsLeft = 3;
  bool completed = false;
  int currentAttempt = 1;

  // Audio preview
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingPreview = false;

  @override
  void initState() {
    super.initState();
    _loadTaskData();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadTaskData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Load progress and PDF material in parallel
      await Future.wait([
        _loadProgress(),
        _loadPDFMaterial(),
      ]);
    } catch (e) {
      debugPrint('Error loading task data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadProgress() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final progressRes = await supabase
          .from('student_task_progress')
          .select('attempts_left, completed')
          .eq('student_id', user.id)
          .eq('task_id', widget.task['id'])
          .maybeSingle();

      if (progressRes != null) {
        setState(() {
          attemptsLeft = progressRes['attempts_left'] ?? 3;
          completed = progressRes['completed'] ?? false;
          currentAttempt = 4 - attemptsLeft;
        });
      }
    } catch (e) {
      debugPrint('Error loading progress: $e');
    }
  }

  Future<void> _loadPDFMaterial() async {
    try {
      // Check if task has PDF in task_materials table
      final materialRes = await supabase
          .from('task_materials')
          .select('material_file_path, material_type')
          .eq('task_id', widget.task['id'])
          .eq('material_type', 'pdf')
          .maybeSingle();

      if (materialRes != null && materialRes['material_file_path'] != null) {
        final materialPath = materialRes['material_file_path'] as String;

        // Construct full PDF URL
        pdfUrl = materialPath;
        await _downloadPDF();
      }
    } catch (e) {
      debugPrint('Error loading PDF material: $e');
    }
  }

  Future<void> _downloadPDF() async {
    if (pdfUrl == null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/task_${widget.task['id']}.pdf';

      await Dio().download(pdfUrl!, filePath);
      setState(() {
        localPdfPath = filePath;
      });
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
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

  Future<void> _playRecordingPreview() async {
    if (recordingPath == null || !File(recordingPath!).existsSync()) return;

    try {
      setState(() => _isPlayingPreview = true);
      await _audioPlayer.setFilePath(recordingPath!);
      await _audioPlayer.play();

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() => _isPlayingPreview = false);
        }
      });
    } catch (e) {
      debugPrint('Error playing preview: $e');
      setState(() => _isPlayingPreview = false);
    }
  }

  Future<void> _stopPreview() async {
    await _audioPlayer.stop();
    setState(() => _isPlayingPreview = false);
  }

  Future<void> _uploadAndSubmit() async {
    if (attemptsLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ No attempts left')),
      );
      return;
    }

    if (!hasRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record your reading first')),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      setState(() => isLoading = true);

      // Upload recording if exists
      if (recordingPath != null && File(recordingPath!).existsSync()) {
        try {
          final file = File(recordingPath!);
          
          // Backend validation: Check file size
          final sizeValidation = await validateFileSize(file);
          if (!sizeValidation.isValid) {
            debugPrint('❌ [UPLOAD_RECORDING] File size validation failed: ${sizeValidation.getDetailedInfo()}');
            setState(() => isLoading = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(sizeValidation.getUserMessage()),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          final fileName = 'reading_task_${user.id}_${widget.task['id']}_${DateTime.now().millisecondsSinceEpoch}.m4a';
          final storagePath = 'student_voice/$fileName';

          await supabase.storage
              .from('student_voice')
              .upload(storagePath, file);

          uploadedAudioUrl = supabase.storage
              .from('student_voice')
              .getPublicUrl(storagePath);

          debugPrint('✅ Recording uploaded: $uploadedAudioUrl');

          // Store recording reference in database
          await supabase.from('student_recordings').insert({
            'student_id': user.id,
            'task_id': widget.task['id'],
            'recording_url': uploadedAudioUrl,
            'recorded_at': DateTime.now().toIso8601String(),
            'needs_grading': true,
          });
        } catch (e) {
          debugPrint('⚠️ Failed to upload recording: $e');
          setState(() => isLoading = false);
          if (mounted) {
            String errorMessage = 'Upload failed: $e';
            if (e is FileSizeLimitException) {
              errorMessage = e.message;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Update progress - mark as completed after successful recording
      await supabase.from('student_task_progress').upsert({
        'student_id': user.id,
        'task_id': widget.task['id'],
        'attempts_left': attemptsLeft - 1,
        'completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      setState(() => isLoading = false);
      setState(() => completed = true);

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Recording saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate back to previous page after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      debugPrint('Error uploading: $e');
      setState(() => isLoading = false);
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

            // Reading Passage - PDF or Text
            const Text(
              '📖 Reading Material',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (localPdfPath != null && pdfUrl != null)
              // Show PDF viewer
              Container(
                height: 500,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SfPdfViewer.file(File(localPdfPath!)),
                ),
              )
            else if (widget.task['passage_text'] != null)
              // Show text passage as fallback
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    widget.task['passage_text']!,
                    style: const TextStyle(fontSize: 18, height: 1.5),
                  ),
                ),
              )
            else
              Card(
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No reading material available',
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
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
                            minimumSize: const Size(120, 48),
                          ),
                        ),
                        if (hasRecording)
                          ElevatedButton.icon(
                            onPressed: _isPlayingPreview ? _stopPreview : _playRecordingPreview,
                            icon: Icon(_isPlayingPreview ? Icons.pause : Icons.play_arrow),
                            label: Text(_isPlayingPreview ? 'Pause' : 'Preview'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size(120, 48),
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
                              minimumSize: const Size(120, 48),
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
                onPressed: attemptsLeft > 0 && hasRecording
                    ? _uploadAndSubmit
                    : null,
                icon: const Icon(Icons.save),
                label: const Text('Save Recording'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
