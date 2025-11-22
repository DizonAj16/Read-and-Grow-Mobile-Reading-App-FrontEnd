import 'package:deped_reading_app_laravel/api/user_service.dart';
import 'package:deped_reading_app_laravel/models/teacher_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminViewTeachersPage extends StatefulWidget {
  const AdminViewTeachersPage({super.key});

  @override
  State<AdminViewTeachersPage> createState() => _AdminViewTeachersPageState();
}

class _AdminViewTeachersPageState extends State<AdminViewTeachersPage> {
  late Future<List<Teacher>> _teachersFuture;

  static const List<int> _pageSizes = [2, 5, 10, 20, 50];
  int _pageSize = 10;
  int _currentPage = 0;
  List<Teacher> _allTeachers = [];

  @override
  void initState() {
    super.initState();
    _teachersFuture = _loadTeachers();
  }

  Future<List<Teacher>> _loadTeachers() async {
    try {
      final teachers = await UserService.fetchAllTeachers();
      if (mounted) {
        setState(() {
          _allTeachers = teachers;
          _currentPage = 0;
        });
      }
      return teachers;
    } catch (e) {
      debugPrint('Error loading teachers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load teachers: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _allTeachers = [];
        });
      }
      return [];
    }
  }

  List<Teacher> _getPaginatedTeachers() {
    final start = _currentPage * _pageSize;
    final end = ((_currentPage + 1) * _pageSize).clamp(0, _allTeachers.length);
    return _allTeachers.sublist(start, end);
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToNextPage() {
    if ((_currentPage + 1) * _pageSize < _allTeachers.length) {
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

  Widget _buildTeacherList(List<Teacher> teachers) {
    if (teachers.isEmpty) {
      return Center(child: Text('No teachers found.'));
    }
    final paginated = _getPaginatedTeachers();
    final totalPages = (_allTeachers.length / _pageSize).ceil();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Teacher List",
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
                final teacher = paginated[index];
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
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxHeight: MediaQuery.of(context).size.height * 0.8,
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(0),
                                                child: Stack(
                                                  children: [
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
                                                      child: SingleChildScrollView(
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
                                                                    teacher.profilePicture !=
                                                                        null &&
                                                                    teacher
                                                                        .profilePicture!
                                                                        .isNotEmpty)
                                                                ? "${snapshot.data}/${teacher.profilePicture}"
                                                                : null;

                                                            final String initial =
                                                                teacher.name
                                                                        .isNotEmpty
                                                                    ? teacher
                                                                        .name[0]
                                                                        .toUpperCase()
                                                                    : "T";

                                                            if (profileUrl == null || !snapshot.hasData) {
                                                              return CircleAvatar(
                                                                radius: 55,
                                                                backgroundColor:
                                                                    _getDynamicColor(
                                                                      index,
                                                                    ),
                                                                child: Text(
                                                                  initial,
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
                                                                  _getDynamicColor(
                                                                    index,
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
                                                                      color: _getDynamicColor(
                                                                        index,
                                                                      ),
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      child: Text(
                                                                        initial,
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
                                                        Text(
                                                          teacher.name,
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
                                                        // Approval status in dialog
                                                        if (teacher.accountStatus != null)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 12),
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(
                                                                horizontal: 16,
                                                                vertical: 8,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: teacher.accountStatus == 'active'
                                                                    ? Colors.green.withOpacity(0.2)
                                                                    : Colors.orange.withOpacity(0.2),
                                                                borderRadius: BorderRadius.circular(12),
                                                                border: Border.all(
                                                                  color: teacher.accountStatus == 'active'
                                                                      ? Colors.green
                                                                      : Colors.orange,
                                                                  width: 1.5,
                                                                ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Icon(
                                                                    teacher.accountStatus == 'active'
                                                                        ? Icons.check_circle
                                                                        : Icons.pending,
                                                                    size: 20,
                                                                    color: teacher.accountStatus == 'active'
                                                                        ? Colors.green
                                                                        : Colors.orange,
                                                                  ),
                                                                  const SizedBox(width: 8),
                                                                  Flexible(
                                                                    child: Text(
                                                                      teacher.accountStatus == 'active'
                                                                          ? 'Approved Teacher'
                                                                          : 'Pending Approval',
                                                                      style: TextStyle(
                                                                        fontSize: 14,
                                                                        fontWeight: FontWeight.bold,
                                                                        color: teacher.accountStatus == 'active'
                                                                            ? Colors.green[700]
                                                                            : Colors.orange[700],
                                                                      ),
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
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
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            _infoColumn(
                                                              "Email",
                                                              teacher.email ??
                                                                  "N/A",
                                                              context,
                                                            ),
                                                            SizedBox(width: 48),
                                                            _infoColumn(
                                                              "Username",
                                                              teacher.username ??
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
                                                              "Position",
                                                              teacher.position ??
                                                                  "N/A",
                                                              context,
                                                            ),
                                                            SizedBox(width: 48),
                                                            _infoColumn(
                                                              "ID",
                                                              teacher.id
                                                                      ?.toString() ??
                                                                  "N/A",
                                                              context,
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 24),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    } else if (value == 'edit') {
                                      final nameController =
                                          TextEditingController(
                                            text: teacher.name,
                                          );
                                      final emailController =
                                          TextEditingController(
                                            text: teacher.email,
                                          );
                                      final positionController =
                                          TextEditingController(
                                            text: teacher.position,
                                          );
                                      final usernameController =
                                          TextEditingController(
                                            text: teacher.username,
                                          );

                                      final updated = await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: Text('Edit Teacher'),
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
                                                      'Email',
                                                      emailController,
                                                    ),
                                                    _buildInputField(
                                                      'Position',
                                                      positionController,
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
                                                userId: teacher.userId!,
                                                body: {
                                                  "username":
                                                      usernameController.text
                                                          .trim(),
                                                  "teacher_name":
                                                      nameController.text
                                                          .trim(),
                                                  "teacher_email":
                                                      emailController.text
                                                          .trim(),
                                                  "teacher_position":
                                                      positionController.text
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
                                                      "Teacher Updated successfully!",
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
                                              _teachersFuture = _loadTeachers();
                                            });
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to update teacher',
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
                                                'Error updating teacher',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    } else if (value == 'approve') {
                                      await _handleTeacherApproval(teacher, true);
                                    } else if (value == 'reject') {
                                      await _handleTeacherApproval(teacher, false);
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
                                                  Text('Delete Teacher'),
                                                ],
                                              ),
                                              content: Text(
                                                'Are you sure you want to delete this teacher?',
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
                                          if (teacher.userId != null) {
                                            final response =
                                                await UserService.deleteUser(
                                                  teacher.userId,
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
                                                        "Teacher deleted successfully!",
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor:
                                                      Colors.green[700],
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
                                                _teachersFuture =
                                                    _loadTeachers();
                                              });
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Failed to delete teacher',
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
                                                  'Teacher user ID is missing',
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
                                                'Error deleting teacher',
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
                                        if (teacher.accountStatus != 'active')
                                          PopupMenuItem(
                                            value: 'approve',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Approve'),
                                              ],
                                            ),
                                          ),
                                        if (teacher.accountStatus == 'active')
                                          PopupMenuItem(
                                            value: 'reject',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.cancel,
                                                  color: Colors.orange,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Reject'),
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
                                        teacher.profilePicture != null &&
                                        teacher.profilePicture!.isNotEmpty)
                                    ? "${snapshot.data}/${teacher.profilePicture}"
                                    : null;

                                final String initial = teacher.name.isNotEmpty
                                    ? teacher.name[0].toUpperCase()
                                    : "T";

                                if (profileUrl == null || !snapshot.hasData) {
                                  return CircleAvatar(
                                    radius: 50,
                                    backgroundColor: _getDynamicColor(index),
                                    child: Text(
                                      initial,
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
                                            initial,
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
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  teacher.name,
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
                            // Approval status badge
                            if (teacher.accountStatus != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: teacher.accountStatus == 'active'
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: teacher.accountStatus == 'active'
                                          ? Colors.green
                                          : Colors.orange,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        teacher.accountStatus == 'active'
                                            ? Icons.check_circle
                                            : Icons.pending,
                                        size: 14,
                                        color: teacher.accountStatus == 'active'
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          teacher.accountStatus == 'active'
                                              ? 'Approved'
                                              : 'Pending',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: teacher.accountStatus == 'active'
                                                ? Colors.green[700]
                                                : Colors.orange[700],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            SizedBox(height: 10),
                            Text(
                              "Email:",
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
                                  teacher.email ?? "N/A",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                  maxLines: 2,
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
              'Page ${_allTeachers.isEmpty ? 0 : _currentPage + 1} of $totalPages',
            ),
            IconButton(
              icon: Icon(Icons.arrow_circle_right_sharp, size: 40),
              onPressed:
                  (_currentPage + 1) * _pageSize < _allTeachers.length
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
          "All Teachers",
          style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Teacher>>(
          future: _teachersFuture,
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
              return Center(child: Text('Failed to load teachers'));
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: constraints.maxHeight,
                  child: _buildTeacherList(_allTeachers),
                );
              },
            );
          },
        ),
      ),
    );
  }

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

  Color _getDynamicColor(int index) {
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

  Future<void> _handleTeacherApproval(Teacher teacher, bool isApproved) async {
    // Get teacher ID - handle both UUID (string) and integer IDs
    String? teacherId;
    if (teacher.id != null) {
      teacherId = teacher.id.toString();
    } else if (teacher.userId != null) {
      teacherId = teacher.userId.toString();
    } else if (teacher.email != null) {
      // Fallback: get ID from database using email
      try {
        final supabase = Supabase.instance.client;
        final teacherData = await supabase
            .from('teachers')
            .select('id')
            .eq('teacher_email', teacher.email!)
            .maybeSingle();
        if (teacherData != null && teacherData['id'] != null) {
          teacherId = teacherData['id'].toString();
        }
      } catch (e) {
        debugPrint('Error fetching teacher ID: $e');
      }
    }

    if (teacherId == null || teacherId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher ID is missing. Cannot update approval status.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              isApproved ? Icons.check_circle : Icons.cancel,
              color: isApproved ? Colors.green : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isApproved ? 'Approve Teacher' : 'Reject Teacher',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Text(
          isApproved
              ? 'Are you sure you want to approve ${teacher.name}? They will gain full access to the system.'
              : 'Are you sure you want to reject ${teacher.name}? They will lose access to the system.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproved ? Colors.green : Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isApproved ? 'Approve' : 'Reject',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Updating approval status...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final success = await UserService.updateTeacherApprovalStatus(
        teacherId: teacherId,
        isApproved: isApproved,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    isApproved ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isApproved
                          ? 'Teacher approved successfully!'
                          : 'Teacher rejected successfully!',
                    ),
                  ),
                ],
              ),
              backgroundColor: isApproved ? Colors.green[700] : Colors.orange[700],
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        // Refresh the list
        if (mounted) {
          setState(() {
            _teachersFuture = _loadTeachers();
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update teacher approval status. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
