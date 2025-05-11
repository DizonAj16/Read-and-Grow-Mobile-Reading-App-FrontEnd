import 'package:flutter/material.dart';
import '../../widgets/password_text_field.dart';
import '../../widgets/login_button.dart';
import '../../widgets/page_transition.dart';
import '../../widgets/theme_toggle_button.dart';
import '../admin pages/admin_page.dart';
import 'login_page.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // AppBar with theme toggle button
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          ThemeToggleButton(iconColor: Colors.white),
        ],
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Container(
              // Gradient background for the login page
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
              child: Column(
                children: [
                  Column(
                    children: [
                      SizedBox(height: 50),
                      // Admin icon
                      CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 90,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 5),
                      // Page title
                      Text(
                        "Admin Login",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 80),
                    ],
                  ),
                  Expanded(
                    child: Container(
                      // Login form container
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 20),
                          // Password input field
                          PasswordTextField(labelText: "Password"),
                          SizedBox(height: 20),
                          // Login button
                          LoginButton(
                            text: "Login",
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminPage(),
                                ),
                                (route) => false, // Removes all previous routes
                              );
                            },
                          ),
                          Spacer(),
                          // Button to navigate to teacher/student login page
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(PageTransition(page: LoginPage()));
                            },
                            child: Text(
                              "Teacher/Student Login",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
