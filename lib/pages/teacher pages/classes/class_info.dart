import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClassInfoPage extends StatelessWidget {
  final Map<String, dynamic> classDetails;

  const ClassInfoPage({super.key, required this.classDetails});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final List<_ClassInfoItem> infoItems = [
      _ClassInfoItem(
        icon: Icons.class_,
        label: "Class Name",
        value: classDetails['class_name'],
        color: colorScheme.primary,
      ),
      _ClassInfoItem(
        icon: Icons.grade,
        label: "Grade Level",
        value: classDetails['grade_level'],
        color: Colors.blueAccent,
      ),
      _ClassInfoItem(
        icon: Icons.group,
        label: "Section",
        value: classDetails['section'] ?? "N/A",
        color: Colors.teal,
      ),
      _ClassInfoItem(
        icon: Icons.people_alt,
        label: "Students",
        value: "${classDetails['student_count']}",
        color: Colors.deepPurple,
      ),
      _ClassInfoItem(
        icon: Icons.person,
        label: "Teacher",
        value: classDetails['teacher_name'] ?? 'N/A',
        color: Colors.orangeAccent,
      ),
      _ClassInfoItem(
        icon: Icons.calendar_today,
        label: "School Year",
        value: classDetails['school_year'] ?? "N/A",
        color: Colors.green,
      ),
      _ClassInfoItem(
        icon: Icons.vpn_key,
        label: "Classroom Code",
        value: classDetails['classroom_code'] ?? "N/A",
        color: Colors.redAccent,
        isCopyable: true,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "📚 Class Information",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: infoItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 cards per row
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, index) {
              final item = infoItems[index];
              return _infoCard(context, item);
            },
          ),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context, _ClassInfoItem item) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: item.color.withOpacity(0.15),
                  radius: 18,
                  child: Icon(item.icon, size: 20, color: item.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: onSurface.withOpacity(0.65),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      item.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                  ),
                  if (item.isCopyable && item.value != "N/A")
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.copy, size: 20, color: item.color),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: item.value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${item.label} copied!"),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
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

  _ClassInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isCopyable = false,
  });
}
