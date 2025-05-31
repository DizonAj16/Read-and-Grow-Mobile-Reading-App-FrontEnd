import 'package:flutter/material.dart';
import '../../widgets/appbar/theme_toggle_button.dart';
import '../../widgets/buttons/login_button.dart';
import '../../widgets/form/email_text_field.dart';
import '../../widgets/form/password_text_field.dart';
import '../../widgets/navigation/page_transition.dart';
import 'login_page.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  Widget _buildHeader(BuildContext context) => Column(
        children: [
          const SizedBox(height: 50),
          CircleAvatar(
            radius: 80,
            backgroundColor: Theme.of(context).colorScheme.onPrimary,
            child: Icon(
              Icons.person_add,
              size: 90,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Sign Up",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 80),
        ],
      );

  Widget _buildSignUpForm(BuildContext context) => Container(
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
            EmailTextField(labelText: "Email"),
            const SizedBox(height: 20),
            PasswordTextField(labelText: "Password"),
            const SizedBox(height: 20),
            PasswordTextField(labelText: "Confirm Password"),
            const SizedBox(height: 20),
            LoginButton(
              text: "Sign Up",
              onPressed: () {
                // Add sign-up logic here
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account?",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(PageTransition(page: LoginPage()));
                  },
                  child: Text(
                    "Log In",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ],
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
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        actions: [
          ThemeToggleButton(iconColor: Theme.of(context).colorScheme.onPrimary),
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
                    Expanded(child: _buildSignUpForm(context)),
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
