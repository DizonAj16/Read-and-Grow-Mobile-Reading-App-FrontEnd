import 'package:flutter/material.dart';
import '../../widgets/email_text_field.dart';
import '../../widgets/password_text_field.dart';
import '../../widgets/login_button.dart';
import '../../widgets/page_transition.dart';
import '../../widgets/theme_toggle_button.dart';
import 'login_page.dart';

class SignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                      CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person_add,
                          size: 90,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Sign Up",
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
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.background,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 20),
                          EmailTextField(labelText: "Email"),
                          SizedBox(height: 20),
                          PasswordTextField(labelText: "Password"),
                          SizedBox(height: 20),
                          PasswordTextField(labelText: "Confirm Password"),
                          SizedBox(height: 20),
                          LoginButton(
                            text: "Sign Up",
                            onPressed: () {
                              // Add sign-up logic here
                            },
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account?",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onBackground,
                                    ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(PageTransition(page: LoginPage()));
                                },
                                child: Text(
                                  "Log In",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Color(0xFF2575FC),
                                      ),
                                ),
                              ),
                            ],
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
