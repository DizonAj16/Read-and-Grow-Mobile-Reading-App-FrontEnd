import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../utils/database_helpers.dart';

class StudentReadingMaterialsPage extends StatefulWidget {
  const StudentReadingMaterialsPage({super.key});

  @override
  State<StudentReadingMaterialsPage> createState() => _StudentReadingMaterialsPageState();
}

class _StudentReadingMaterialsPageState extends State<StudentReadingMaterialsPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _tasksWithMaterials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 1. Get student's grade level
      final studentRes = await supabase
          .from('students')
          .select('student_grade')
          .eq('id', user.id)
          .maybeSingle();

      if (studentRes == null || studentRes['student_grade'] == null) {
        debugPrint('❌ Student grade not found');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _tasksWithMaterials = [];
          });
        }
        return;
      }

      final studentGrade = studentRes['student_grade'] as String;

      // 2. Find classes matching the student's grade level
      final classesRes = await supabase
          .from('class_rooms')
          .select('id')
          .eq('grade_level', studentGrade);

      if (classesRes.isEmpty) {
        debugPrint('ℹ️ No classes found for grade: $studentGrade');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _tasksWithMaterials = [];
          });
        }
        return;
      }

      final classIds = (classesRes as List)
          .map((c) => c['id'] as String?)
          .whereType<String>()
          .toList();

      debugPrint('📚 Found ${classIds.length} classes for grade $studentGrade');

      // 3. Get tasks assigned to these classes
      final tasksRes = await supabase
          .from('tasks')
          .select('''
            id,
            title,
            description,
            class_id,
            class_rooms(class_name, grade_level)
          ''')
          .inFilter('class_id', classIds)
          .order('created_at', ascending: false);

      if (tasksRes.isEmpty) {
        debugPrint('ℹ️ No tasks found for grade $studentGrade');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _tasksWithMaterials = [];
          });
        }
        return;
      }

      // 4. Get task_materials for each task
      final List<Map<String, dynamic>> tasksWithMaterials = [];
      
      for (final task in tasksRes) {
        final taskId = task['id'] as String?;
        if (taskId == null) continue;

        // Get materials for this task
        final materialsRes = await DatabaseHelpers.safeGetList(
          supabase: supabase,
          table: 'task_materials',
          filters: {
            'task_id': taskId,
            'material_type': 'pdf',
          },
        );

        if (materialsRes.isNotEmpty) {
          // Process materials to get PDF URLs
          final List<Map<String, dynamic>> materials = [];
          for (var material in materialsRes) {
            final filePath = DatabaseHelpers.safeStringFromResult(
              material,
              'material_file_path',
            );
            
            if (filePath.isNotEmpty) {
              try {
                final pdfUrl = supabase.storage.from('materials').getPublicUrl(filePath);
                if (pdfUrl.isNotEmpty) {
                  materials.add({
                    'id': DatabaseHelpers.safeStringFromResult(material, 'id'),
                    'title': DatabaseHelpers.safeStringFromResult(
                      material,
                      'material_title',
                      defaultValue: 'Reading Material',
                    ),
                    'description': DatabaseHelpers.safeStringFromResult(material, 'description'),
                    'file_path': filePath,
                    'url': pdfUrl,
                  });
                }
              } catch (e) {
                debugPrint('⚠️ Error getting PDF URL: $e');
              }
            }
          }

          if (materials.isNotEmpty) {
            tasksWithMaterials.add({
              'task_id': taskId,
              'task_title': task['title'] ?? 'Untitled Task',
              'task_description': task['description'],
              'class_name': task['class_rooms']?['class_name'] ?? 'Unknown Class',
              'grade_level': task['class_rooms']?['grade_level'] ?? studentGrade,
              'materials': materials,
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _tasksWithMaterials = tasksWithMaterials;
          _isLoading = false;
        });
      }

      debugPrint('✅ Loaded ${tasksWithMaterials.length} tasks with materials');
    } catch (e) {
      debugPrint('❌ Error loading materials: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Materials'),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _buildTasksList(),
      ),
    );
  }

  Widget _buildTasksList() {
    if (_tasksWithMaterials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Reading Materials Available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Materials will appear here when your teacher posts tasks for your grade level',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasksWithMaterials.length,
      itemBuilder: (context, index) {
        final taskData = _tasksWithMaterials[index];
        final taskTitle = taskData['task_title'] as String;
        final taskDescription = taskData['task_description'] as String?;
        final className = taskData['class_name'] as String;
        final gradeLevel = taskData['grade_level'] as String;
        final materials = taskData['materials'] as List<Map<String, dynamic>>;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: ExpansionTile(
            leading: const Icon(Icons.assignment, size: 40, color: Colors.blue),
            title: Text(
              taskTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('$className • Grade $gradeLevel'),
            children: [
              if (taskDescription != null && taskDescription.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    taskDescription,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
                const Divider(),
              ],
              ...materials.map((material) => _buildMaterialCard(material)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material) {
    final title = material['title'] as String;
    final description = material['description'] as String?;
    final pdfUrl = material['url'] as String;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[50],
      child: ExpansionTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
        title: Text(title),
        subtitle: description != null && description.isNotEmpty
            ? Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        children: [
          Container(
            height: 500,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SfPdfViewer.network(
                pdfUrl,
                onDocumentLoadFailed: (details) {
                  debugPrint('❌ PDF load failed: ${details.error}');
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

