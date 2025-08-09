import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmptyClassesWidget extends StatelessWidget {
  final VoidCallback onJoinClassPressed;
  final VoidCallback onRefreshPressed;

  const EmptyClassesWidget({
    Key? key,
    required this.onJoinClassPressed,
    required this.onRefreshPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade50.withOpacity(0.5),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.blue.shade100, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation Section
            _buildEmptyAnimation(),

            // Title Section
            _buildTitleText(),
            const SizedBox(height: 12),

            // Description Section
            _buildDescriptionText(),
            const SizedBox(height: 12),

            // Action Buttons Section
            _buildActionButtons(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAnimation() {
    return SizedBox(
      width: 220,
      height: 220,
      child: Lottie.asset(
        'assets/animation/empty_box.json',
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }

  Widget _buildTitleText() {
    return Text(
      "No Classrooms Yet!",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: Colors.deepPurple.shade700,
        height: 1.3,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescriptionText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        'Ask your teacher for a class code then tap the '
        '"Join Class" button below! 👇',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey.shade700,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        // Join Class Button
        ElevatedButton.icon(
          onPressed: onJoinClassPressed,
          icon: const Icon(Icons.school, size: 22),
          label: const Text(
            "Join Class Now",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
            shadowColor: colorScheme.primary.withOpacity(0.3),
          ),
        ),

        // Refresh Button
        TextButton.icon(
          onPressed: onRefreshPressed,
          icon: Icon(Icons.refresh, color: colorScheme.primary, size: 20),
          label: Text(
            "Try Again",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
