import 'package:supabase_flutter/supabase_flutter.dart';
import 'validators.dart';

/// Data layer validators for database operations
/// Validates data before insertion/update to prevent constraint violations

class DataValidators {
  final supabase = Supabase.instance.client;

  /// Validate student data before database operations
  static Map<String, String?> validateStudentData(Map<String, dynamic> data) {
    final errors = <String, String?>{};

    // Validate student_name (required, NOT NULL)
    final name = data['student_name'] as String?;
    errors['student_name'] = Validators.validateName(name, fieldName: 'Student name');

    // Validate student_lrn (required, NOT NULL, UNIQUE)
    final lrn = data['student_lrn'] as String?;
    errors['student_lrn'] = Validators.validateLRN(lrn);

    // Validate username (required for users table)
    final username = data['username'] as String?;
    if (username != null) {
      errors['username'] = Validators.validateUsername(username);
    }

    // Optional fields
    if (data['student_grade'] != null) {
      errors['student_grade'] = Validators.validateGrade(data['student_grade'] as String?);
    }
    if (data['student_section'] != null) {
      errors['student_section'] = Validators.validateSection(data['student_section'] as String?);
    }

    return errors;
  }

  /// Validate teacher data before database operations
  static Map<String, String?> validateTeacherData(Map<String, dynamic> data) {
    final errors = <String, String?>{};

    // Validate teacher_name (required, NOT NULL)
    final name = data['teacher_name'] as String?;
    errors['teacher_name'] = Validators.validateName(name, fieldName: 'Teacher name');

    // Validate teacher_email (required, NOT NULL, UNIQUE)
    final email = data['teacher_email'] as String?;
    errors['teacher_email'] = Validators.validateEmail(email);

    // Validate teacher_position (required, NOT NULL)
    final position = data['teacher_position'] as String?;
    errors['teacher_position'] = Validators.validateRequiredText(
      position,
      fieldName: 'Position',
      maxLength: 100,
    );

    return errors;
  }

  /// Validate classroom data before database operations
  static Map<String, String?> validateClassroomData(Map<String, dynamic> data) {
    final errors = <String, String?>{};

    // Validate class_name (required, NOT NULL)
    final className = data['class_name'] as String?;
    errors['class_name'] = Validators.validateRequiredText(
      className,
      fieldName: 'Class name',
      maxLength: 200,
    );

    // Validate classroom_code (required, NOT NULL, UNIQUE)
    final code = data['classroom_code'] as String?;
    errors['classroom_code'] = Validators.validateClassroomCode(code);

    // Optional fields
    if (data['section'] != null) {
      errors['section'] = Validators.validateSection(data['section'] as String?);
    }
    if (data['grade_level'] != null) {
      errors['grade_level'] = Validators.validateGrade(data['grade_level'] as String?);
    }

    return errors;
  }

  /// Validate task data before database operations
  static Map<String, String?> validateTaskData(Map<String, dynamic> data) {
    final errors = <String, String?>{};

    // Validate title (required, NOT NULL)
    final title = data['title'] as String?;
    errors['title'] = Validators.validateTitle(title ?? '', fieldName: 'Task title');

    // Optional fields
    if (data['description'] != null) {
      errors['description'] = Validators.validateOptionalText(
        data['description'] as String?,
        maxLength: 1000,
      );
    }

    // Validate time_limit_minutes if provided
    if (data['time_limit_minutes'] != null) {
      errors['time_limit_minutes'] = Validators.validateInteger(
        data['time_limit_minutes'].toString(),
        min: 1,
        max: 300,
        required: false,
      );
    }

    return errors;
  }

  /// Validate quiz data before database operations
  static Map<String, String?> validateQuizData(Map<String, dynamic> data) {
    final errors = <String, String?>{};

    // Validate title (required, NOT NULL)
    final title = data['title'] as String?;
    errors['title'] = Validators.validateTitle(title ?? '', fieldName: 'Quiz title');

    // Validate task_id (required, NOT NULL, FK)
    final taskId = data['task_id'] as String?;
    if (taskId == null || taskId.isEmpty) {
      errors['task_id'] = 'Task ID is required';
    } else if (!Validators.isValidUUID(taskId)) {
      errors['task_id'] = 'Invalid task ID format';
    }

    return errors;
  }

  /// Validate material data before database operations
  static Map<String, String?> validateMaterialData(Map<String, dynamic> data) {
    final errors = <String, String?>{};

    // Validate material_title (required, NOT NULL)
    final title = data['material_title'] as String?;
    errors['material_title'] = Validators.validateTitle(title ?? '', fieldName: 'Material title');

    // Validate material_file_url (required, NOT NULL)
    final fileUrl = data['material_file_url'] as String?;
    errors['material_file_url'] = Validators.validateRequiredText(
      fileUrl,
      fieldName: 'File URL',
    );

    // Validate class_room_id (required, NOT NULL, FK)
    final classRoomId = data['class_room_id'] as String?;
    if (classRoomId == null || classRoomId.isEmpty) {
      errors['class_room_id'] = 'Classroom ID is required';
    } else if (!Validators.isValidUUID(classRoomId)) {
      errors['class_room_id'] = 'Invalid classroom ID format';
    }

    // Validate uploaded_by (required, NOT NULL, FK)
    final uploadedBy = data['uploaded_by'] as String?;
    if (uploadedBy == null || uploadedBy.isEmpty) {
      errors['uploaded_by'] = 'Uploader ID is required';
    } else if (!Validators.isValidUUID(uploadedBy)) {
      errors['uploaded_by'] = 'Invalid uploader ID format';
    }

    return errors;
  }

  /// Validate assignment data before database operations
  static Map<String, String?> validateAssignmentData(Map<String, dynamic> data) {
    final errors = <String, String?>{};

    // Validate task_id (required, NOT NULL, FK)
    final taskId = data['task_id'] as String?;
    if (taskId == null || taskId.isEmpty) {
      errors['task_id'] = 'Task ID is required';
    } else if (!Validators.isValidUUID(taskId)) {
      errors['task_id'] = 'Invalid task ID format';
    }

    // Validate class_room_id (required, NOT NULL, FK)
    final classRoomId = data['class_room_id'] as String?;
    if (classRoomId == null || classRoomId.isEmpty) {
      errors['class_room_id'] = 'Classroom ID is required';
    } else if (!Validators.isValidUUID(classRoomId)) {
      errors['class_room_id'] = 'Invalid classroom ID format';
    }

    // Validate teacher_id (required, NOT NULL, FK)
    final teacherId = data['teacher_id'] as String?;
    if (teacherId == null || teacherId.isEmpty) {
      errors['teacher_id'] = 'Teacher ID is required';
    } else if (!Validators.isValidUUID(teacherId)) {
      errors['teacher_id'] = 'Invalid teacher ID format';
    }

    // Validate max_attempts if provided
    if (data['max_attempts'] != null) {
      final maxAttempts = data['max_attempts'];
      if (maxAttempts is int) {
        if (maxAttempts < 1 || maxAttempts > 10) {
          errors['max_attempts'] = 'Max attempts must be between 1 and 10';
        }
      } else {
        errors['max_attempts'] = 'Max attempts must be a number';
      }
    }

    return errors;
  }

  /// Validate student recording data before database operations
  static Map<String, String?> validateStudentRecordingData(Map<String, dynamic> data) {
    final errors = <String, String?>{};

    // Validate student_id (required, FK)
    final studentId = data['student_id'] as String?;
    if (studentId == null || studentId.isEmpty) {
      errors['student_id'] = 'Student ID is required';
    } else if (!Validators.isValidUUID(studentId)) {
      errors['student_id'] = 'Invalid student ID format';
    }

    // Validate task_id if provided (FK)
    if (data['task_id'] != null) {
      final taskId = data['task_id'] as String;
      if (!Validators.isValidUUID(taskId)) {
        errors['task_id'] = 'Invalid task ID format';
      }
    }

    // Validate recording_url or file_url
    final recordingUrl = data['recording_url'] as String? ?? data['file_url'] as String?;
    if (recordingUrl == null || recordingUrl.isEmpty) {
      errors['recording_url'] = 'Recording URL is required';
    }

    return errors;
  }

  /// Check if errors map has any errors
  static bool hasErrors(Map<String, String?> errors) {
    return errors.values.any((error) => error != null && error.isNotEmpty);
  }

  /// Get error message string from errors map
  static String getErrorMessage(Map<String, String?> errors) {
    final errorMessages = errors.values
        .where((error) => error != null && error.isNotEmpty)
        .toList();
    return errorMessages.join('\n');
  }
}

