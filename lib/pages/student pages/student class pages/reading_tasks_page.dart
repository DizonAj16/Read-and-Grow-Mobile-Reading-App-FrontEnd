import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/validators.dart';
import '../../../utils/database_helpers.dart';

class ReadingTaskPage extends StatefulWidget {
  final Map<String, dynamic> task;
  const ReadingTaskPage({super.key, required this.task});

  @override
  State<ReadingTaskPage> createState() => _ReadingTaskPageState();
}

class _ReadingTaskPageState extends State<ReadingTaskPage> {
  final supabase = Supabase.instance.client;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  int attemptsLeft = 3;
  bool completed = false;
  bool isLoading = true;
  
  // Materials list
  List<Map<String, dynamic>> _materials = [];
  
  // Recording state per material
  Map<String, MaterialRecordingState> _recordingStates = {};

  @override
  void initState() {
    super.initState();
    _initTask();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    // Stop all active recordings
    for (var state in _recordingStates.values) {
      if (state.isRecording) {
        _audioRecorder.stop();
      }
    }
    super.dispose();
  }

  Future<void> _initTask() async {
    try {
      // Validate task data
      final taskId = widget.task['id'] as String?;
      if (taskId == null || !Validators.isValidUUID(taskId)) {
        throw Exception('Invalid task ID');
      }

      await Future.wait([_loadProgress(), _loadMaterials()]);
    } catch (e) {
      debugPrint('Error initializing task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// ✅ Load attempts/completion progress
  Future<void> _loadProgress() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final taskId = widget.task['id'] as String?;
    if (taskId == null || !Validators.isValidUUID(taskId)) {
      debugPrint('Invalid task ID in _loadProgress');
      return;
    }

    try {
      final res = await DatabaseHelpers.safeGetSingle(
        supabase: supabase,
        table: 'student_task_progress',
        filters: {
          'student_id': user.id,
          'task_id': taskId,
        },
      );

      if (res != null && mounted) {
        setState(() {
          attemptsLeft = DatabaseHelpers.safeIntFromResult(res, 'attempts_left', defaultValue: 3);
          completed = DatabaseHelpers.safeBoolFromResult(res, 'completed', defaultValue: false);
        });
      }
    } catch (e) {
      debugPrint('Error loading progress: $e');
      // Use default values on error
      if (mounted) {
        setState(() {
          attemptsLeft = 3;
          completed = false;
        });
      }
    }
  }

  /// ✅ Load all materials for this task
  Future<void> _loadMaterials() async {
    try {
      final taskId = widget.task['id'] as String?;
      if (taskId == null || !Validators.isValidUUID(taskId)) {
        debugPrint('Invalid task ID in _loadMaterials');
        return;
      }

      // Try task_materials table first
      List<Map<String, dynamic>> materials = [];
      
      final taskMaterialsRes = await DatabaseHelpers.safeGetList(
        supabase: supabase,
        table: 'task_materials',
        filters: {
          'task_id': taskId,
          'material_type': 'pdf',
        },
      );

      if (taskMaterialsRes.isNotEmpty) {
        for (var material in taskMaterialsRes) {
          final materialId = DatabaseHelpers.safeStringFromResult(
            material,
            'id',
            defaultValue: DateTime.now().millisecondsSinceEpoch.toString(),
          );
          final filePath = DatabaseHelpers.safeStringFromResult(material, 'material_file_path');
          
          if (filePath.isNotEmpty) {
            try {
              // Construct PDF URL
              // Using 'materials' bucket as per user's Supabase storage setup
              final pdfUrl = supabase.storage.from('materials').getPublicUrl(filePath);
              
              if (pdfUrl.isNotEmpty) {
                materials.add({
                  'id': materialId,
                  'title': DatabaseHelpers.safeStringFromResult(
                    material,
                    'material_title',
                    defaultValue: 'Reading Material',
                  ),
                  'file_path': filePath,
                  'url': pdfUrl,
                  'type': 'pdf',
                });
                
                // Initialize recording state for this material
                _recordingStates[materialId] = MaterialRecordingState();
              }
            } catch (e) {
              debugPrint('Error constructing PDF URL for material $materialId: $e');
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _materials = materials;
        });
      }

      // Download PDFs with error handling
      for (var material in materials) {
        try {
          await _downloadPdf(material);
        } catch (e) {
          debugPrint('Error downloading PDF for ${material['title']}: $e');
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error loading materials: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading materials: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// ✅ Download PDF for local rendering
  Future<void> _downloadPdf(Map<String, dynamic> material) async {
    final url = material['url'] as String?;
    if (url == null || url.isEmpty) {
      debugPrint('Invalid PDF URL');
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final materialId = material['id'] as String?;
      if (materialId == null || materialId.isEmpty) {
        debugPrint('Invalid material ID');
        return;
      }

      final filePath = "${dir.path}/material_${materialId}.pdf";

      // Validate URL before downloading
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        throw Exception('Invalid URL format');
      }

      await Dio().download(url, filePath);
      
      // Verify file exists after download
      final file = File(filePath);
      if (await file.exists()) {
        if (mounted) {
          setState(() {
            material['local_path'] = filePath;
          });
        }
      } else {
        throw Exception('File download failed');
      }
    } catch (e) {
      debugPrint("⚠️ Failed to download PDF for ${material['title']}: $e");
      if (mounted) {
        setState(() {
          material['local_path'] = null;
        });
      }
    }
  }

  /// ✅ Start recording for a specific material
  Future<void> _startRecording(String materialId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/reading_${user.id}_${materialId}_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(const RecordConfig(), path: filePath);

      setState(() {
        final state = _recordingStates[materialId];
        if (state != null) {
          state.isRecording = true;
          state.recordingPath = filePath;
          state.hasRecording = false;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.mic, color: Colors.white),
                SizedBox(width: 10),
                Text('🎤 Recording started...'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ✅ Stop recording for a specific material
  Future<void> _stopRecording(String materialId) async {
    try {
      final path = await _audioRecorder.stop();

      setState(() {
        final state = _recordingStates[materialId];
        if (state != null) {
          state.isRecording = false;
          state.hasRecording = path != null;
          if (path != null) {
            state.recordingPath = path;
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  path != null ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(path != null ? '✅ Recording saved!' : 'Failed to save recording'),
              ],
            ),
            backgroundColor: path != null ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  /// ✅ Preview recording
  Future<void> _playPreview(String materialId) async {
    final state = _recordingStates[materialId];
    if (state?.recordingPath == null || !File(state!.recordingPath!).existsSync()) return;

    try {
      setState(() {
        state.isPlayingPreview = true;
      });

      await _audioPlayer.setFilePath(state.recordingPath!);
      await _audioPlayer.play();

      _audioPlayer.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() {
              state.isPlayingPreview = false;
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Error playing preview: $e');
      if (mounted) {
        setState(() {
          state.isPlayingPreview = false;
        });
      }
    }
  }

  /// ✅ Stop preview
  Future<void> _stopPreview(String materialId) async {
    await _audioPlayer.stop();
    final state = _recordingStates[materialId];
    if (state != null && mounted) {
      setState(() {
        state.isPlayingPreview = false;
      });
    }
  }

  /// ✅ Upload and submit recording
  Future<void> _submitRecording(String materialId, Map<String, dynamic> material) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to submit recordings'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final taskId = widget.task['id'] as String?;
    if (taskId == null || !Validators.isValidUUID(taskId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid task ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final state = _recordingStates[materialId];
    if (state == null || !state.hasRecording || state.recordingPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please record your reading first'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Verify file exists
    final recordingFile = File(state.recordingPath!);
    if (!await recordingFile.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording file not found. Please record again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        state.hasRecording = false;
        state.recordingPath = null;
      });
      return;
    }

    if (attemptsLeft <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ No attempts left'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          state.isUploading = true;
        });
      }

      // Validate file size (max 10MB)
      final fileSize = await recordingFile.length();
      final maxSize = 10 * 1024 * 1024; // 10MB
      final sizeError = Validators.validateFileSize(fileSize, maxSize);
      if (sizeError != null) {
        throw Exception(sizeError);
      }

      // Upload recording to Supabase Storage
      final fileName = 'reading_task_${user.id}_${taskId}_${materialId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storagePath = 'student_voice/$fileName';

      await supabase.storage
          .from('student_voice')
          .upload(storagePath, recordingFile);

      final uploadedUrl = supabase.storage
          .from('student_voice')
          .getPublicUrl(storagePath);

      if (uploadedUrl.isEmpty) {
        throw Exception('Failed to get uploaded file URL');
      }

      // Validate recording data before insert
      final recordingData = {
        'student_id': user.id,
        'task_id': taskId,
        'recording_url': uploadedUrl,
        'file_url': uploadedUrl,
        'recorded_at': DateTime.now().toIso8601String(),
        'needs_grading': true,
      };

      // Insert record into student_recordings
      final insertResult = await DatabaseHelpers.safeInsert(
        supabase: supabase,
        table: 'student_recordings',
        data: recordingData,
      );

      if (insertResult != null && insertResult.containsKey('error')) {
        throw Exception(insertResult['error']);
      }

      // Update progress (decrement attempts) - use upsert to handle insert or update
      await supabase.from('student_task_progress').upsert({
        'student_id': user.id,
        'task_id': taskId,
        'attempts_left': attemptsLeft - 1,
        'completed': false,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          attemptsLeft = attemptsLeft - 1;
          state.isUploading = false;
          state.hasRecording = false;
          state.recordingPath = null;
          state.isSubmitted = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text('✅ Recording submitted successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting recording: $e');
      if (mounted) {
        setState(() {
          state.isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Error submitting: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
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
          Container(
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
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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

            // Reading Materials Section
            if (_materials.isNotEmpty) ...[
              const Text(
                '📚 Reading Materials',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._materials.map((material) => _buildMaterialCard(material)),
              const SizedBox(height: 20),
            ],

            // Fallback to passage_text if no materials
            if (_materials.isEmpty && widget.task['passage_text'] != null) ...[
              const Text(
                '📖 Reading Passage',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    widget.task['passage_text']!,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Note: Quizzes are removed from reading tasks
            // Reading tasks are only for PDF reading and voice recording
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material) {
    final materialId = material['id'] as String;
    final title = material['title'] as String;
    final localPath = material['local_path'] as String?;
    final state = _recordingStates[materialId];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (state?.isSubmitted == true)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
        subtitle: state?.isSubmitted == true
            ? const Text('Recording submitted', style: TextStyle(color: Colors.green))
            : null,
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // PDF Viewer
                if (localPath != null && File(localPath).existsSync())
                  Container(
                    height: 500,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SfPdfViewer.file(File(localPath)),
                    ),
                  )
                else
                  Container(
                    height: 500,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading PDF...'),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Recording Section
                if (state?.isSubmitted != true) ...[
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    '🎤 Record Your Reading',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                                state?.isRecording == true
                                    ? Icons.fiber_manual_record
                                    : Icons.mic,
                                color: state?.isRecording == true
                                    ? Colors.red
                                    : Colors.purple,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  state?.isRecording == true
                                      ? '🎙️ Recording in progress...'
                                      : state?.hasRecording == true
                                          ? '✅ Recording saved'
                                          : 'Tap to record your reading',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: state?.isRecording == true
                                        ? Colors.red
                                        : Colors.purple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: state?.isUploading == true
                                    ? null
                                    : state?.isRecording == true
                                        ? () => _stopRecording(materialId)
                                        : () => _startRecording(materialId),
                                icon: Icon(
                                  state?.isRecording == true ? Icons.stop : Icons.mic,
                                ),
                                label: Text(
                                  state?.isRecording == true ? 'Stop' : 'Record',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: state?.isRecording == true
                                      ? Colors.red
                                      : Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              if (state?.hasRecording == true) ...[
                                ElevatedButton.icon(
                                  onPressed: state?.isPlayingPreview == true
                                      ? () => _stopPreview(materialId)
                                      : () => _playPreview(materialId),
                                  icon: Icon(
                                    state?.isPlayingPreview == true
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                  ),
                                  label: const Text('Preview'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      if (state != null) {
                                        state.hasRecording = false;
                                        state.recordingPath = null;
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Clear'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: state?.isUploading == true ||
                                      state?.hasRecording != true
                                  ? null
                                  : () => _submitRecording(materialId, material),
                              icon: state?.isUploading == true
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.upload),
                              label: Text(
                                state?.isUploading == true
                                    ? 'Uploading...'
                                    : 'Submit Recording',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class to manage recording state per material
class MaterialRecordingState {
  bool isRecording = false;
  bool hasRecording = false;
  bool isPlayingPreview = false;
  bool isUploading = false;
  bool isSubmitted = false;
  String? recordingPath;
}
