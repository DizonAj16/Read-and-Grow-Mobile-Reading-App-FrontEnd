import 'package:flutter/material.dart';
import 'teacher dashboard/create student and classes/create_class_or_student_dialog.dart';
import '../../models/student_model.dart';
import '../../api/classroom_service.dart';
import 'edit_student_profile_teacher_page.dart';

class PupilManagementPage extends StatefulWidget {
  const PupilManagementPage({super.key});

  @override
  State<PupilManagementPage> createState() => _PupilManagementPageState();
}

class _PupilManagementPageState extends State<PupilManagementPage> {
  List<Student> _allPupils = [];
  List<Student> _filteredPupils = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedGradeFilter;
  String? _selectedSectionFilter;

  @override
  void initState() {
    super.initState();
    _loadPupils();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPupils() async {
    setState(() => _isLoading = true);

    try {
      final pupils = await ClassroomService.getAllStudents();
      
      setState(() {
        _allPupils = pupils;
        _filteredPupils = pupils;
      });
    } catch (e) {
      debugPrint('Error loading pupils: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading pupils: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPupils = _allPupils.where((pupil) {
        final matchesSearch = _searchQuery.isEmpty ||
            pupil.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (pupil.studentLrn?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase()) ||
            (pupil.username?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase());

        final matchesGrade = _selectedGradeFilter == null ||
            _selectedGradeFilter!.isEmpty ||
            pupil.studentGrade == _selectedGradeFilter;

        final matchesSection = _selectedSectionFilter == null ||
            _selectedSectionFilter!.isEmpty ||
            pupil.studentSection == _selectedSectionFilter;

        return matchesSearch && matchesGrade && matchesSection;
      }).toList();
    });
  }

  void _showAddPupilDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateClassOrStudentDialog(
        initialTab: 1, // Start with Student form (1) instead of Class form (0)
        onStudentAdded: () {
          _loadPupils();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Pupil added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshPupils() async {
    await _loadPupils();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Pupil list refreshed'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showPupilOptions(BuildContext context, Student pupil) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.person, 
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    pupil.studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Grade ${pupil.studentGrade ?? 'N/A'} - ${pupil.studentSection ?? 'N/A'}',
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.blue),
                  title: const Text('View Details'),
                  onTap: () {
                    Navigator.pop(context);
                    _showPupilDetails(context, pupil);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.green),
                  title: const Text('Edit Profile'),
                  subtitle: const Text('Edit profile & assign reading level'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditStudentProfileTeacherPage(
                          studentId: pupil.id,
                        ),
                      ),
                    );
                    if (result == true) {
                      // Refresh pupil list
                      _loadPupils();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Student profile updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPupilDetails(BuildContext context, Student pupil) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pupil Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Name'),
                subtitle: Text(pupil.studentName),
              ),
              if (pupil.studentLrn != null)
                ListTile(
                  leading: const Icon(Icons.confirmation_number),
                  title: const Text('LRN'),
                  subtitle: Text(pupil.studentLrn!),
                ),
              if (pupil.studentGrade != null || pupil.studentSection != null)
                ListTile(
                  leading: const Icon(Icons.school),
                  title: const Text('Grade & Section'),
                  subtitle: Text('Grade ${pupil.studentGrade ?? 'N/A'} - ${pupil.studentSection ?? 'N/A'}'),
                ),
              if (pupil.username != null)
                ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: const Text('Username'),
                  subtitle: Text(pupil.username!),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<String> get _availableGrades {
    final grades = _allPupils
        .map((p) => p.studentGrade)
        .whereType<String>()
        .toSet()
        .toList();
    grades.sort();
    return grades;
  }

  List<String> get _availableSections {
    final sections = _allPupils
        .map((p) => p.studentSection)
        .whereType<String>()
        .toSet()
        .toList();
    sections.sort();
    return sections;
  }

  Widget _buildSearchAndFilters() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, LRN, or username...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DropdownButton<String>(
                  value: _selectedGradeFilter,
                  hint: const Text('Filter by Grade'),
                  items: [null, ..._availableGrades].map((grade) {
                    return DropdownMenuItem(
                      value: grade,
                      child: Text(grade ?? 'All Grades'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGradeFilter = value;
                    });
                    _applyFilters();
                  },
                ),
                DropdownButton<String>(
                  value: _selectedSectionFilter,
                  hint: const Text('Filter by Section'),
                  items: [null, ..._availableSections].map((section) {
                    return DropdownMenuItem(
                      value: section,
                      child: Text(section ?? 'All Sections'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSectionFilter = value;
                    });
                    _applyFilters();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPupilCard(Student pupil) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            pupil.studentName.isNotEmpty
                ? pupil.studentName.substring(0, 1).toUpperCase()
                : '?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          pupil.studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pupil.studentLrn != null)
              Text('LRN: ${pupil.studentLrn}'),
            if (pupil.studentGrade != null)
              Text('Grade ${pupil.studentGrade}${pupil.studentSection != null ? ' - ${pupil.studentSection}' : ''}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showPupilOptions(context, pupil),
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 Manage Pupils'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshPupils,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.assignment_ind, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Assign to Class'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndFilters(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadPupils,
                    child: _filteredPupils.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No pupils yet'
                                      : 'No pupils found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (_searchQuery.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: _showAddPupilDialog,
                                    icon: const Icon(Icons.person_add),
                                    label: const Text('Add First Pupil'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredPupils.length,
                            itemBuilder: (context, index) =>
                                _buildPupilCard(_filteredPupils[index]),
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPupilDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Pupil'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
