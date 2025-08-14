import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DialogUtils {
  static void showLoadingDialog(
    BuildContext context,
    String lottieAsset,
    String loadingText,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
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
                      color: Colors.black87, // Changed for better contrast
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
