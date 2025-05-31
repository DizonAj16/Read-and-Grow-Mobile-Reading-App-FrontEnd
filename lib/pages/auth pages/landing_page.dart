import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../widgets/appbar/theme_toggle_button.dart';
import '../../widgets/navigation/page_transition.dart';
import 'choose_role_page.dart'; // Import the new ChooseLoginPage

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Blended background image with color overlay for effect
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
              BlendMode.softLight,
            ),
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/background/480681008_1020230633459316_6070422237958140538_n.jpg',
                fit: BoxFit.fill,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          // Main content column
          Column(
            children: [
              const SizedBox(height: 80),
              // Animated hello illustration
              Lottie.asset('assets/animation/hello.json', height: 400),
              // App title
              Text(
                "Read & Grow",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 5),
              // App subtitle/description
              Text(
                "Mobile Reading App For Elementary School Learners",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const Spacer(),
              // Welcome card with login and sign up buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome message
                    Text(
                      "Welcome",
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 10),
                    // Short description
                    Text(
                      "Start your reading journey today with our platform.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.8),
                          ),
                    ),
                    const SizedBox(height: 20),
                    // Login button navigates to ChooseRolePage (login mode)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageTransition(
                            page: ChooseRolePage(showLogin: true), // Show login roles
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        "Login",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Sign Up button navigates to ChooseRolePage (sign up mode)
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageTransition(
                            page: ChooseRolePage(showLogin: false), // Show sign up roles
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        "Sign Up",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Theme toggle button positioned at the top-right corner
          Positioned(
            top: 40,
            right: 0,
            child: ThemeToggleButton(iconColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
