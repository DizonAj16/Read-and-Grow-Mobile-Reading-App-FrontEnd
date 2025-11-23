import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:just_audio/just_audio.dart';
import '../../api/reading_materials_service.dart';

class TeacherReadingMaterialsPage extends StatefulWidget {
  const TeacherReadingMaterialsPage({super.key});

  @override
  State<TeacherReadingMaterialsPage> createState() => _TeacherReadingMaterialsPageState();
}

class _TeacherReadingMaterialsPageState extends State<TeacherReadingMaterialsPage> {
  final supabase = Supabase.instance.client;
  List<ReadingMaterial> _materials = [];
  List<Map<String, dynamic>> _readingLevels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadReadingLevels(),
        _loadMaterials(),
      ]);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadReadingLevels() async {
    try {
      final levels = await ReadingMaterialsService.getAllReadingLevels();
      if (mounted) {
        setState(() => _readingLevels = levels);
      }
    } catch (e) {
      debugPrint('❌ Error loading reading levels: $e');
    }
  }

  Future<void> _loadMaterials() async {
    try {
      final materials = await ReadingMaterialsService.getAllReadingMaterials();
      if (mounted) {
        setState(() => _materials = materials);
      }
    } catch (e) {
      debugPrint('❌ Error loading materials: $e');
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  Future<void> _showUploadDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedLevelId;
    File? selectedFile;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Upload Reading Material'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Enter material title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Reading Level *',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedLevelId,
                  items: _readingLevels.map((level) {
                    return DropdownMenuItem(
                      value: level['id'] as String,
                      child: Text('Level ${level['level_number']}: ${level['title']}'),
                    );
                  }).toList(),
                  onChanged: (value) => setDialogState(() => selectedLevelId = value),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf'],
                    );
                    if (result != null && result.files.single.path != null) {
                      setDialogState(() {
                        selectedFile = File(result.files.single.path!);
                      });
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: Text(selectedFile == null
                      ? 'Select PDF File'
                      : selectedFile!.path.split('/').last),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedFile != null &&
                      selectedLevelId != null &&
                      titleController.text.trim().isNotEmpty
                  ? () async {
                      Navigator.pop(context);
                      await _uploadMaterial(
                        file: selectedFile!,
                        title: titleController.text.trim(),
                        levelId: selectedLevelId!,
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                      );
                    }
                  : null,
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadMaterial({
    required File file,
    required String title,
    required String levelId,
    String? description,
  }) async {
    if (!mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false, // Prevent dismissing with back button
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    try {
      final result = await ReadingMaterialsService.uploadReadingMaterial(
        file: file,
        title: title,
        levelId: levelId,
        description: description,
      );

      // Always close loading dialog
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;

      if (result != null && !result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Material uploaded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        await _loadMaterials();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result?['error'] ?? 'Upload failed'}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Always close loading dialog on error
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteMaterial(ReadingMaterial material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${material.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ReadingMaterialsService.deleteReadingMaterial(material.id);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Material deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadMaterials();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to delete material'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewSubmissions(ReadingMaterial material) async {
    final submissions = await ReadingMaterialsService.getSubmissionsForMaterial(material.id);
    
    if (!mounted) return;
    
    final audioPlayer = AudioPlayer();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          String? playingUrl;
          
          return Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Submissions for "${material.title}"',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        audioPlayer.dispose();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: submissions.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No submissions yet'),
                          ),
                        )
                      : ListView.builder(
                          itemCount: submissions.length,
                          itemBuilder: (context, index) {
                            final submission = submissions[index];
                            final student = submission['students'] as Map<String, dynamic>?;
                            final recordingUrl = submission['recording_url'] as String? ?? submission['file_url'] as String?;
                            final isPlaying = playingUrl == recordingUrl;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    (student?['student_name'] as String? ?? 'U')[0].toUpperCase(),
                                  ),
                                ),
                                title: Text(student?['student_name'] ?? 'Unknown'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Submitted: ${submission['created_at'] ?? submission['recorded_at'] ?? 'Unknown'}'),
                                    if (submission['needs_grading'] == true)
                                      Chip(
                                        label: const Text('Needs Grading'),
                                        backgroundColor: Colors.orange.shade100,
                                        labelStyle: const TextStyle(fontSize: 10),
                                      ),
                                  ],
                                ),
                                trailing: recordingUrl != null
                                    ? IconButton(
                                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                                        onPressed: () async {
                                          try {
                                            if (isPlaying) {
                                              await audioPlayer.stop();
                                              setModalState(() => playingUrl = null);
                                            } else {
                                              await audioPlayer.setUrl(recordingUrl);
                                              await audioPlayer.play();
                                              setModalState(() => playingUrl = recordingUrl);
                                              
                                              audioPlayer.playerStateStream.listen((state) {
                                                if (state.processingState == ProcessingState.completed) {
                                                  setModalState(() => playingUrl = null);
                                                }
                                              });
                                            }
                                          } catch (e) {
                                            debugPrint('Error playing audio: $e');
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error playing audio: $e')),
                                            );
                                          }
                                        },
                                      )
                                    : const Icon(Icons.error),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() => audioPlayer.dispose());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _materials.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.library_books, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No Reading Materials Yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to upload your first material',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _materials.length,
                itemBuilder: (context, index) {
                  final material = _materials[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf, size: 40),
                      title: Text(material.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Level ${material.levelNumber ?? 'N/A'}'),
                          if (material.description != null)
                            Text(material.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.people),
                            onPressed: () => _viewSubmissions(material),
                            tooltip: 'View Submissions',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteMaterial(material),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                      onTap: () {
                        // Show PDF viewer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(title: Text(material.title)),
                              body: SfPdfViewer.network(material.fileUrl),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

