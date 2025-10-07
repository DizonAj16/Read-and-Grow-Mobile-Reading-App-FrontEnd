import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';



class ReadingActivityPage extends StatefulWidget {
  final String taskId;
  final String passageText;
  final Student student;
  final String? pdfUrl;

  const ReadingActivityPage({
    Key? key,
    required this.taskId,
    required this.passageText,
    required this.student,
    this.pdfUrl,
  }) : super(key: key);

  @override
  State<ReadingActivityPage> createState() => _ReadingActivityPageState();
}

class _ReadingActivityPageState extends State<ReadingActivityPage> {
  final supabase = Supabase.instance.client;
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isUploading = false;
  String? _recordedPath;
  String? _localPdfPath;

  @override
  void initState() {
    super.initState();
    if (widget.pdfUrl != null) _downloadPdf(widget.pdfUrl!);
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  /// ✅ Download PDF to local temp folder for PDFView
  Future<void> _downloadPdf(String pdfUrl) async {
    try {
      final response = await HttpClient().getUrl(Uri.parse(pdfUrl));
      final fileBytes = await (await response.close()).fold<List<int>>([], (a, b) => a..addAll(b));

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/reading_passage.pdf';
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      setState(() => _localPdfPath = filePath);
    } catch (e) {
      debugPrint('Error loading PDF: $e');
    }
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final user = supabase.auth.currentUser;

      if (user == null) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to record')),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/reading_${user.id}_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(const RecordConfig(), path: filePath);

      setState(() {
        _isRecording = true;
        _recordedPath = filePath;
      });
    }
  }
  Future<void> _stopRecording() async {
    if (!_isRecording) {
      debugPrint('Recorder is not running, skipping stop.');
      return;
    }

    try {
      final path = await _recorder.stop();
      debugPrint('Recording saved at $path');

      setState(() {
        _isRecording = false;
        _recordedPath = path ?? _recordedPath;
      });
    } catch (e) {
      debugPrint('Error stopping recorder: $e');
    }
  }
  Future<void> _uploadRecording() async {

    if (_recordedPath == null) return;
    setState(() => _isUploading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        Text('You must be logged in to upload');
        return;
      }
      print('hello ${user.id}');

      final file = File(_recordedPath!);
      final fileName = 'reading_${user.id}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storagePath = 'student_voice/$fileName';
      await supabase.storage.from('student_voice').upload(storagePath, file);
      final taskId = widget.taskId;
      final publicUrl = supabase.storage.from('student_voice').getPublicUrl(storagePath);
      print('hellooo ${publicUrl}');
      await supabase.from('student_recordings').insert({
        'student_id': user.id,
        'file_url': publicUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording uploaded successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Error uploading recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading Activity')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [


            Expanded(
              child: widget.pdfUrl != null
                  ? (_localPdfPath == null
                  ? const Center(child: CircularProgressIndicator())
                  : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PDFView(
                  filePath: _localPdfPath!,
                  onError: (error) => debugPrint('PDF Error: $error'),
                ),
              ))
                  : SingleChildScrollView(
                child: Text(
                  widget.passageText,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  backgroundColor: _isRecording ? Colors.red : Colors.green,
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  child: Icon(_isRecording ? Icons.stop : Icons.mic),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _uploadRecording,
                  icon: const Icon(Icons.upload),
                  label: Text('Upload Recordiddddddng'),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}
