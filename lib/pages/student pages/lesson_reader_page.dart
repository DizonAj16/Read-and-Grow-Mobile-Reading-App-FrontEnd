import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deped_reading_app_laravel/api/comprehension_quiz_service.dart';
import 'package:deped_reading_app_laravel/pages/student%20pages/student_quiz_pages.dart';

class LessonReaderPage extends StatefulWidget {
  final String taskId;
  final String assignmentId;
  final String classRoomId;
  final String quizId;
  final String studentId;
  final String lessonTitle;

  const LessonReaderPage({
    super.key,
    required this.taskId,
    required this.assignmentId,
    required this.classRoomId,
    required this.quizId,
    required this.studentId,
    required this.lessonTitle,
  });

  @override
  State<LessonReaderPage> createState() => _LessonReaderPageState();
}

class _LessonReaderPageState extends State<LessonReaderPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ComprehensionQuizService _quizService = ComprehensionQuizService();

  bool _isLoading = true;
  bool _isCompleting = false;
  String? _pdfUrl;
  int? _materialId; // bigint id from materials table
  String? _materialDescription;

  @override
  void initState() {
    super.initState();
    _loadMaterial();
  }

  Future<void> _loadMaterial() async {
    try {
      final materialRes = await _supabase
          .from('task_materials')
          .select('material_title, description, material_file_path')
          .eq('task_id', widget.taskId)
          .eq('material_type', 'pdf')
          .maybeSingle();

      if (materialRes != null) {
        _materialDescription = materialRes['description'] as String?;
        final filePath = materialRes['material_file_path'] as String?;

        if (filePath != null && filePath.isNotEmpty) {
          final publicUrl =
              _supabase.storage.from('materials').getPublicUrl(filePath);

          if (publicUrl.isNotEmpty) {
            final materialRow = await _supabase
                .from('materials')
                .select('id')
                .eq('material_file_url', publicUrl)
                .eq('class_room_id', widget.classRoomId)
                .order('created_at', ascending: false)
                .maybeSingle();

            if (materialRow != null) {
              final dynamic idValue = materialRow['id'];
              if (idValue is int) {
                _materialId = idValue;
              } else if (idValue is num) {
                _materialId = idValue.toInt();
              }
            }

            setState(() {
              _pdfUrl = publicUrl;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading lesson material: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDoneReading() async {
    if (_isCompleting) return;

    setState(() => _isCompleting = true);

    try {
      if (_materialId != null) {
        await _quizService.completeLessonReading(
          studentId: widget.studentId,
          materialId: _materialId!,
          readingDurationSeconds: 0,
          pagesViewed: 0,
          lastPageViewed: 0,
        );
      }
    } catch (e) {
      debugPrint('Error completing lesson reading: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark lesson as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }

    await _openQuiz();
  }

  Future<void> _openQuiz() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentQuizPage(
          quizId: widget.quizId,
          assignmentId: widget.assignmentId,
          studentId: widget.studentId,
        ),
      ),
    );

    if (!mounted) return;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pdfUrl == null
              ? _buildNoMaterialView()
              : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SfPdfViewer.network(_pdfUrl!),
                        ),
                      ),
                    ),
                    if (_materialDescription != null &&
                        _materialDescription!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          _materialDescription!,
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _isCompleting
                ? null
                : () {
                    _handleDoneReading();
                  },
            icon: _isCompleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.quiz),
            label: Text(
              _pdfUrl == null
                  ? 'Proceed to Quiz'
                  : 'Done Reading • Take Quiz',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoMaterialView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No reading material was attached to this lesson.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can still proceed to the quiz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

