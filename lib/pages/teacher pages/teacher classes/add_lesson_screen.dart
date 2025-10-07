import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../api/supabase_api_service.dart';
import 'add_quiz_screen.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class AddLessonScreen extends StatefulWidget {
  final String? readingLevelId;
  final String classRoomId;
  const AddLessonScreen({
    super.key,
    this.readingLevelId,
    required this.classRoomId,
  });

  @override
  State<AddLessonScreen> createState() => _AddLessonScreenState();
}

class _AddLessonScreenState extends State<AddLessonScreen> {
  final _lessonTitleController = TextEditingController();
  final _lessonDescController = TextEditingController();
  final _lessonTimeController = TextEditingController();
  bool _unlocksNextLevel = false;
  bool _isLoading = false;

  String? _uploadedFileUrl;
  String? _uploadedFileType;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp4', 'mp3', 'wav', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileExtension = file.path.split('.').last.toLowerCase();

      String? uploadedUrl = await ApiService.uploadFile(file);

      setState(() {
        _uploadedFileUrl = uploadedUrl;
        if (['jpg', 'jpeg', 'png'].contains(fileExtension)) {
          _uploadedFileType = 'image';
        } else if (fileExtension == 'pdf') {
          _uploadedFileType = 'pdf';
        } else if (['mp4'].contains(fileExtension)) {
          _uploadedFileType = 'video';
        } else {
          _uploadedFileType = 'audio';
        }
      });
    }
  }

  Future<void> _submitLesson() async {
    if (_lessonTitleController.text.isEmpty) return;

    setState(() => _isLoading = true);

    final lesson = await ApiService.addLesson(
      readingLevelId: widget.readingLevelId,
      title: _lessonTitleController.text,
      description: _lessonDescController.text,
      timeLimitMinutes: int.tryParse(_lessonTimeController.text),
      unlocksNextLevel: _unlocksNextLevel,
    );

    if (lesson == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to add lesson')));
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    final teacher = await Supabase.instance.client
        .from('teachers')
        .select('id')
        .eq('user_id', userId!)
        .maybeSingle();

    if (teacher == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher record not found')),
      );
      return;
    }

    final teacherId = teacher['id'];

    await Supabase.instance.client.from('assignments').insert({
      'class_room_id': widget.classRoomId,
      'task_id': lesson['id'],
      'teacher_id': teacherId,
    });

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Lesson added successfully!')));

    // Ask if they want to add a quiz
    final shouldAddQuiz = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Quiz?'),
        content: const Text('Do you want to add a quiz to this lesson?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldAddQuiz == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AddQuizScreen(lessonId: lesson['id']),
        ),
      );
    } else {
      Navigator.pop(context, lesson);
    }
  }

  Widget _buildFilePreview() {
    if (_uploadedFileUrl == null) return const SizedBox();

    switch (_uploadedFileType) {
      case 'image':
        return Image.network(_uploadedFileUrl!, height: 150);
      case 'pdf':
        return Row(
          children: [
            const Icon(Icons.picture_as_pdf),
            const SizedBox(width: 8),
            Expanded(child: Text(_uploadedFileUrl!)),
          ],
        );
      case 'video':
        return Row(
          children: [
            const Icon(Icons.videocam),
            const SizedBox(width: 8),
            Expanded(child: Text(_uploadedFileUrl!)),
          ],
        );
      case 'audio':
        return Row(
          children: [
            const Icon(Icons.audiotrack),
            const SizedBox(width: 8),
            Expanded(child: Text(_uploadedFileUrl!)),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Lesson')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _lessonTitleController,
              decoration: const InputDecoration(labelText: 'Lesson Title'),
            ),
            TextField(
              controller: _lessonDescController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _lessonTimeController,
              decoration: const InputDecoration(labelText: 'Time Limit (minutes)'),
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              title: const Text('Unlocks Next Level'),
              value: _unlocksNextLevel,
              onChanged: (val) => setState(() => _unlocksNextLevel = val),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Upload File (Image, PDF, Video, Audio)'),
            ),
            const SizedBox(height: 10),
            _buildFilePreview(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitLesson,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save Lesson'),
            ),
          ],
        ),
      ),
    );
  }
}
