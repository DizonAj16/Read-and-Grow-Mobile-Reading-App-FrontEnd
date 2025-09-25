import 'dart:convert';
import 'package:deped_reading_app_laravel/api/classroom_service.dart';
import 'package:deped_reading_app_laravel/models/student_model.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentsManagementPage extends StatefulWidget {
  final String classId;

  const StudentsManagementPage({super.key, required this.classId});

  @override
  State<StudentsManagementPage> createState() => _StudentsManagementPageState();
}

class _StudentsManagementPageState extends State<StudentsManagementPage> {
  List<Student> allStudents = [];
  List<Student> assignedStudents = [];
  bool loading = true;
  int currentAssignedPage = 0;
  int currentUnassignedPage = 0;
  final int studentsPerPage = 5;
  final double avatarSize = 55;
  int _refreshCounter = 0;
  bool isRefreshing = false;
  bool isInitialLoad = true; // Track initial load

  @override
  void initState() {
    super.initState();
    // Initial load with minimum delay
    Future.wait([
      _loadStudents(),
      Future.delayed(const Duration(seconds: 2)), // Minimum loading time
    ]).then((_) {
      if (mounted) {
        setState(() => isInitialLoad = false);
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadStudents() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      _refreshCounter++;
      allStudents = [];
      assignedStudents = [];
    });

    try {
      final assigned = await ClassroomService.getAssignedStudents(
        widget.classId,
      );
      final unassigned = await ClassroomService.getUnassignedStudents();

      if (!mounted) return;
      setState(() {
        assignedStudents = assigned;
        allStudents = unassigned;
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar("Failed to load students: $e", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;

    setState(() {
      isRefreshing = true;
      loading = true; // Show shimmer during refresh
    });

    try {
      await _loadStudents();
    } finally {
      if (mounted) {
        setState(() => isRefreshing = false);
      }
    }
  }

  Future<void> _assignStudent(Student student) async {
    final res = await ClassroomService.assignStudent(
      studentId: student.id,
      classRoomId: widget.classId,
    );

    if (res.statusCode == 200) {
      currentUnassignedPage = 0;
      currentAssignedPage = 0;

      setState(() {
        final updatedStudent = student.copyWith(classRoomId: widget.classId);
        allStudents.removeWhere((s) => s.id == student.id);
        assignedStudents.add(updatedStudent);
      });

      _showSnackBar("Student assigned successfully");
    } else {
      String errorMessage = "Failed to assign student";
      try {
        final Map<String, dynamic> body = jsonDecode(res.body);
        if (body.containsKey('message')) {
          errorMessage = body['message'];
        }
      } catch (_) {}
      _showSnackBar(errorMessage, isError: true);
    }
  }

  Future<void> _unassignStudent(Student student) async {
    final res = await ClassroomService.unassignStudent(studentId: student.id);

    if (res.statusCode == 200) {
      setState(() {
        final updatedStudent = student.copyWith(classRoomId: null);
        assignedStudents.removeWhere((s) => s.id == student.id);
        allStudents.add(updatedStudent);
      });
      _showSnackBar("Student unassigned successfully");
    } else {
      _showSnackBar("Failed to unassign student: ${res.body}", isError: true);
    }
  }

  Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl =
        prefs.getString('base_url') ?? 'http://10.0.2.2:8000/api';
    final uri = Uri.parse(savedBaseUrl);
    return '${uri.scheme}://${uri.authority}';
  }

  Widget _buildStudentAvatar(Student student, bool isAssigned) {
    return FutureBuilder<String>(
      key: ValueKey('${student.id}-$_refreshCounter'),
      future: _getBaseUrl(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildAvatarFallback(student, isAssigned);
        }

        final String? profileUrl =
            (student.profilePicture != null &&
                    student.profilePicture!.isNotEmpty)
                ? "${snapshot.data}/${student.profilePicture}"
                : null;

        if (profileUrl == null) {
          return _buildAvatarFallback(student, isAssigned);
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(avatarSize / 2),
          child: FadeInImage.assetNetwork(
            placeholder: 'assets/placeholder/avatar_placeholder.jpg',
            image: profileUrl,
            fit: BoxFit.cover,
            width: avatarSize,
            height: avatarSize,
            fadeInDuration: const Duration(milliseconds: 800),
            fadeInCurve: Curves.easeInOut,
            imageErrorBuilder:
                (_, __, ___) => _buildAvatarFallback(student, isAssigned),
            placeholderErrorBuilder:
                (_, __, ___) => _buildAvatarFallback(student, isAssigned),
          ),
        );
      },
    );
  }

  Widget _buildAvatarFallback(Student student, bool isAssigned) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: isAssigned ? Colors.green.shade100 : Colors.blue.shade100,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          student.avatarLetter,
          style: TextStyle(
            color: isAssigned ? Colors.green.shade700 : Colors.blue.shade700,
            fontWeight: FontWeight.bold,
            fontSize: avatarSize * 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Student student, {bool isAssigned = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      borderRadius: BorderRadius.circular(16),
      color: colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isAssigned
                      ? Colors.green.withOpacity(0.3)
                      : colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 2),
                    ),
                    child: _buildStudentAvatar(student, isAssigned),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isAssigned ? Colors.green : Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.studentName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(
                              0.7,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primaryContainer.withOpacity(
                                0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "${student.studentGrade ?? 'N/A'}${student.studentSection != null && student.studentSection!.isNotEmpty ? ' - ${student.studentSection!}' : ''}",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:
                        isAssigned
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAssigned ? Icons.person_remove : Icons.person_add,
                    color: isAssigned ? Colors.red : Colors.green,
                    size: 22,
                  ),
                ),
                onPressed: () => _showStudentActionSheet(student, isAssigned),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerTabBar() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: kToolbarHeight,
        color: Colors.white,
        child: Row(
          children: List.generate(
            2,
            (index) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerStudentCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  Container(width: 100, height: 16, color: Colors.white),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerSectionHeader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 200,
        height: 24,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildShimmerPagination() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 150,
        height: 36,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  void _showStudentActionSheet(Student student, bool isAssigned) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _buildStudentAvatar(student, isAssigned),
                  title: Text(
                    student.studentName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    isAssigned ? "Currently assigned" : "Available to assign",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                const Divider(height: 24),
                _buildActionTile(
                  context,
                  icon: isAssigned ? Icons.person_remove : Icons.person_add,
                  label: isAssigned ? "Unassign Student" : "Assign Student",
                  color: isAssigned ? Colors.redAccent : Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _showConfirmationBottomSheet(student, isAssigned);
                  },
                ),
                const SizedBox(height: 8),
                _buildActionTile(
                  context,
                  icon: Icons.close,
                  label: "Cancel",
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showConfirmationBottomSheet(Student student, bool isAssigned) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isAssigned ? Icons.warning : Icons.person_add_alt_1,
                  color: isAssigned ? Colors.orange : Colors.green,
                ),
                title: Text(
                  isAssigned ? "Confirm Unassignment" : "Confirm Assignment",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  isAssigned
                      ? "Are you sure you want to unassign ${student.studentName} from this class? All the student's data will be lost."
                      : "Are you sure you want to assign ${student.studentName} to this class?",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAssigned ? Colors.red : Colors.green,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (isAssigned) {
                        _unassignStudent(student);
                      } else {
                        _assignStudent(student);
                      }
                    },
                    child: Text(
                      isAssigned ? "Unassign" : "Assign",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<Student> get paginatedUnassigned {
    final start = currentUnassignedPage * studentsPerPage;
    final end = (start + studentsPerPage).clamp(0, allStudents.length);
    return allStudents.sublist(start, end);
  }

  List<Student> get paginatedAssigned {
    final start = currentAssignedPage * studentsPerPage;
    final end = (start + studentsPerPage).clamp(0, assignedStudents.length);
    return assignedStudents.sublist(start, end);
  }

  Widget _buildShimmerTabContent() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShimmerSectionHeader(),
            const SizedBox(height: 12),
            Column(
              children: List.generate(3, (index) => _buildShimmerStudentCard()),
            ),
            _buildShimmerPagination(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show shimmer during initial load (with delay) or during refresh
    if (isInitialLoad || loading) {
      return Scaffold(
        body: Column(
          children: [
            _buildShimmerTabBar(),
            Expanded(child: _buildShimmerTabContent()),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: SafeArea(
            top: false, // removes status bar padding
            child: const TabBar(
              dividerHeight: 0,
              tabs: [Tab(text: "Available"), Tab(text: "Class List")],
            ),
          ),
        ),

        body: TabBarView(
          children: [
            _buildStudentList(
              students: paginatedUnassigned,
              isAssigned: false,
              currentPage: currentUnassignedPage,
              totalItems: allStudents.length,
              totalCount: allStudents.length,
              onNextPage: () => setState(() => currentUnassignedPage++),
              onPrevPage: () => setState(() => currentUnassignedPage--),
            ),
            _buildStudentList(
              students: paginatedAssigned,
              isAssigned: true,
              currentPage: currentAssignedPage,
              totalItems: assignedStudents.length,
              totalCount: assignedStudents.length,
              onNextPage: () => setState(() => currentAssignedPage++),
              onPrevPage: () => setState(() => currentAssignedPage--),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList({
    required List<Student> students,
    required bool isAssigned,
    required int currentPage,
    required int totalItems,
    required int totalCount,
    required VoidCallback onNextPage,
    required VoidCallback onPrevPage,
  }) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAssigned
                  ? "Class List ($totalCount Assigned)"
                  : "Available Students ($totalCount Unassigned)",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            if (students.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  isAssigned
                      ? "There are no students assigned to this class yet."
                      : "There are currently no available students to assign.",
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            else ...[
              ...students.map(
                (student) => _buildStudentCard(student, isAssigned: isAssigned),
              ),
              _buildPaginationControls(
                currentPage: currentPage,
                totalItems: totalItems,
                onNext: onNextPage,
                onPrevious: onPrevPage,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls({
    required int currentPage,
    required int totalItems,
    required VoidCallback onNext,
    required VoidCallback onPrevious,
  }) {
    final totalPages = (totalItems / studentsPerPage).ceil();
    final colorScheme = Theme.of(context).colorScheme;

    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: currentPage > 0 ? onPrevious : null,
            color:
                currentPage > 0
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.3),
          ),
          Text(
            "Page ${currentPage + 1} of $totalPages",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: currentPage < totalPages - 1 ? onNext : null,
            color:
                currentPage < totalPages - 1
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
