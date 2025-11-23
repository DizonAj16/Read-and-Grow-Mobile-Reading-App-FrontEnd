import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import '../../api/reading_materials_service.dart';

class EnhancedReadingMaterialPage extends StatefulWidget {
  final Map<String, dynamic> material;

  const EnhancedReadingMaterialPage({super.key, required this.material});

  @override
  State<EnhancedReadingMaterialPage> createState() => _EnhancedReadingMaterialPageState();
}

class _EnhancedReadingMaterialPageState extends State<EnhancedReadingMaterialPage> {
  final supabase = Supabase.instance.client;
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool isLoading = true;
  bool isRecording = false;
  bool hasRecording = false;
  String? recordingPath;
  String? pdfUrl;
  String? localPdfPath;
  bool isSubmitting = false;
  bool isSubmitted = false;

  // Audio preview
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingPreview = false;

  @override
  void initState() {
    super.initState();
    _loadMaterialData();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadMaterialData() async {
    try {
      // Get PDF URL from material
      pdfUrl = widget.material['file_url'] as String?;
      
      // Check if student has already submitted
      final user = supabase.auth.currentUser;
      if (user != null) {
        final submission = await ReadingMaterialsService.getStudentSubmission(
          studentId: user.id,
          materialId: widget.material['id'] as String,
        );
        
        if (submission != null) {
          setState(() {
            isSubmitted = true;
          });
        }
      }

      if (pdfUrl != null && pdfUrl!.isNotEmpty) {
        await _downloadPDF();
      }
    } catch (e) {
      debugPrint('Error loading material data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _downloadPDF() async {
    if (pdfUrl == null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final materialId = widget.material['id'] as String? ?? 'material';
      final filePath = '${dir.path}/material_$materialId.pdf';

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final materialId = widget.material['id'] as String? ?? 'material';
      final filePath = '${dir.path}/reading_${user.id}_${materialId}_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(const RecordConfig(), path: filePath);

      setState(() {
        isRecording = true;
        recordingPath = filePath;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎤 Recording started...')),
        );
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(hasRecording ? '✅ Recording saved!' : 'Failed to save recording')),
        );
      }
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

  Future<void> _submitRecording() async {
    if (!hasRecording || recordingPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please record your reading first')),
        );
      }
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to submit recordings')),
        );
      }
      return;
    }

    final materialId = widget.material['id'] as String?;
    if (materialId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid material ID')),
        );
      }
      return;
    }

    // Verify file exists
    final recordingFile = File(recordingPath!);
    if (!await recordingFile.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording file not found. Please record again.')),
        );
      }
      setState(() {
        hasRecording = false;
        recordingPath = null;
      });
      return;
    }

    try {
      setState(() => isSubmitting = true);

      // Submit using ReadingMaterialsService
      final result = await ReadingMaterialsService.submitReadingRecording(
        studentId: user.id,
        materialId: materialId,
        recordingFilePath: recordingPath!,
      );

      if (result != null && result.containsKey('error')) {
        throw Exception(result['error']);
      }

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
        hasRecording = false;
        recordingPath = null;
        isSubmitted = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Recording submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      debugPrint('Error submitting recording: $e');
      setState(() => isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting: ${e.toString()}'),
            backgroundColor: Colors.red,
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
        title: Text(widget.material['title'] ?? 'Reading Material'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Material Description
            if (widget.material['description'] != null && 
                widget.material['description'].toString().isNotEmpty)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    widget.material['description'],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Reading Material - PDF
            const Text(
              '📖 Reading Material',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (localPdfPath != null && File(localPdfPath!).existsSync())
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
            else if (pdfUrl != null && pdfUrl!.isNotEmpty)
              // Show loading or network PDF
              Container(
                height: 500,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SfPdfViewer.network(
                    pdfUrl!,
                    onDocumentLoadFailed: (details) {
                      debugPrint('PDF load failed: ${details.error}');
                    },
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

            // Submission Status
            if (isSubmitted)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 32),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Recording submitted successfully!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
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
                  onPressed: hasRecording && !isSubmitting
                      ? _submitRecording
                      : null,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(isSubmitting ? 'Submitting...' : 'Submit Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

