import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'enhanced_reading_material_page.dart';

class EnhancedReadingLevelPage extends StatefulWidget {
  const EnhancedReadingLevelPage({super.key});

  @override
  State<EnhancedReadingLevelPage> createState() => _EnhancedReadingLevelPageState();
}

class _EnhancedReadingLevelPageState extends State<EnhancedReadingLevelPage> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? currentLevel;
  List<Map<String, dynamic>> materials = [];
  Map<String, dynamic> submissionMap = {}; // Maps material_id to submission record
  bool isLoading = true;
  late TabController _tabController;
  int _currentTabIndex = 0; // 0 = All, 1 = Completed

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _loadReadingLevel();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReadingLevel() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 🔹 Fetch student's record (to get internal student.id)
      final studentRes = await supabase
          .from('students')
          .select('id, current_reading_level_id')
          .eq('id', user.id)
          .maybeSingle();

      if (studentRes == null || studentRes['current_reading_level_id'] == null) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      final studentId = studentRes['id']; // ✅ internal UUID from students.id
      final levelId = studentRes['current_reading_level_id'];

      // 🔹 Get level details
      final levelRes = await supabase
          .from('reading_levels')
          .select('*')
          .eq('id', levelId)
          .maybeSingle();

      // 🔹 Get reading materials linked to that reading level
      final materialsRes = await supabase
          .from('reading_materials')
          .select('id, title, description, file_url, created_at')
          .eq('level_id', levelId)
          .order('created_at', ascending: true);

      // 🔹 Extract UUID list of materials
      final materialIds = (materialsRes as List)
          .map((m) => m['id']?.toString())
          .where((id) => id != null)
          .toList();

      // 🔹 Get student's submission records for these materials
      // Note: For reading materials, task_id is NULL and material_id is stored in teacher_comments JSON
      final submissionsRes = await supabase
          .from('student_recordings')
          .select('teacher_comments, recorded_at, needs_grading, score, file_url')
          .eq('student_id', studentId)
          .isFilter('task_id', null); // task_id is NULL for materials

      final Map<String, dynamic> submissions = {};
      for (final s in submissionsRes) {
        // Extract material_id from teacher_comments JSON or file_url pattern
        String? materialId;
        
        // Try to parse from teacher_comments JSON
        final comments = s['teacher_comments'] as String?;
        if (comments != null && comments.contains('"material_id"')) {
          try {
            // Simple extraction: look for "material_id": "uuid"
            final regex = RegExp(r'"material_id":\s*"([^"]+)"');
            final match = regex.firstMatch(comments);
            if (match != null) {
              materialId = match.group(1);
            }
          } catch (e) {
            debugPrint('Error parsing material_id from comments: $e');
          }
        }
        
        // Backup: extract from file_url if it contains material_id
        if (materialId == null) {
          final fileUrl = s['file_url'] as String?;
          if (fileUrl != null && fileUrl.isNotEmpty) {
            for (final mid in materialIds) {
              if (mid != null && fileUrl.contains(mid)) {
                materialId = mid;
                break;
              }
            }
          }
        }
        
        if (materialId != null && materialIds.contains(materialId)) {
          submissions[materialId] = s;
        }
      }

      if (mounted) {
        setState(() {
          currentLevel = levelRes;
          materials = List<Map<String, dynamic>>.from(materialsRes);
          submissionMap = submissions;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reading level: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  bool _isMaterialSubmitted(dynamic materialId) {
    return submissionMap.containsKey(materialId.toString());
  }

  String _getProgressStatus(dynamic materialId) {
    if (_isMaterialSubmitted(materialId)) {
      return 'submitted';
    }
    return 'not_started';
  }

  /// Get filtered materials based on current tab
  List<Map<String, dynamic>> _getFilteredMaterials() {
    if (_currentTabIndex == 0) {
      // All materials
      return materials;
    } else {
      // Submitted materials only
      return materials.where((material) {
        final materialId = material['id']?.toString();
        return materialId != null && _isMaterialSubmitted(materialId);
      }).toList();
    }
  }



  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentLevel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('📚 My Reading Level')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No reading level assigned yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Ask your teacher to assign you a reading level',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final totalMaterials = materials.length;
    final submittedCount = submissionMap.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('📚 ${currentLevel!['title']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReadingLevel,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Text(
                    currentLevel!['title'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentLevel!['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProgressStat('Submitted', '$submittedCount/$totalMaterials', Icons.check_circle),
                        const VerticalDivider(color: Colors.white70),
                        _buildProgressStat('Pending', '${totalMaterials - submittedCount} remaining', Icons.schedule),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'All Materials', icon: Icon(Icons.list)),
                Tab(text: 'Submitted', icon: Icon(Icons.check_circle)),
              ],
              onTap: (index) {
                setState(() {
                  _currentTabIndex = index;
                });
              },
            ),
          ),

          // Materials List
          Expanded(
            child: Builder(
              builder: (context) {
                final filteredMaterials = _getFilteredMaterials();
                
                if (filteredMaterials.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _currentTabIndex == 0 
                              ? Icons.book_outlined 
                              : Icons.check_circle_outline,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentTabIndex == 0
                              ? 'No reading materials available yet'
                              : 'No submitted materials yet',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        if (_currentTabIndex == 1) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Submit recordings to see them here',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredMaterials.length,
                  itemBuilder: (context, index) {
                    final material = filteredMaterials[index];
                    final materialId = material['id'];
                    final originalIndex = materials.indexWhere((m) => m['id'] == materialId);
                    final submitted = _isMaterialSubmitted(materialId);
                    final status = _getProgressStatus(materialId);

                    return _buildMaterialCard(
                      material: material,
                      index: originalIndex != -1 ? originalIndex : index,
                      submitted: submitted,
                      status: status,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialCard({
    required Map<String, dynamic> material,
    required int index,
    required bool submitted,
    required String status,
  }) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (submitted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Submitted';
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.play_circle_outline;
      statusText = 'Start Reading';
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EnhancedReadingMaterialPage(material: material),
            ),
          ).then((_) {
            if (mounted) {
              _loadReadingLevel();
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Material ${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          material['title'] ?? 'Untitled Material',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: statusColor),
                ],
              ),
              if (material['description'] != null && material['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  material['description'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    avatar: Icon(Icons.menu_book, size: 16),
                    label: Text(statusText),
                    backgroundColor: statusColor.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (submitted)
                    Icon(Icons.audio_file, color: Colors.green, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
