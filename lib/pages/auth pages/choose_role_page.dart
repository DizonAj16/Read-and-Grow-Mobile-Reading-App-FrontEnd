import 'package:flutter/material.dart';
import 'login_page.dart';
import 'admin_login_page.dart';
import 'sign_up_page.dart';
import '../../widgets/choose_role_card.dart';

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
          onTap: () => Navigator.of(context).push(_slideRoute(LoginPage())),
        ),
        _roleOption(
          icon: Icons.person_2_outlined,
          label: 'Teacher',
          color: Colors.orange,
          onTap: () => Navigator.of(context).push(_slideRoute(LoginPage())),
        ),
        _roleOption(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Admin',
          color: Colors.green,
          onTap: () => Navigator.of(context).push(_slideRoute(AdminLoginPage())),
        ),
      ];
    } else {
      return [
        _roleOption(
          icon: Icons.school_outlined,
          label: 'Student',
          color: Colors.blue,
          onTap: () => Navigator.of(context).push(_slideRoute(SignUpPage())),
        ),
        _roleOption(
          icon: Icons.person_2_outlined,
          label: 'Teacher',
          color: Colors.orange,
          onTap: () => Navigator.of(context).push(_slideRoute(SignUpPage())),
        ),
      ];
    }
  }

  static Route _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Slide from right
        const end = Offset.zero;
        const curve = Curves.ease;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: Container(
        width: double.infinity,
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
    );
  }
}
