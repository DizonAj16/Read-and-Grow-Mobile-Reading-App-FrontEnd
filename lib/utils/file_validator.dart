import 'dart:io';

/// Reusable file-size validation helpers shared across the app.
class FileValidator {
  /// Default maximum file size in MB
  static const double defaultMaxSizeMB = 5.0;

  /// Validation result codes
  static const String errorFileTooLarge = 'FILE_TOO_LARGE';
  static const String errorFileNotFound = 'FILE_NOT_FOUND';
  static const String success = 'SUCCESS';

  /// User-facing messages
  static String tooLargeMessage(double limitMB) =>
      'File too large. Maximum allowed is ${limitMB.toStringAsFixed(0)}MB. '
      'Contact administrator if you need a higher limit.';

  static String backendLimitMessage(double limitMB) =>
      'File size limit reached. Contact administrator.';

  /// Returns a JSON-compatible error response for backend validation
  static Map<String, String> backendErrorResponse() => {
        'error': backendLimitMessage(defaultMaxSizeMB),
      };

  /// Validates file size against a specified limit.
  ///
  /// Returns a [FileValidationResult] with validation status.
  static Future<FileValidationResult> validateFileSize(
    File file, {
    double limitMB = defaultMaxSizeMB,
  }) async {
    try {
      if (!await file.exists()) {
        return FileValidationResult(
          isValid: false,
          errorCode: errorFileNotFound,
          errorMessage: 'File not found. Please select a valid file.',
        );
      }

      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      if (fileSizeMB > limitMB) {
        return FileValidationResult(
          isValid: false,
          errorCode: errorFileTooLarge,
          errorMessage: tooLargeMessage(limitMB),
          actualSizeMB: fileSizeMB,
          limitMB: limitMB,
        );
      }

      return FileValidationResult(
        isValid: true,
        errorCode: success,
        actualSizeMB: fileSizeMB,
        limitMB: limitMB,
      );
    } catch (e) {
      return FileValidationResult(
        isValid: false,
        errorCode: 'ERROR',
        errorMessage: 'Error validating file: ${e.toString()}',
      );
    }
  }

  /// Validates file size from file path (convenience).
  static Future<FileValidationResult> validateFileSizeFromPath(
    String filePath, {
    double limitMB = defaultMaxSizeMB,
  }) async {
    final file = File(filePath);
    return validateFileSize(file, limitMB: limitMB);
  }

  /// Formats file size in bytes to human-readable format.
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

/// Reusable, top-level validation helper demanded by spec.
Future<FileValidationResult> validateFileSize(
  File file, {
  double limitMB = FileValidator.defaultMaxSizeMB,
}) {
  return FileValidator.validateFileSize(file, limitMB: limitMB);
}

/// Exception thrown when a file exceeds the allowed size.
class FileSizeLimitException implements Exception {
  final String message;
  final double? actualSizeMB;
  final double? limitMB;

  FileSizeLimitException(
    this.message, {
    this.actualSizeMB,
    this.limitMB,
  });

  Map<String, String> toJson() => {'error': message};

  @override
  String toString() => message;
}

/// Result of file validation
class FileValidationResult {
  final bool isValid;
  final String errorCode;
  final String? errorMessage;
  final double? actualSizeMB;
  final double? limitMB;

  FileValidationResult({
    required this.isValid,
    required this.errorCode,
    this.errorMessage,
    this.actualSizeMB,
    this.limitMB,
  });

  /// Returns a user-friendly error message
  String getUserMessage() {
    if (isValid) {
      return 'File is valid';
    }
    return errorMessage ?? 'File validation failed';
  }

  /// Returns detailed info for debugging
  String getDetailedInfo() {
    if (!isValid) {
      return getUserMessage();
    }
    return 'File size: ${actualSizeMB?.toStringAsFixed(2)}MB / ${limitMB?.toStringAsFixed(1)}MB';
  }
}

