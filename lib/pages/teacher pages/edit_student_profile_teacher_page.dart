import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../api/user_service.dart';
import '../../models/student_model.dart';
import '../../utils/validators.dart';
import '../../utils/data_validators.dart';
import '../../utils/database_helpers.dart';

/// Teacher's page to edit student profile and assign reading level
class EditStudentProfileTeacherPage extends StatefulWidget {
  final String studentId;
  
  const EditStudentProfileTeacherPage({
    super.key,
    required this.studentId,
  });

  @override
  State<EditStudentProfileTeacherPage> createState() => _EditStudentProfileTeacherPageState();
}

class _EditStudentProfileTeacherPageState extends State<EditStudentProfileTeacherPage> {
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
      // Validate student ID
      if (!Validators.isValidUUID(widget.studentId)) {
        throw Exception('Invalid student ID');
      }

      // Load student data and reading levels in parallel
      final results = await Future.wait([
        _loadStudentData(widget.studentId),
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
        _errorMessage = 'Failed to load student data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<Student> _loadStudentData(String studentId) async {
    final response = await DatabaseHelpers.safeGetSingle(
      supabase: supabase,
      table: 'students',
      id: studentId,
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
      final currentStudent = _currentStudent;
      if (currentStudent == null) {
        throw Exception('No student data loaded');
      }

      final trimmedName = _nameController.text.trim();
      final trimmedLRN = _lrnController.text.trim();
      final trimmedUsername = _usernameController.text.trim();
      final trimmedGrade = _gradeController.text.trim();
      final trimmedSection = _sectionController.text.trim();

      // Check for duplicate LRN (if changed)
      final currentLRN = _currentStudent?.studentLrn ?? '';
      if (trimmedLRN != currentLRN) {
        final lrnExists = await _checkDuplicateLRN(trimmedLRN, widget.studentId);
        if (lrnExists) {
          throw Exception('LRN already exists. Please use a different LRN.');
        }
      }

      // Check for duplicate username (if changed)
      final currentUsername = _currentStudent?.username ?? '';
      if (trimmedUsername != currentUsername) {
        final usernameExists = await _checkDuplicateUsername(trimmedUsername, widget.studentId);
        if (usernameExists) {
          throw Exception('Username already exists. Please use a different username.');
        }
      }

      // Upload profile picture if selected
      String? profilePictureUrl;
      if (_pickedImageFile != null) {
        final uploadedUrl = await UserService.uploadProfilePicture(
          userId: widget.studentId,
          role: 'student',
          filePath: _pickedImageFile!.path,
        );
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
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
        id: widget.studentId,
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
          id: widget.studentId,
          data: {'username': trimmedUsername},
        );

        if (!userUpdateSuccess) {
          debugPrint('Warning: Failed to update username in users table');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                const Text('Student profile updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Student Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: colorScheme.primary.withOpacity(0.3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading student data...',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null && _currentStudent == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red.shade200,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Error Loading Data',
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            shadowColor: colorScheme.primary.withOpacity(0.3),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.refresh),
                              const SizedBox(width: 8),
                              Text(
                                'Retry',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.primary.withOpacity(0.03),
                        colorScheme.primary.withOpacity(0.01),
                        colorScheme.background,
                      ],
                      stops: const [0, 0.3, 0.7],
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Card
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.school,
                                size: 32,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Edit Student Profile',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Update student information and assign reading level',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Profile Picture Card
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Profile Picture',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Stack(
                                        children: [
                                          Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: colorScheme.primary.withOpacity(0.3),
                                                width: 3,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: colorScheme.primary.withOpacity(0.1),
                                                  blurRadius: 10,
                                                  spreadRadius: 2,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ClipOval(
                                              child: _pickedImageFile != null
                                                  ? Image.file(
                                                      File(_pickedImageFile!.path),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : _currentStudent?.profilePicture != null &&
                                                          _currentStudent!.profilePicture!.isNotEmpty
                                                      ? Image.network(
                                                          _currentStudent!.profilePicture!,
                                                          fit: BoxFit.cover,
                                                          loadingBuilder: (context, child, loadingProgress) {
                                                            if (loadingProgress == null) return child;
                                                            return Center(
                                                              child: CircularProgressIndicator(
                                                                value: loadingProgress.expectedTotalBytes != null
                                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                                        loadingProgress.expectedTotalBytes!
                                                                    : null,
                                                                color: colorScheme.primary,
                                                              ),
                                                            );
                                                          },
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Icon(
                                                              Icons.person,
                                                              size: 60,
                                                              color: colorScheme.onPrimaryContainer,
                                                            );
                                                          },
                                                        )
                                                      : Container(
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                              colors: [
                                                                colorScheme.primary.withOpacity(0.1),
                                                                colorScheme.primary.withOpacity(0.3),
                                                              ],
                                                            ),
                                                          ),
                                                          child: Icon(
                                                            Icons.person,
                                                            size: 60,
                                                            color: colorScheme.primary,
                                                          ),
                                                        ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: _pickImage,
                                              child: Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      colorScheme.primary,
                                                      colorScheme.primary.withOpacity(0.8),
                                                    ],
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 3,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.2),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ],
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
                                      const SizedBox(height: 12),
                                      Text(
                                        'Tap to upload new photo',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Personal Information Card
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Personal Information',
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),

                                      // Name Field
                                      _buildEnhancedTextField(
                                        controller: _nameController,
                                        label: 'Full Name',
                                        icon: Icons.person,
                                        validator: _validateName,
                                        isRequired: true,
                                      ),
                                      const SizedBox(height: 20),

                                      // LRN Field
                                      _buildEnhancedTextField(
                                        controller: _lrnController,
                                        label: 'Learner Reference Number (LRN)',
                                        icon: Icons.badge,
                                        validator: _validateLRN,
                                        isRequired: true,
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 20),

                                      // Username Field
                                      _buildEnhancedTextField(
                                        controller: _usernameController,
                                        label: 'Username',
                                        icon: Icons.alternate_email,
                                        validator: _validateUsername,
                                        isRequired: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Academic Information Card
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.school_outlined,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Academic Information',
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),

                                      // Grade Field
                                      _buildEnhancedTextField(
                                        controller: _gradeController,
                                        label: 'Grade Level',
                                        icon: Icons.grade,
                                        validator: _validateGrade,
                                        isRequired: false,
                                        hintText: 'e.g., Grade 6',
                                      ),
                                      const SizedBox(height: 20),

                                      // Section Field
                                      _buildEnhancedTextField(
                                        controller: _sectionController,
                                        label: 'Section',
                                        icon: Icons.groups,
                                        validator: _validateSection,
                                        isRequired: false,
                                        hintText: 'e.g., Section A',
                                      ),
                                      const SizedBox(height: 20),

                                      // Reading Level Dropdown
                                      _buildEnhancedReadingLevelDropdown(),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Error Message Display
                              if (_errorMessage != null && _isSaving == false)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.shade100,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        color: Colors.red.shade700,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Update Failed',
                                              style: textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _errorMessage!,
                                              style: textTheme.bodySmall?.copyWith(
                                                color: Colors.red.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Action Buttons
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(
                                          color: colorScheme.outline.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                        backgroundColor: colorScheme.surface,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.arrow_back),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Cancel',
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface.withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isSaving ? null : _saveProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 3,
                                        shadowColor: colorScheme.primary.withOpacity(0.4),
                                        disabledBackgroundColor: colorScheme.primary.withOpacity(0.5),
                                      ),
                                      child: _isSaving
                                          ? Row(
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
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Saving...',
                                                  style: textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.save_alt),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Save Changes',
                                                  style: textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              
                              // Help Text
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: colorScheme.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Fields marked with * are required. Make sure all information is accurate before saving.',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    required bool isRequired,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$label${isRequired ? ' *' : ''}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedReadingLevelDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.book_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Reading Level *',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedLevelId,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              prefixIcon: Icon(
                Icons.arrow_drop_down_circle_outlined,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
            ),
            items: _readingLevels.map((level) {
              final levelNumber = level['level_number'] as int?;
              final title = level['title'] as String?;
              final id = level['id'] as String?;
              
              return DropdownMenuItem<String>(
                value: id,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'L${levelNumber ?? '?'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title ?? 'Unknown Level',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
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
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            isExpanded: true,
            icon: Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            dropdownColor: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            elevation: 4,
            menuMaxHeight: 300,
          ),
        ),
      ],
    );
  }

  // Validation Methods
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter student name';
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
      return 'Username must be at least 2 characters';
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