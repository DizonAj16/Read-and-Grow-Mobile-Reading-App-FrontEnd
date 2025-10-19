import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../comprehension_and_quiz.dart';

class ReadingTaskPage extends StatefulWidget {
  final Map<String, dynamic> task;
  const ReadingTaskPage({super.key, required this.task});

  @override
  State<ReadingTaskPage> createState() => _ReadingTaskPageState();
}

class _ReadingTaskPageState extends State<ReadingTaskPage> {
  final supabase = Supabase.instance.client;
  int attemptsLeft = 3;
  bool completed = false;
  bool isLoading = true;
  String? pdfUrl; // <-- store PDF link
  String? localPdfPath; // <-- store local file for PDFView

  @override
  void initState() {
    super.initState();
    _initTask();
  }

  Future<void> _initTask() async {
    await Future.wait([_loadProgress(), _loadTaskMaterial()]);
    setState(() => isLoading = false);
  }

  /// ✅ Load attempts/completion progress
  Future<void> _loadProgress() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final res = await supabase
        .from('student_task_progress')
        .select('attempts_left, completed')
        .eq('student_id', user.id)
        .eq('task_id', widget.task['id'])
        .maybeSingle();

    if (res != null) {
      attemptsLeft = res['attempts_left'] ?? 3;
      completed = res['completed'] ?? false;
    }
  }

  /// ✅ Load PDF material (if any)
  Future<void> _loadTaskMaterial() async {
    try {
      final res = await supabase
          .from('task_materials')
          .select('material_file_path, material_type')
          .eq('task_id', widget.task['id'])
          .eq('material_type', 'pdf')
          .maybeSingle();

      if (res != null && res['material_file_path'] != null) {
        pdfUrl =
        "https://<YOUR_SUPABASE_PROJECT>.supabase.co/storage/v1/object/public/content-files/${res['material_file_path']}";
        await _downloadPdf();
      }
    } catch (e) {
      debugPrint("⚠️ Error loading PDF: $e");
    }
  }

  /// ✅ Download PDF for local rendering
  Future<void> _downloadPdf() async {
    if (pdfUrl == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/${widget.task['id']}.pdf";

    try {
      await Dio().download(pdfUrl!, filePath);
      localPdfPath = filePath;
    } catch (e) {
      debugPrint("⚠️ Failed to download PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.task['title'] ?? 'Reading Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(widget.task['description'] ?? '',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            if (localPdfPath != null) ...[
              Text("📄 Reading Material (PDF)",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700)),
              const SizedBox(height: 10),
              SizedBox(
                height: 500,
                child: PDFView(
                  filePath: localPdfPath!,
                  enableSwipe: true,
                  swipeHorizontal: true,
                ),
              ),
            ] else ...[
              Text(widget.task['passage_text'] ?? '',
                  style:
                  const TextStyle(fontSize: 18, height: 1.4, color: Colors.black87)),
            ],

            const SizedBox(height: 30),
            _buildAttemptsSection(),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: attemptsLeft > 0
                  ? () {
                final user = supabase.auth.currentUser;
                if (user == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComprehensionQuizPage(
                      studentId: user.id,
                      storyId: widget.task['id'],
                      levelId: widget.task['level_id'],
                    ),
                  ),
                );
              }
                  : null,
              icon: const Icon(Icons.quiz_rounded),
              label: const Text("Take Comprehension Quiz"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Attempts Left: $attemptsLeft",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          completed
              ? const Icon(Icons.verified, color: Colors.green)
              : const Icon(Icons.pending_actions, color: Colors.orange),
        ],
      ),
    );
  }
}
