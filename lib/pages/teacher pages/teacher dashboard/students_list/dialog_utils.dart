import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DialogUtils {
  static void showLoadingDialog(BuildContext context, String lottieAsset, String loadingText) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      barrierColor: Colors.transparent,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Lottie.asset(lottieAsset),
              ),
              const SizedBox(height: 12),
              Text(
                loadingText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> hideLoadingDialog(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}