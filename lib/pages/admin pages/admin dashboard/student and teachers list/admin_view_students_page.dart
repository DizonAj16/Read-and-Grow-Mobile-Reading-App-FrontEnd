import 'package:deped_reading_app_laravel/api/prefs_service.dart';
import 'package:deped_reading_app_laravel/api/user_service.dart';
import 'package:deped_reading_app_laravel/models/student_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminViewStudentsPage extends StatefulWidget {
  const AdminViewStudentsPage({super.key});

  @override
  State<AdminViewStudentsPage> createState() => _AdminViewStudentsPageState();
}

class _AdminViewStudentsPageState extends State<AdminViewStudentsPage> {
  late Future<List<Student>> _studentsFuture;

  // Pagination state
  static const List<int> _pageSizes = [2, 5, 10, 20, 50];
  int _pageSize = 10;
  int _currentPage = 0;
  List<Student> _allStudents = [];

  @override
  void initState() {
    super.initState();
    _studentsFuture = _loadStudents();
  }

  Future<List<Student>> _loadStudents() async {
    try {
      final apiList = await UserService.fetchAllStudents();
      await PrefsService.storeStudentsToPrefs(apiList);
    } catch (_) {}
    final students = await PrefsService.getStudentsFromPrefs();
    setState(() {
      _allStudents = students;
      _currentPage = 0;
    });
    return students;
  }

  List<Student> _getPaginatedStudents() {
    final start = _currentPage * _pageSize;
    final end = ((_currentPage + 1) * _pageSize).clamp(0, _allStudents.length);
    return _allStudents.sublist(start, end);
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToNextPage() {
    if ((_currentPage + 1) * _pageSize < _allStudents.length) {
      setState(() {
        _currentPage++;
      });
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

  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildStudentList(List<Student> students) {
    if (students.isEmpty) {
      return Center(child: Text('No students found.'));
    }
    final paginated = _getPaginatedStudents();
    final totalPages = (_allStudents.length / _pageSize).ceil();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Student List",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Row(
              children: [
                Text("Show: "),
                DropdownButton<int>(
                  value: _pageSize,
                  items:
                      _pageSizes
                          .map(
                            (size) => DropdownMenuItem<int>(
                              value: size,
                              child: Text(size.toString()),
                            ),
                          )
                          .toList(),
                  onChanged: _onPageSizeChanged,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(" per page"),
              ],
            ),
          ],
        ),
        SizedBox(height: 10),
        // Use Expanded + SingleChildScrollView + GridView for scrollable grid
        Expanded(
          child: Scrollbar(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.55,
              ),
              itemCount: paginated.length,
              itemBuilder: (context, index) {
                final student = paginated[index];
                return Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    child: Container(
                      height: 400,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.white,
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.15),
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 12,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Popup menu at the top right above avatar
                            Row(
                              children: [
                                Spacer(),
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert),
                                  onSelected: (value) async {
                                    if (value == 'view') {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return Dialog(
                                            insetPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 24,
                                                  vertical: 24,
                                                ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(0),
                                              child: Stack(
                                                children: [
                                                  // X button at upper right
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: IconButton(
                                                      icon: Icon(
                                                        Icons.close,
                                                        color: Colors.grey[700],
                                                      ),
                                                      onPressed:
                                                          () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(),
                                                      tooltip: "Close",
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.fromLTRB(
                                                          24,
                                                          32,
                                                          24,
                                                          32,
                                                        ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        FutureBuilder<String?>(
                                                          future: _getBaseUrl(),
                                                          builder:
                                                              (context,
                                                                  snapshot) {
                                                            final String?
                                                                profileUrl = (snapshot
                                                                        .hasData &&
                                                                    student.profilePicture !=
                                                                        null &&
                                                                    student
                                                                        .profilePicture!
                                                                        .isNotEmpty)
                                                                ? "${snapshot.data}/${student.profilePicture}"
                                                                : null;

                                                            if (profileUrl == null || !snapshot.hasData) {
                                                              return CircleAvatar(
                                                                radius: 55,
                                                                backgroundColor:
                                                                    Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary
                                                                        .withOpacity(
                                                                          0.15,
                                                                        ),
                                                                child: Text(
                                                                  student
                                                                      .avatarLetter,
                                                                  style:
                                                                      TextStyle(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        48,
                                                                  ),
                                                                ),
                                                              );
                                                            }

                                                            return CircleAvatar(
                                                              radius: 55,
                                                              backgroundColor:
                                                                  Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .primary
                                                                      .withOpacity(
                                                                        0.15,
                                                                      ),
                                                              child: ClipOval(
                                                                child: FadeInImage.assetNetwork(
                                                                  placeholder:
                                                                      'assets/placeholder/avatar_placeholder.jpg',
                                                                  image: profileUrl,
                                                                  fit: BoxFit.cover,
                                                                  width: 110,
                                                                  height: 110,
                                                                  imageErrorBuilder:
                                                                      (_, __, ___) {
                                                                    return Container(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .primary
                                                                          .withOpacity(
                                                                            0.15,
                                                                          ),
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      child: Text(
                                                                        student
                                                                            .avatarLetter,
                                                                        style:
                                                                            TextStyle(
                                                                          color: Theme.of(
                                                                                  context)
                                                                              .colorScheme
                                                                              .primary,
                                                                          fontWeight:
                                                                              FontWeight
                                                                                  .bold,
                                                                          fontSize:
                                                                              48,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                        SizedBox(height: 24),
                                                        Flexible(
                                                          child: Text(
                                                            student.studentName,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight.bold,
                                                              fontSize: 28,
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .primary,
                                                              letterSpacing: 1.1,
                                                            ),
                                                            textAlign:
                                                                TextAlign.center,
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        Divider(
                                                          color: Theme.of(
                                                                context,
                                                              )
                                                              .colorScheme
                                                              .primary
                                                              .withOpacity(0.5),
                                                          height: 32,
                                                          thickness: 1.5,
                                                        ),
                                                        SizedBox(height: 18),
                                                        // Two columns per row for info, with bigger text and more spacing
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            _infoColumn(
                                                              "LRN",
                                                              student.studentLrn ??
                                                                  "N/A",
                                                              context,
                                                            ),
                                                            SizedBox(width: 48),
                                                            _infoColumn(
                                                              "Grade",
                                                              student.studentGrade ??
                                                                  "N/A",
                                                              context,
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 18),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            _infoColumn(
                                                              "Section",
                                                              student.studentSection ??
                                                                  "N/A",
                                                              context,
                                                            ),
                                                            SizedBox(width: 48),
                                                            _infoColumn(
                                                              "Username",
                                                              student.username ??
                                                                  "N/A",
                                                              context,
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 24),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    } else if (value == 'edit') {
                                      final nameController =
                                          TextEditingController(
                                            text: student.studentName,
                                          );
                                      final lrnController =
                                          TextEditingController(
                                            text: student.studentLrn,
                                          );
                                      final gradeController =
                                          TextEditingController(
                                            text: student.studentGrade,
                                          );
                                      final sectionController =
                                          TextEditingController(
                                            text: student.studentSection,
                                          );
                                      final usernameController =
                                          TextEditingController(
                                            text: student.username,
                                          );

                                      final updated = await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: Text('Edit Student'),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    _buildInputField(
                                                      'Name',
                                                      nameController,
                                                    ),
                                                    _buildInputField(
                                                      'LRN',
                                                      lrnController,
                                                    ),
                                                    _buildInputField(
                                                      'Grade',
                                                      gradeController,
                                                    ),
                                                    _buildInputField(
                                                      'Section',
                                                      sectionController,
                                                    ),
                                                    _buildInputField(
                                                      'Username',
                                                      usernameController,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: Text('Update'),
                                                ),
                                              ],
                                            ),
                                      );

                                      if (updated == true) {
                                        try {
                                          final response =
                                              await UserService.updateUser(
                                                userId: student.userId!,
                                                body: {
                                                  "username":
                                                      usernameController.text
                                                          .trim(),
                                                  "student_name":
                                                      nameController.text
                                                          .trim(),
                                                  "student_lrn":
                                                      lrnController.text.trim(),
                                                  "student_grade":
                                                      gradeController.text
                                                          .trim(),
                                                  "student_section":
                                                      sectionController.text
                                                          .trim(),
                                                },
                                              );
                                          if (response.statusCode == 200) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: Colors.white,
                                                      size: 22,
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      "Student Updated successfully!",
                                                    ),
                                                  ],
                                                ),
                                                backgroundColor:
                                                    Colors.lightBlue[700],
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                margin: EdgeInsets.only(
                                                  top: 20,
                                                  left: 20,
                                                  right: 20,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 8,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                            // Refresh the list
                                            setState(() {
                                              _studentsFuture = _loadStudents();
                                            });
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to update student',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error updating student',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    } else if (value == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: Row(
                                                children: [
                                                  Icon(
                                                    Icons.warning,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Delete Student'),
                                                ],
                                              ),
                                              content: Text(
                                                'Are you sure you want to delete this student?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.of(
                                                        context,
                                                      ).pop(false),
                                                  child: Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                  onPressed:
                                                      () => Navigator.of(
                                                        context,
                                                      ).pop(true),
                                                  child: Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                      );
                                      if (confirm == true) {
                                        try {
                                          if (student.userId != null) {
                                            final response =
                                                await UserService.deleteUser(
                                                  student.userId,
                                                );
                                            print(
                                              'Status: ${response.statusCode}',
                                            );
                                            print('Body: ${response.body}');

                                            if (response.statusCode == 200) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.check_circle,
                                                        color: Colors.white,
                                                        size: 22,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        "Student deleted successfully!",
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor:
                                                      Colors.red[700],
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  margin: EdgeInsets.only(
                                                    top: 20,
                                                    left: 20,
                                                    right: 20,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  elevation: 8,
                                                  duration: Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                              // Refresh list
                                              setState(() {
                                                _studentsFuture =
                                                    _loadStudents();
                                              });
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Failed to delete student',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Student user ID is missing',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error deleting student',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder:
                                      (context) => [
                                        PopupMenuItem(
                                          value: 'view',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.visibility,
                                                color: Colors.blue,
                                              ),
                                              SizedBox(width: 8),
                                              Text('View'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                color: Colors.orange,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Delete'),
                                            ],
                                          ),
                                        ),
                                      ],
                                ),
                              ],
                            ),
                            // Avatar with profile picture or initials
                            FutureBuilder<String?>(
                              future: _getBaseUrl(),
                              builder: (context, snapshot) {
                                final String? profileUrl = (snapshot.hasData &&
                                        student.profilePicture != null &&
                                        student.profilePicture!.isNotEmpty)
                                    ? "${snapshot.data}/${student.profilePicture}"
                                    : null;

                                if (profileUrl == null || !snapshot.hasData) {
                                  return CircleAvatar(
                                    radius: 50,
                                    backgroundColor: _getDynamicColor(index),
                                    child: Text(
                                      student.avatarLetter,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 32,
                                      ),
                                    ),
                                  );
                                }

                                return CircleAvatar(
                                  radius: 50,
                                  backgroundColor: _getDynamicColor(index),
                                  child: ClipOval(
                                    child: FadeInImage.assetNetwork(
                                      placeholder:
                                          'assets/placeholder/avatar_placeholder.jpg',
                                      image: profileUrl,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                      imageErrorBuilder: (_, __, ___) {
                                        return Container(
                                          color: _getDynamicColor(index),
                                          alignment: Alignment.center,
                                          child: Text(
                                            student.avatarLetter,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 32,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 12),
                            // Name
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  student.studentName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                    letterSpacing: 1.1,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            // LRN only
                            SizedBox(height: 10),
                            Text(
                              "LRN:",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Text(
                                  student.studentLrn ?? "N/A",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_circle_left_sharp, size: 40),
              onPressed: _currentPage > 0 ? _goToPreviousPage : null,
            ),
            Text(
              'Page ${_allStudents.isEmpty ? 0 : _currentPage + 1} of $totalPages',
            ),
            IconButton(
              icon: Icon(Icons.arrow_circle_right_sharp, size: 40),
              onPressed:
                  (_currentPage + 1) * _pageSize < _allStudents.length
                      ? _goToNextPage
                      : null,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "All Students",
          style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Student>>(
          future: _studentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text('Failed to load students'));
            }
            // Wrap in LayoutBuilder to allow Expanded in Column
            return LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: constraints.maxHeight,
                  child: _buildStudentList(_allStudents),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Update _infoColumn to accept fontSize and valueFontSize
  Widget _infoColumn(
    String label,
    String value,
    BuildContext context, {
    double fontSize = 15,
    double valueFontSize = 15,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
          SizedBox(height: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: valueFontSize,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Add this helper method inside _AdminViewStudentsPageState
  Color _getDynamicColor(int index) {
    // Define a list of nice colors to cycle through
    final colors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.purple.shade100,
      Colors.orange.shade100,
      Colors.red.shade100,
      Colors.teal.shade100,
      Colors.amber.shade100,
      Colors.pink.shade100,
      Colors.cyan.shade100,
      Colors.lime.shade100,
    ];
    return colors[index % colors.length];
  }

  Future<String?> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String? baseUrl = prefs.getString('base_url');
    if (baseUrl != null) {
      baseUrl = baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    }
    return baseUrl;
  }
}
