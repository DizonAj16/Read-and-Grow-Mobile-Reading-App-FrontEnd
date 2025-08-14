import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DialogUtils {
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 75,
                    height: 75,
                    child: Lottie.asset(
                      'assets/animation/loading_rainbow.json',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color:
                          Colors
                              .black87, // Changed from surface to black for better contrast
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  static Future<void> showSuccessDialog(
    BuildContext context,
    String message,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Lottie.asset('assets/animation/success.json'),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
    );
    await Future.delayed(const Duration(milliseconds: 2100));
    Navigator.of(context).pop();
  }

  static void showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 35),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
