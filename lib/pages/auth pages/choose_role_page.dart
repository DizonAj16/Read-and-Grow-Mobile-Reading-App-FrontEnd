import 'package:deped_reading_app_laravel/pages/auth%20pages/student_signup_page.dart';
import 'package:deped_reading_app_laravel/pages/auth%20pages/teacher_signup_page.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'admin_login_page.dart';
import '../../widgets/navigation/page_transition.dart';

class ChooseRolePage extends StatelessWidget {
  final bool showLogin;
  const ChooseRolePage({super.key, this.showLogin = true});

  List<Map<String, dynamic>> _roleOptions(BuildContext context) {
    if (showLogin) {
      return [
        _roleOption(
          icon: Icons.school_outlined,
          label: 'Student',
          color: Colors.blue,
          onTap: () => Navigator.of(context).push(PageTransition(page: LoginPage())),
        ),
        _roleOption(
          icon: Icons.person_2_outlined,
          label: 'Teacher',
          color: Colors.orange,
          onTap: () => Navigator.of(context).push(PageTransition(page: LoginPage())),
        ),
        _roleOption(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Admin',
          color: Colors.green,
          onTap: () => Navigator.of(context).push(PageTransition(page: AdminLoginPage())),
        ),
        _roleOption(
          icon: Icons.family_restroom,
          label: 'Parent',
          color: Colors.purple,
          onTap: () => Navigator.of(context).push(PageTransition(page: AdminLoginPage())),
        ),
      ];
    } else {
      return [
        _roleOption(
          icon: Icons.school_outlined,
          label: 'Student',
          color: Colors.blue,
          onTap: () => Navigator.of(context).push(PageTransition(page: StudentSignUpPage())),
        ),
        _roleOption(
          icon: Icons.person_2_outlined,
          label: 'Teacher',
          color: Colors.orange,
          onTap: () => Navigator.of(context).push(PageTransition(page: TeacherSignUpPage())),
        ),
      ];
    }
  }

  static Map<String, dynamic> _roleOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      {
        'icon': icon,
        'label': label,
        'color': color,
        'onTap': onTap,
      };

  @override
  Widget build(BuildContext context) {
    final options = _roleOptions(context);

    return Scaffold(
      body: Stack(
        children: [
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
          Container(
            color: Colors.black.withOpacity(0.35),
            width: double.infinity,
            height: double.infinity,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Back',
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  showLogin ? "Login as" : "Sign Up as",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
                const SizedBox(height: 30),
                ...options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: ChooseRoleCard(
                      icon: option['icon'] as IconData,
                      label: option['label'] as String,
                      color: option['color'] as Color,
                      onTap: option['onTap'] as VoidCallback,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChooseRoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ChooseRoleCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 260,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(width: 18),
              Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

