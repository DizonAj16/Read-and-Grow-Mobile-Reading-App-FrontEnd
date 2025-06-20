import 'package:flutter/material.dart';

/// Success snackbar widget.

class SuccessSnackBar extends SnackBar {
  SuccessSnackBar({required String message})
    : super(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(top: 20, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        duration: Duration(seconds: 2),
      );
}
