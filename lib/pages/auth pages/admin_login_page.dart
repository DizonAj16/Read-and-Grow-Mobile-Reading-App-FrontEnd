import 'package:flutter/material.dart';
import '../../widgets/appbar/theme_toggle_button.dart';
import '../../widgets/buttons/login_button.dart';
import '../../widgets/form/password_text_field.dart';
import '../admin pages/admin_page.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  Widget _buildHeader(BuildContext context) => Column(
        children: [
          const SizedBox(height: 50),
          CircleAvatar(
            radius: 80,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.admin_panel_settings,
              size: 90,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Admin Login",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 80),
        ],
      );

  Widget _buildLoginForm(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            PasswordTextField(labelText: "Password"),
            const SizedBox(height: 20),
            LoginButton(
              text: "Login",
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminPage(),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      );

  Widget _buildBackground(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ThemeToggleButton(iconColor: Colors.white),
        ],
      ),
      body: Stack(
        children: [
          _buildBackground(context),
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(child: _buildLoginForm(context)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
