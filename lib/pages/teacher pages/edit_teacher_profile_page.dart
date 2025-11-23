import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../api/user_service.dart';
import '../../models/teacher_model.dart';
import '../../utils/validators.dart';
import '../../utils/data_validators.dart';
import '../../utils/database_helpers.dart';

class EditTeacherProfilePage extends StatefulWidget {
  const EditTeacherProfilePage({super.key});

  @override
  State<EditTeacherProfilePage> createState() => _EditTeacherProfilePageState();
}

class _EditTeacherProfilePageState extends State<EditTeacherProfilePage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _positionController;
  late TextEditingController _usernameController;
  
  // State variables
  Teacher? _currentTeacher;
  XFile? _pickedImageFile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _positionController = TextEditingController();
    _usernameController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    _usernameController.dispose();
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

      if (!Validators.isValidUUID(user.id)) {
        throw Exception('Invalid user ID');
      }

      final teacherData = await _loadTeacherData(user.id);

      setState(() {
        _currentTeacher = teacherData;
        
        // Populate controllers
        _nameController.text = teacherData.name;
        _emailController.text = teacherData.email ?? '';
        _positionController.text = teacherData.position ?? '';
        _usernameController.text = teacherData.username ?? '';
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading teacher data: $e');
      setState(() {
        _errorMessage = 'Failed to load profile data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<Teacher> _loadTeacherData(String userId) async {
    try {
      // Try to load from Supabase
      final response = await DatabaseHelpers.safeGetSingle(
        supabase: supabase,
        table: 'teachers',
        id: userId,
      );

      if (response == null) {
        // Fallback to SharedPreferences
        try {
          final teacher = await Teacher.fromPrefs();
          return teacher;
        } catch (e) {
          throw Exception('Teacher record not found');
        }
      }

      // Also get username from users table
      final userResponse = await DatabaseHelpers.safeGetSingle(
        supabase: supabase,
        table: 'users',
        id: userId,
      );

      final teacherJson = Map<String, dynamic>.from(response);
      if (userResponse != null) {
        teacherJson['username'] = DatabaseHelpers.safeStringFromResult(userResponse, 'username');
      }

      return Teacher.fromJson(teacherJson);
    } catch (e) {
      debugPrint('Error parsing teacher data: $e');
      throw Exception('Failed to parse teacher data');
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

  Future<bool> _checkDuplicateEmail(String email, String excludeUserId) async {
    try {
      if (!Validators.isValidUUID(excludeUserId)) {
        return false;
      }

      // Check for duplicate email excluding current teacher
      final teachers = await DatabaseHelpers.safeGetList(
        supabase: supabase,
        table: 'teachers',
        filters: {'teacher_email': email},
        limit: 10,
      );

      // Filter out current teacher
      return teachers.any((teacher) {
        final id = DatabaseHelpers.safeStringFromResult(teacher, 'id');
        return id.isNotEmpty && id != excludeUserId;
      });
    } catch (e) {
      debugPrint('Error checking duplicate email: $e');
      return false;
    }
  }

  Future<bool> _checkDuplicateUsername(String username, String excludeUserId) async {
    try {
      if (!Validators.isValidUUID(excludeUserId)) {
        return false;
      }

      // Check in users table (unique constraint)
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

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;
      final currentTeacher = _currentTeacher;
      if (user == null || currentTeacher == null) {
        throw Exception('No logged in user');
      }

      final trimmedName = _nameController.text.trim();
      final trimmedEmail = _emailController.text.trim();
      final trimmedPosition = _positionController.text.trim();
      final trimmedUsername = _usernameController.text.trim();

      // Check for duplicate email (if changed)
      final currentEmail = _currentTeacher?.email ?? '';
      if (trimmedEmail.isNotEmpty && trimmedEmail != currentEmail) {
        final emailExists = await _checkDuplicateEmail(trimmedEmail, user.id);
        if (emailExists) {
          throw Exception('Email already exists. Please use a different email.');
        }
      }

      // Check for duplicate username (if changed)
      final currentUsername = _currentTeacher?.username ?? '';
      if (trimmedUsername.isNotEmpty && trimmedUsername != currentUsername) {
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
          role: 'teacher',
          filePath: _pickedImageFile!.path,
        );
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          profilePictureUrl = uploadedUrl;
        } else {
          throw Exception('Failed to upload profile picture');
        }
      }

      // Validate teacher data before update
      final teacherData = {
        'teacher_name': trimmedName,
        'teacher_email': trimmedEmail.isNotEmpty ? trimmedEmail : null,
        'teacher_position': trimmedPosition.isNotEmpty ? trimmedPosition : null,
      };
      final validationErrors = DataValidators.validateTeacherData(teacherData);
      if (DataValidators.hasErrors(validationErrors)) {
        throw Exception(DataValidators.getErrorMessage(validationErrors));
      }

      // Update teacher record
      final updatePayload = <String, dynamic>{
        'teacher_name': trimmedName,
        'teacher_position': trimmedPosition.isNotEmpty ? trimmedPosition : null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Only update email if it's not empty and changed
      if (trimmedEmail.isNotEmpty && trimmedEmail != currentEmail) {
        updatePayload['teacher_email'] = trimmedEmail;
      }

      if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
        updatePayload['profile_picture'] = profilePictureUrl;
      }

      // Remove null values
      updatePayload.removeWhere((key, value) => value == null);

      final updateSuccess = await DatabaseHelpers.safeUpdate(
        supabase: supabase,
        table: 'teachers',
        id: user.id,
        data: updatePayload,
      );

      if (!updateSuccess) {
        throw Exception('Failed to update teacher record');
      }

      // Update username in users table if changed
      if (trimmedUsername.isNotEmpty && trimmedUsername != currentUsername) {
        final userUpdateSuccess = await DatabaseHelpers.safeUpdate(
          supabase: supabase,
          table: 'users',
          id: user.id,
          data: {'username': trimmedUsername},
        );

        if (!userUpdateSuccess) {
          debugPrint('Warning: Failed to update username in users table');
          // Don't throw - teacher record was updated successfully
        }
      }

      // Update local preferences
      final updatedTeacher = Teacher(
        id: currentTeacher.id,
        userId: currentTeacher.userId ?? int.tryParse(user.id),
        name: trimmedName,
        position: trimmedPosition.isNotEmpty ? trimmedPosition : null,
        email: trimmedEmail.isNotEmpty ? trimmedEmail : currentTeacher.email,
        username: trimmedUsername.isNotEmpty ? trimmedUsername : currentTeacher.username,
        profilePicture: profilePictureUrl ?? currentTeacher.profilePicture,
        createdAt: currentTeacher.createdAt,
        updatedAt: DateTime.now(),
      );
      await updatedTeacher.saveToPrefs();

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
          : _errorMessage != null && _currentTeacher == null
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
                                    : _currentTeacher?.profilePicture != null &&
                                            _currentTeacher!.profilePicture!.isNotEmpty
                                        ? NetworkImage(_currentTeacher!.profilePicture!)
                                        : null,
                                child: _pickedImageFile == null &&
                                        (_currentTeacher?.profilePicture == null ||
                                            _currentTeacher!.profilePicture!.isEmpty)
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
                          label: 'Full Name *',
                          icon: Icons.person,
                          validator: _validateName,
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email (Optional)',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),

                        // Position Field
                        _buildTextField(
                          controller: _positionController,
                          label: 'Position (Optional)',
                          icon: Icons.work,
                          validator: _validatePosition,
                        ),
                        const SizedBox(height: 16),

                        // Username Field
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Username (Optional)',
                          icon: Icons.alternate_email,
                          validator: _validateUsername,
                        ),
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

  String? _validateEmail(String? value) {
    // Optional field, but if provided, must be valid
    if (value != null && value.trim().isNotEmpty) {
      final trimmed = value.trim();
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(trimmed)) {
        return 'Please enter a valid email address';
      }
    }
    return null;
  }

  String? _validatePosition(String? value) {
    // Optional field, no validation needed
    return null;
  }

  String? _validateUsername(String? value) {
    // Optional field, but if provided, must be valid
    if (value != null && value.trim().isNotEmpty) {
      final trimmed = value.trim();
      if (trimmed.length < 4) {
        return 'Username must be at least 4 characters';
      }
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
        return 'Username can only contain letters, numbers, and underscores';
      }
    }
    return null;
  }
}

