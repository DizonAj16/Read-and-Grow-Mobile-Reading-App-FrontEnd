import 'package:deped_reading_app_laravel/api/user_service.dart';
import 'package:deped_reading_app_laravel/models/student_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dialog_utils.dart';
import 'student_info_dialog.dart';
import 'student_edit_dialog.dart';
import 'student_delete_dialog.dart';
import 'student_list_item.dart';

class TeacherStudentListModal extends StatefulWidget {
  final List<Student> allStudents;
  final List<int> pageSizes;
  final int initialPageSize;
  final VoidCallback? onDataChanged;

  const TeacherStudentListModal({
    super.key,
    required this.allStudents,
    required this.pageSizes,
    required this.initialPageSize,
    this.onDataChanged,
  });

  @override
  State<TeacherStudentListModal> createState() =>
      _TeacherStudentListModalState();
}

class _TeacherStudentListModalState extends State<TeacherStudentListModal> {
  late int _pageSize;
  int _currentPage = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Student> _filteredStudents = [];
  String _searchQuery = '';
  String? _selectedGrade;
  String? _selectedSection;

  @override
  void initState() {
    super.initState();
    _pageSize = widget.initialPageSize;
    _filteredStudents = widget.allStudents;
  }

  @override
  void didUpdateWidget(TeacherStudentListModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allStudents != widget.allStudents) {
      _applyFilters();
    }
  }

  List<String> get _availableGrades {
    final grades =
        widget.allStudents
            .map((student) => student.studentGrade)
            .whereType<String>() // This filters out null values
            .where((grade) => grade.isNotEmpty)
            .toSet()
            .toList();
    grades.sort();
    return grades;
  }

  List<String> get _availableSections {
    final sections =
        widget.allStudents
            .map((student) => student.studentSection)
            .whereType<String>() // This filters out null values
            .where((section) => section.isNotEmpty)
            .toSet()
            .toList();
    sections.sort();
    return sections;
  }

  void _applyFilters() {
    setState(() {
      _filteredStudents =
          widget.allStudents.where((student) {
            // Search filter
            final matchesSearch =
                _searchQuery.isEmpty ||
                student.studentName.toLowerCase().contains(_searchQuery) ||
                (student.studentLrn?.toLowerCase() ?? '').contains(
                  _searchQuery,
                ) ||
                (student.studentGrade?.toLowerCase() ?? '').contains(
                  _searchQuery,
                ) ||
                (student.studentSection?.toLowerCase() ?? '').contains(
                  _searchQuery,
                ) ||
                (student.username?.toLowerCase() ?? '').contains(_searchQuery);

            // Grade filter
            final matchesGrade =
                _selectedGrade == null ||
                _selectedGrade!.isEmpty ||
                student.studentGrade == _selectedGrade;

            // Section filter
            final matchesSection =
                _selectedSection == null ||
                _selectedSection!.isEmpty ||
                student.studentSection == _selectedSection;

            return matchesSearch && matchesGrade && matchesSection;
          }).toList();
      _currentPage = 0; // Reset to first page when filters change
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _applyFilters();
    });
  }

  void _resetAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedGrade = null;
      _selectedSection = null;
      _applyFilters();
    });
  }

  List<Student> _getPaginatedStudents() {
    final start = _currentPage * _pageSize;
    final end = ((_currentPage + 1) * _pageSize).clamp(
      0,
      _filteredStudents.length,
    );
    return _filteredStudents.sublist(start, end);
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  void _goToNextPage() {
    if ((_currentPage + 1) * _pageSize < _filteredStudents.length) {
      setState(() => _currentPage++);
    }
  }

  void _onPageSizeChanged(int? newSize) {
    if (newSize != null && newSize != _pageSize) {
      setState(() {
        _pageSize = newSize;
        _currentPage = 0;
      });
    }
  }

  Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl =
        prefs.getString('base_url') ?? 'http://10.0.2.2:8000/api';
    final uri = Uri.parse(savedBaseUrl);
    return '${uri.scheme}://${uri.authority}';
  }

  Future<void> _showStudentInfoDialog(Student student) async {
    final baseUrl = await _getBaseUrl();
    final profileUrl =
        (student.profilePicture != null && student.profilePicture!.isNotEmpty)
            ? "$baseUrl/${student.profilePicture}"
            : null;

    showDialog(
      context: context,
      builder:
          (context) => StudentInfoDialog(
            student: student,
            profileUrl: profileUrl,
            colorScheme: Theme.of(context).colorScheme,
          ),
    );
  }

  Future<void> _handleEditStudent(Student student) async {
    final nameController = TextEditingController(text: student.studentName);
    final lrnController = TextEditingController(text: student.studentLrn);
    final gradeController = TextEditingController(text: student.studentGrade);
    final sectionController = TextEditingController(
      text: student.studentSection,
    );
    final usernameController = TextEditingController(text: student.username);

    final updated = await showDialog<bool>(
      context: context,
      builder:
          (context) => StudentEditDialog(
            nameController: nameController,
            lrnController: lrnController,
            gradeController: gradeController,
            sectionController: sectionController,
            usernameController: usernameController,
          ),
    );

    if (updated == true) {
      await _performStudentUpdate(student, {
        "username": usernameController.text.trim(),
        "student_name": nameController.text.trim(),
        "student_lrn": lrnController.text.trim(),
        "student_grade": gradeController.text.trim(),
        "student_section": sectionController.text.trim(),
      });
    }
  }

  Future<void> _performStudentUpdate(
    Student student,
    Map<String, String> data,
  ) async {
    DialogUtils.showLoadingDialog(
      context,
      'assets/animation/edit.json',
      "Updating Student...",
    );

    try {
      final response = await UserService.updateUser(
        userId: student.userId!,
        body: data,
      );

      await DialogUtils.hideLoadingDialog(context);

      if (response.statusCode == 200) {
        _showSuccessSnackbar(
          "Student Updated successfully!",
          Colors.lightBlue[700],
        );
        widget.onDataChanged?.call();
      } else {
        _showErrorSnackbar('Failed to update student');
      }
    } catch (e) {
      await DialogUtils.hideLoadingDialog(context);
      _showErrorSnackbar('Error updating student');
    }
  }

  Future<void> _handleDeleteStudent(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const StudentDeleteDialog(),
    );

    if (confirm == true) {
      await _performStudentDeletion(student);
    }
  }

  Future<void> _performStudentDeletion(Student student) async {
    DialogUtils.showLoadingDialog(
      context,
      'assets/animation/delete.json',
      "Deleting Student...",
    );

    try {
      if (student.userId != null) {
        final response = await UserService.deleteUser(student.userId);
        await DialogUtils.hideLoadingDialog(context);

        if (response.statusCode == 200) {
          _showSuccessSnackbar(
            "Student deleted successfully!",
            Colors.red[700],
          );
          setState(() {
            widget.allStudents.removeWhere((s) => s.userId == student.userId);
            _filteredStudents.removeWhere((s) => s.userId == student.userId);
          });
          widget.onDataChanged?.call();
        } else {
          _showErrorSnackbar('Failed to delete student');
        }
      } else {
        await DialogUtils.hideLoadingDialog(context);
        _showErrorSnackbar('Student user ID is missing');
      }
    } catch (e) {
      await DialogUtils.hideLoadingDialog(context);
      _showErrorSnackbar('Error deleting student');
    }
  }

  void _showSuccessSnackbar(String message, Color? backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 80, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 80, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paginated = _getPaginatedStudents();
    final totalPages = (_filteredStudents.length / _pageSize).ceil();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHandleIndicator(context),
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildSearchBar(),
        const SizedBox(height: 12),
        _buildFilterControls(),
        const SizedBox(height: 16),
        _buildStudentList(paginated),
        const SizedBox(height: 16),
        _buildPaginationControls(totalPages),
      ],
    );
  }

  Widget _buildHandleIndicator(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Student List",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        _buildPageSizeDropdown(),
      ],
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search students...',
                hintStyle: TextStyle(fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[500]),
                          onPressed: _clearSearch,
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                  _applyFilters();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _resetAllFilters,
              tooltip: 'Reset all filters',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Row(
      children: [
        Expanded(
          child: _buildCompactFilterDropdown(
            value: _selectedGrade,
            items: _availableGrades,
            hint: 'Grade',
            onChanged: (value) {
              setState(() {
                _selectedGrade = value;
                _applyFilters();
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactFilterDropdown(
            value: _selectedSection,
            items: _availableSections,
            hint: 'Section',
            onChanged: (value) {
              setState(() {
                _selectedSection = value;
                _applyFilters();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactFilterDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: [
          DropdownMenuItem(
            value: null,
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ...items.map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: InputBorder.none,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        dropdownColor: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        isExpanded: true,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildPageSizeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Show: ",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _pageSize,
              items:
                  widget.pageSizes
                      .map(
                        (size) => DropdownMenuItem<int>(
                          value: size,
                          child: Text(
                            size.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: _onPageSizeChanged,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
              dropdownColor: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(List<Student> students) {
    if (_filteredStudents.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _searchQuery.isEmpty &&
                          _selectedGrade == null &&
                          _selectedSection == null
                      ? 'No students found.'
                      : 'No students match your filters',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_searchQuery.isNotEmpty ||
                  _selectedGrade != null ||
                  _selectedSection != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ElevatedButton(
                    onPressed: _resetAllFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Clear all filters'),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return FutureBuilder<String>(
                future: _getBaseUrl(),
                builder: (context, snapshot) {
                  String? imageUrl;
                  if (snapshot.hasData &&
                      student.profilePicture != null &&
                      student.profilePicture!.isNotEmpty) {
                    imageUrl = "${snapshot.data}/${student.profilePicture}";
                  }

                  return StudentListItem(
                    student: student,
                    imageUrl: imageUrl,
                    onViewPressed: () => _showStudentInfoDialog(student),
                    onEditPressed: () => _handleEditStudent(student),
                    onDeletePressed: () => _handleDeleteStudent(student),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    final bool hasPreviousPage = _currentPage > 0;
    final bool hasNextPage =
        (_currentPage + 1) * _pageSize < _filteredStudents.length;
    final int startIndex =
        _filteredStudents.isEmpty ? 0 : (_currentPage * _pageSize) + 1;
    final int endIndex =
        _filteredStudents.isEmpty
            ? 0
            : ((_currentPage + 1) * _pageSize).clamp(
              0,
              _filteredStudents.length,
            );
    final int totalStudents = _filteredStudents.length;
    final int currentPageDisplay =
        _filteredStudents.isEmpty ? 0 : _currentPage + 1;
    final int totalPagesDisplay = totalPages == 0 ? 1 : totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Results count - more concise wording
          Text(
            '$startIndex-$endIndex of $totalStudents students',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),

          // Unified pagination controls for all screen sizes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button
              _buildCompactPaginationButton(
                icon: Icons.arrow_back_ios,
                isEnabled: hasPreviousPage,
                onPressed: _goToPreviousPage,
                tooltip: 'Previous page',
              ),

              // Page info - more compact
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'page $currentPageDisplay of $totalPagesDisplay',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

              // Next button
              _buildCompactPaginationButton(
                icon: Icons.arrow_forward_ios,
                isEnabled: hasNextPage,
                onPressed: _goToNextPage,
                tooltip: 'Next page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPaginationButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: isEnabled ? onPressed : null,
        style: IconButton.styleFrom(
          backgroundColor:
              isEnabled
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color:
                  isEnabled
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(8),
          visualDensity: VisualDensity.compact,
        ),
        iconSize: 16,
      ),
    );
  }
}
