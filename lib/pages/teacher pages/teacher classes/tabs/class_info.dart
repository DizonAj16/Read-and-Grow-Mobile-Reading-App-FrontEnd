import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClassInfoPage extends StatelessWidget {
  final Map<String, dynamic> classDetails;

  const ClassInfoPage({super.key, required this.classDetails});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<_ClassInfoItem> infoItems = [
      _ClassInfoItem(
        icon: Icons.class_outlined,
        label: "Class Name",
        value: classDetails['class_name'],
        color: colorScheme.primary,
      ),
      _ClassInfoItem(
        icon: Icons.school_outlined,
        label: "Grade Level",
        value: classDetails['grade_level'],
        color: Colors.blue.shade600,
      ),
      _ClassInfoItem(
        icon: Icons.assignment_outlined,
        label: "Section",
        value: classDetails['section'] ?? "N/A",
        color: Colors.teal.shade600,
      ),
      _ClassInfoItem(
        icon: Icons.people_outline,
        label: "Students",
        value: "${classDetails['student_count']}",
        color: Colors.deepPurple.shade600,
      ),
      _ClassInfoItem(
        icon: Icons.person_outline,
        label: "Teacher",
        value: classDetails['teacher_name'] ?? 'N/A',
        color: Colors.orange.shade600,
      ),
      _ClassInfoItem(
        icon: Icons.calendar_month_outlined,
        label: "School Year",
        value: classDetails['school_year'] ?? "N/A",
        color: Colors.green.shade600,
      ),
      _ClassInfoItem(
        icon: Icons.vpn_key_outlined,
        label: "Class Code",
        value: classDetails['classroom_code'] ?? "N/A",
        color: Colors.red.shade600,
        isCopyable: true,
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                mainAxisExtent: 120, // Fixed height for each card
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _InfoCard(item: infoItems[index]),
                childCount: infoItems.length,
              ),
            ),
          ),

          // Additional Info Section
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  "About This Class",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Manage your class settings and view detailed information about your students and activities.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final _ClassInfoItem item;

  const _InfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            item.isCopyable && item.value != "N/A"
                ? () {
                  Clipboard.setData(ClipboardData(text: item.value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Copied ${item.label} to clipboard"),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
                : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.color.withOpacity(0.03),
                item.color.withOpacity(0.08),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Label
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, size: 20, color: item.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Value
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.value,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isCopyable && item.value != "N/A")
                        Icon(
                          Icons.copy,
                          size: 18,
                          color: item.color.withOpacity(0.7),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassInfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isCopyable;

  const _ClassInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isCopyable = false,
  });
}
