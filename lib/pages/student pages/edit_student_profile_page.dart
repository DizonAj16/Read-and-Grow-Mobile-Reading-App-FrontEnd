import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../api/user_service.dart';
import '../../models/student_model.dart';
import '../../utils/validators.dart';
import '../../utils/data_validators.dart';
import '../../utils/database_helpers.dart';

class EditStudentProfilePage extends StatefulWidget {
  const EditStudentProfilePage({super.key});

  @override
  State<EditStudentProfilePage> createState() => _EditStudentProfilePageState();
}

class _EditStudentProfilePageState extends State<EditStudentProfilePage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _lrnController;
  late TextEditingController _usernameController;
  late TextEditingController _gradeController;
  late TextEditingController _sectionController;
  
  // State variables
  Student? _currentStudent;
  List<Map<String, dynamic>> _readingLevels = [];
  String? _selectedLevelId;
  XFile? _pickedImageFile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _lrnController = TextEditingController();
    _usernameController = TextEditingController();
    _gradeController = TextEditingController();
    _sectionController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lrnController.dispose();
    _usernameController.dispose();
    _gradeController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No logged in user');
      }

      // Load student data and reading levels in parallel
      final results = await Future.wait([
        _loadStudentData(user.id),
        _loadReadingLevels(),
      ]);

      final student = results[0] as Student;
      final levels = results[1] as List<Map<String, dynamic>>;

      setState(() {
        _currentStudent = student;
        _readingLevels = levels;
        
        // Populate controllers
        _nameController.text = student.studentName;
        _lrnController.text = student.studentLrn ?? '';
        _usernameController.text = student.username ?? '';
        _gradeController.text = student.studentGrade ?? '';
        _sectionController.text = student.studentSection ?? '';
        _selectedLevelId = student.currentReadingLevelId;
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _errorMessage = 'Failed to load profile data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<Student> _loadStudentData(String userId) async {
    if (!Validators.isValidUUID(userId)) {
      throw Exception('Invalid user ID');
    }

    final response = await DatabaseHelpers.safeGetSingle(
      supabase: supabase,
      table: 'students',
      id: userId,
    );

    if (response == null) {
      throw Exception('Student record not found');
    }

    try {
      return Student.fromJson(response);
    } catch (e) {
      throw Exception('Failed to parse student data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _loadReadingLevels() async {
    try {
      final response = await DatabaseHelpers.safeGetList(
        supabase: supabase,
        table: 'reading_levels',
        orderBy: 'level_number',
        ascending: true,
      );

      // Validate and filter reading levels
      return response
          .where((level) {
            final id = DatabaseHelpers.safeStringFromResult(level, 'id');
            final levelNumber = DatabaseHelpers.safeIntFromResult(level, 'level_number');
            return id.isNotEmpty && levelNumber > 0;
          })
          .toList();
    } catch (e) {
      debugPrint('Error loading reading levels: $e');
      return [];
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedImageFile = pickedFile;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<bool> _checkDuplicateLRN(String lrn, String excludeStudentId) async {
    try {
      if (!Validators.isValidUUID(excludeStudentId)) {
        return false;
      }

      // Check for duplicate LRN excluding current student
      final students = await DatabaseHelpers.safeGetList(
        supabase: supabase,
        table: 'students',
        filters: {'student_lrn': lrn},
        limit: 10,
      );

      // Filter out current student
      return students.any((student) {
        final id = DatabaseHelpers.safeStringFromResult(student, 'id');
        return id.isNotEmpty && id != excludeStudentId;
      });
    } catch (e) {
      debugPrint('Error checking duplicate LRN: $e');
      return false;
    }
  }

  Future<bool> _checkDuplicateUsername(String username, String excludeUserId) async {
    try {
      if (!Validators.isValidUUID(excludeUserId)) {
        return false;
      }

      // Check in users table first (unique constraint)
      final users = await DatabaseHelpers.safeGetList(
        supabase: supabase,
        table: 'users',
        filters: {'username': username},
        limit: 10,
      );

      // Check if any user (other than current) has this username
      return users.any((user) {
        final id = DatabaseHelpers.safeStringFromResult(user, 'id');
        return id.isNotEmpty && id != excludeUserId;
      });
    } catch (e) {
      debugPrint('Error checking duplicate username: $e');
      return false;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLevelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reading level'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;
      final currentStudent = _currentStudent;
      if (user == null || currentStudent == null) {
        throw Exception('No logged in user');
      }

      final trimmedName = _nameController.text.trim();
      final trimmedLRN = _lrnController.text.trim();
      final trimmedUsername = _usernameController.text.trim();
      final trimmedGrade = _gradeController.text.trim();
      final trimmedSection = _sectionController.text.trim();

      // Check for duplicate LRN (if changed)
      final currentLRN = _currentStudent?.studentLrn ?? '';
      if (trimmedLRN != currentLRN) {
        final lrnExists = await _checkDuplicateLRN(trimmedLRN, user.id);
        if (lrnExists) {
          throw Exception('LRN already exists. Please use a different LRN.');
        }
      }

      // Check for duplicate username (if changed)
      final currentUsername = _currentStudent?.username ?? '';
      if (trimmedUsername != currentUsername) {
        final usernameExists = await _checkDuplicateUsername(trimmedUsername, user.id);
        if (usernameExists) {
          throw Exception('Username already exists. Please use a different username.');
        }
      }

      // Upload profile picture if selected
      String? profilePictureUrl;
      if (_pickedImageFile != null) {
        final uploadedUrl = await UserService.uploadProfilePicture(
          userId: user.id,
          role: 'student',
          filePath: _pickedImageFile!.path,
        );
        if (uploadedUrl != null) {
          profilePictureUrl = uploadedUrl;
        } else {
          throw Exception('Failed to upload profile picture');
        }
      }

      // Validate reading level ID
      if (_selectedLevelId != null && !Validators.isValidUUID(_selectedLevelId!)) {
        throw Exception('Invalid reading level ID');
      }

      // Validate student data before update
      final studentData = {
        'student_name': trimmedName,
        'student_lrn': trimmedLRN,
        'username': trimmedUsername,
      };
      final validationErrors = DataValidators.validateStudentData(studentData);
      if (DataValidators.hasErrors(validationErrors)) {
        throw Exception(DataValidators.getErrorMessage(validationErrors));
      }

      // Update student record
      final updatePayload = <String, dynamic>{
        'student_name': trimmedName,
        'student_lrn': trimmedLRN,
        'username': trimmedUsername,
        'student_grade': trimmedGrade.isNotEmpty ? trimmedGrade : null,
        'student_section': trimmedSection.isNotEmpty ? trimmedSection : null,
        'current_reading_level_id': _selectedLevelId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
        updatePayload['profile_picture'] = profilePictureUrl;
      }

      // Remove null values
      updatePayload.removeWhere((key, value) => value == null);

      final updateSuccess = await DatabaseHelpers.safeUpdate(
        supabase: supabase,
        table: 'students',
        id: user.id,
        data: updatePayload,
      );

      if (!updateSuccess) {
        throw Exception('Failed to update student record');
      }

      // Update username in users table if changed
      if (trimmedUsername != currentUsername) {
        final userUpdateSuccess = await DatabaseHelpers.safeUpdate(
          supabase: supabase,
          table: 'users',
          id: user.id,
          data: {'username': trimmedUsername},
        );

        if (!userUpdateSuccess) {
          debugPrint('Warning: Failed to update username in users table');
          // Don't throw - student record was updated successfully
        }
      }

      // Update local preferences
      final updatedStudent = currentStudent.copyWith(
        studentName: trimmedName,
        studentLrn: trimmedLRN,
        username: trimmedUsername,
        studentGrade: trimmedGrade.isNotEmpty ? trimmedGrade : null,
        studentSection: trimmedSection.isNotEmpty ? trimmedSection : null,
        currentReadingLevelId: _selectedLevelId,
        profilePicture: profilePictureUrl ?? currentStudent.profilePicture,
      );
      await updatedStudent.saveToPrefs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
        
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage ?? 'Failed to update profile',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _currentStudent == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile Picture Section
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                backgroundImage: _pickedImageFile != null
                                    ? FileImage(File(_pickedImageFile!.path))
                                    : _currentStudent?.profilePicture != null
                                        ? NetworkImage(_currentStudent!.profilePicture!)
                                        : null,
                                child: _pickedImageFile == null &&
                                        (_currentStudent?.profilePicture == null ||
                                            _currentStudent!.profilePicture!.isEmpty)
                                    ? Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Name Field
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person,
                          validator: _validateName,
                        ),
                        const SizedBox(height: 16),

                        // LRN Field
                        _buildTextField(
                          controller: _lrnController,
                          label: 'LRN (Learner Reference Number)',
                          icon: Icons.numbers,
                          keyboardType: TextInputType.number,
                          validator: _validateLRN,
                        ),
                        const SizedBox(height: 16),

                        // Username Field
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Username',
                          icon: Icons.alternate_email,
                          validator: _validateUsername,
                        ),
                        const SizedBox(height: 16),

                        // Grade Field
                        _buildTextField(
                          controller: _gradeController,
                          label: 'Grade (Optional)',
                          icon: Icons.school,
                          validator: _validateGrade,
                        ),
                        const SizedBox(height: 16),

                        // Section Field
                        _buildTextField(
                          controller: _sectionController,
                          label: 'Section (Optional)',
                          icon: Icons.class_,
                          validator: _validateSection,
                        ),
                        const SizedBox(height: 16),

                        // Reading Level Dropdown
                        _buildReadingLevelDropdown(),
                        const SizedBox(height: 32),

                        // Error Message Display
                        if (_errorMessage != null && _isSaving == false)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Save Button
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Saving...'),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save),
                                    SizedBox(width: 8),
                                    Text('Save Changes', style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      ),
    );
  }

  Widget _buildReadingLevelDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedLevelId,
      decoration: InputDecoration(
        labelText: 'Reading Level *',
        prefixIcon: const Icon(Icons.book),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      ),
      items: _readingLevels.map((level) {
        final levelNumber = level['level_number'] as int?;
        final title = level['title'] as String?;
        final id = level['id'] as String?;
        
        return DropdownMenuItem<String>(
          value: id,
          child: Text(
            'Level ${levelNumber ?? 'N/A'}${title != null ? ': $title' : ''}',
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedLevelId = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a reading level';
        }
        return null;
      },
    );
  }

  // Validation Methods
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateLRN(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter LRN';
    }
    final trimmed = value.trim();
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'LRN must contain only numbers';
    }
    if (trimmed.length != 12) {
      return 'LRN must be exactly 12 digits';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter username';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Username must be at least 4 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  String? _validateGrade(String? value) {
    // Optional field, no validation needed
    return null;
  }

  String? _validateSection(String? value) {
    // Optional field, no validation needed
    return null;
  }
}

