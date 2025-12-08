/// Comprehensive validation utilities for the application
/// Provides reusable validators for forms and data validation

class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Username validation
  static String? validateUsername(String? value, {int minLength = 2, int maxLength = 30}) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      return 'Username must be at least $minLength characters';
    }
    if (trimmed.length > maxLength) {
      return 'Username must be at most $maxLength characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  // Password validation
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Name validation
  static String? validateName(String? value, {String fieldName = 'Name', int minLength = 2}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    if (value.trim().length > 100) {
      return '$fieldName must be at most 100 characters';
    }
    // Allow letters, spaces, hyphens, apostrophes
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value.trim())) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }
    return null;
  }

  // LRN (Learner Reference Number) validation
  static String? validateLRN(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'LRN is required';
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

  // Grade validation
  static String? validateGrade(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final trimmed = value.trim();
    // Allow common grade formats: "1", "Grade 1", "G1", etc.
    if (!RegExp(r'^(Grade\s?)?\d{1,2}$', caseSensitive: false).hasMatch(trimmed) &&
        !RegExp(r'^G\d{1,2}$', caseSensitive: false).hasMatch(trimmed)) {
      return 'Please enter a valid grade (e.g., "1", "Grade 1", "G1")';
    }
    return null;
  }

  // Section validation
  static String? validateSection(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final trimmed = value.trim();
    if (trimmed.length > 20) {
      return 'Section must be at most 20 characters';
    }
    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final trimmed = value.trim();
    // Allow common phone formats
    final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]+$');
    if (!phoneRegex.hasMatch(trimmed)) {
      return 'Please enter a valid phone number';
    }
    if (trimmed.replaceAll(RegExp(r'[\s\-\+\(\)]'), '').length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    return null;
  }

  // Text field validation (generic)
  static String? validateRequiredText(String? value, {String fieldName = 'Field', int? maxLength}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (maxLength != null && value.trim().length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  // Optional text field validation
  static String? validateOptionalText(String? value, {int? maxLength}) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    if (maxLength != null && value.trim().length > maxLength) {
      return 'Text must be at most $maxLength characters';
    }
    return null;
  }

  // Number validation
  static String? validateNumber(String? value, {num? min, num? max, bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'This field is required' : null;
    }
    final numValue = num.tryParse(value.trim());
    if (numValue == null) {
      return 'Please enter a valid number';
    }
    if (min != null && numValue < min) {
      return 'Value must be at least $min';
    }
    if (max != null && numValue > max) {
      return 'Value must be at most $max';
    }
    return null;
  }

  // Integer validation
  static String? validateInteger(String? value, {int? min, int? max, bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'This field is required' : null;
    }
    final intValue = int.tryParse(value.trim());
    if (intValue == null) {
      return 'Please enter a valid whole number';
    }
    if (min != null && intValue < min) {
      return 'Value must be at least $min';
    }
    if (max != null && intValue > max) {
      return 'Value must be at most $max';
    }
    return null;
  }

  // URL validation
  static String? validateUrl(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'URL is required' : null;
    }
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  // Date validation
  static String? validateDate(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Date is required' : null;
    }
    try {
      DateTime.parse(value.trim());
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  // Classroom code validation
  static String? validateClassroomCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Classroom code is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 4 || trimmed.length > 20) {
      return 'Classroom code must be between 4 and 20 characters';
    }
    // Allow alphanumeric and hyphens
    if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(trimmed)) {
      return 'Classroom code can only contain letters, numbers, and hyphens';
    }
    return null;
  }

  // Title validation
  static String? validateTitle(String? value, {String fieldName = 'Title', int maxLength = 200}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (trimmed.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  // Content/Description validation
  static String? validateContent(String? value, {String fieldName = 'Content', int? maxLength}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (maxLength != null && value.trim().length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  // Sanitize input (remove dangerous characters)
  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, multiLine: true), '')
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
  }

  // Validate UUID format
  static bool isValidUUID(String? value) {
    if (value == null || value.isEmpty) return false;
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(value);
  }

  // Validate file extension
  static String? validateFileExtension(String? fileName, List<String> allowedExtensions) {
    if (fileName == null || fileName.isEmpty) {
      return 'File name is required';
    }
    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return 'File type not allowed. Allowed types: ${allowedExtensions.join(', ')}';
    }
    return null;
  }

  // Validate file size (in bytes)
  static String? validateFileSize(int fileSizeBytes, int maxSizeBytes) {
    if (fileSizeBytes > maxSizeBytes) {
      final maxSizeMB = (maxSizeBytes / (1024 * 1024)).toStringAsFixed(2);
      return 'File size must be less than ${maxSizeMB}MB';
    }
    return null;
  }
}

