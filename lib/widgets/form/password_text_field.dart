import 'package:flutter/material.dart';

// PasswordTextField is a reusable widget for password input with show/hide toggle
class PasswordTextField extends StatefulWidget {
  final String labelText;

  const PasswordTextField({
    super.key,
    required this.labelText,
  });

  @override
  _PasswordTextFieldState createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  // Tracks whether the password is obscured (hidden)
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = true; // Password is hidden by default
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: _isObscured, // Controls text visibility
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        filled: true,
        fillColor: const Color.fromARGB(52, 158, 158, 158),
        // Lock icon at the start
        prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.onSurface),
        // Eye icon to toggle password visibility
        suffixIcon: IconButton(
          icon: Icon(
            _isObscured ? Icons.visibility_off : Icons.visibility,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          // Toggle password visibility on press
          onPressed: () {
            setState(() {
              _isObscured = !_isObscured;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }
}
