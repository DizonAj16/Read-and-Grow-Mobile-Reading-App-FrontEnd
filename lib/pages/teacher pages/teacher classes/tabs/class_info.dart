import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import '../add_lesson_and_quiz/add_lesson_and_quiz.dart';
import '../add_lesson_screen.dart';
import '../add_quiz_screen.dart';

class ClassInfoPage extends StatefulWidget {
  final Map<String, dynamic> classDetails;

  const ClassInfoPage({super.key, required this.classDetails});

  @override
  State<ClassInfoPage> createState() => _ClassInfoPageState();
}

class _ClassInfoPageState extends State<ClassInfoPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show shimmer only if classDetails is empty
    final isLoading = widget.classDetails.isEmpty;

    return Scaffold(
      body: isLoading
          ? _buildShimmerLoading()
          : _buildContent(theme, colorScheme),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.book),
                  title: const Text('Add Lesson'),
                  onTap: () {
                    Navigator.pop(context);
                    _onAddLesson();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.quiz),
                  title: const Text('Add Quiz'),
                  onTap: () {
                    Navigator.pop(context);
                    _onAddQuiz();
                  },
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _onAddLesson() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddLessonScreen(
          readingLevelId: null,
          classRoomId: widget.classDetails['id'],
        ),
      ),
    );
  }

  void _onAddQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddLessonWithQuizScreen(
          readingLevelId: widget.classDetails['reading_level_id'],
          classDetails: widget.classDetails,
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    final List<_ClassInfoItem> infoItems = [
      _ClassInfoItem(
        icon: Icons.class_outlined,
        label: "Class Name",
        value: widget.classDetails['class_name'],
        color: colorScheme.primary,
      ),
      _ClassInfoItem(
        icon: Icons.school_outlined,
        label: "Grade Level",
        value: widget.classDetails['grade_level'],
        color: Colors.blue.shade600,
      ),
      _ClassInfoItem(
        icon: Icons.assignment_outlined,
        label: "Section",
        value: widget.classDetails['section'] ?? "N/A",
        color: Colors.teal.shade600,
      ),
      _ClassInfoItem(
        icon: Icons.people_outline,
        label: "Students",
        value: "${widget.classDetails['student_count']}",
        color: Colors.deepPurple.shade600,
      ),
      _ClassInfoItem(
        icon: Icons.person_outline,
        label: "Teacher",
        value: widget.classDetails['teacher_name'] ?? 'N/A',
        color: Colors.orange.shade600,
      ),
      _ClassInfoItem(
        icon: Icons.calendar_month_outlined,
        label: "School Year",
        value: widget.classDetails['school_year'] ?? "N/A",
        color: Colors.green.shade600,
      ),
      _ClassInfoItem(
        icon: Icons.vpn_key_outlined,
        label: "Class Code",
        value: widget.classDetails['classroom_code'] ?? "N/A",
        color: Colors.red.shade600,
        isCopyable: true,
      ),
    ];

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              mainAxisExtent: 160,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _InfoCard(item: infoItems[index]),
              childCount: infoItems.length,
            ),
          ),
        ),
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
              const SizedBox(height: 12),
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
    );
  }

  Widget _buildShimmerLoading() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              mainAxisExtent: 160,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _ShimmerInfoCard(),
              childCount: 7,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _ShimmerText(width: 120, height: 24),
              const SizedBox(height: 12),
              _ShimmerText(width: double.infinity, height: 80),
            ]),
          ),
        ),
      ],
    );
  }
}

// ----------------- Other supporting classes remain unchanged -----------------
class _ShimmerInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _ShimmerText extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerText({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
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
        onTap: item.isCopyable && item.value != "N/A"
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
                  Flexible(
                    child: Text(
                      item.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            item.value,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isCopyable && item.value != "N/A")
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.copy,
                              size: 20,
                              color: item.color.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ],
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
