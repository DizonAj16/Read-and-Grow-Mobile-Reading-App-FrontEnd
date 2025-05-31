import 'package:flutter/material.dart';

class EmailTextField extends StatelessWidget {
  final String labelText;
  final IconData? prefixIcon;

  const EmailTextField({
    super.key,
    required this.labelText,
    this.prefixIcon = Icons.email,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        filled: true,
        fillColor: const Color.fromARGB(52, 158, 158, 158),
        prefixIcon: Icon(prefixIcon, color: Theme.of(context).colorScheme.onSurface),
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
