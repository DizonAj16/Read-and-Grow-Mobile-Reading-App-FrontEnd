import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../api/parent_service.dart';
import '../../api/supabase_auth_service.dart';
import '../../widgets/navigation/page_transition.dart';
import '../auth pages/landing_page.dart';
import 'child_detail_page.dart';

class ParentDashboardPage extends StatefulWidget {
  final String parentId;

  const ParentDashboardPage({super.key, required this.parentId});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  bool _isLoading = true;
  List<ChildSummary> _children = [];

  @override
  void initState() {
    super.initState();
    _fetchChildrenData();
  }

  // Helper method to calculate quiz completion percentage - using same logic as ChildDetailPage
  double _calculateQuizCompletion(ChildSummary child) {
    // Use the exact same formula as ChildDetailPage: (completedQuizzes / totalQuizzes)
    return child.totalQuizzes > 0
        ? (child.completedQuizzes / child.totalQuizzes).clamp(0.0, 1.0)
        : 0.0;
  }

  // Helper method to get quiz progress text based on completion percentage
  String _getQuizProgressText(double percent) {
    if (percent >= 0.75) return 'Excellent Progress';
    if (percent >= 0.5) return 'Good Progress';
    if (percent > 0) return 'Needs Improvement';
    return 'No Quizzes Taken';
  }

  Future<void> _fetchChildrenData() async {
    setState(() => _isLoading = true);

    try {
      final parentService = ParentService();
      final childrenData = await parentService.getChildrenSummary(
        widget.parentId,
      );
      setState(() {
        _children = childrenData
            .map(
              (data) => ChildSummary(
                studentId: data['studentId'] as String,
                studentName: data['studentName'] as String,
                readingLevel: data['readingLevel'] as String,
                totalTasks: data['totalTasks'] as int,
                completedTasks: data['completedTasks'] as int,
                averageScore: data['averageScore'] as double,
                completedQuizzes: data['completedQuizzes'] as int,
                totalQuizzes: data['totalQuizzes'] as int,
                quizAverage: data['quizAverage'] as double,
                profilePicture: data['profile_picture'] as String?,
              ),
            )
            .toList();
      });
    } catch (e) {
      debugPrint('Error fetching children data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Logout function for parent
  Future<void> _logout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: Colors.red[700],
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Logout?",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Are you sure you want to logout?",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey[700],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Logging out...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Logout from Supabase
      await SupabaseAuthService.logout();

      // Clear any parent-specific preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('parent_id');
      await prefs.remove('parent_name');

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pushAndRemoveUntil(
          PageTransition(page: const LandingPage()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to logout. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surfaceVariant = Theme.of(context).colorScheme.surfaceVariant;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text(
          '👨‍👩‍👧‍👦 My Children',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 24),
              onPressed: _fetchChildrenData,
              tooltip: 'Refresh',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 24),
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: TextStyle(color: onSurface),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Children Data...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
            )
          : _children.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.child_care_outlined,
                        size: 80,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No children found',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Contact your child\'s teacher to link your account',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchChildrenData,
                  color: primaryColor,
                  backgroundColor: surface,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _children.length,
                    itemBuilder: (context, index) {
                      final child = _children[index];
                      debugPrint(
                        '📡 Loading children for parentId: ${widget.parentId}',
                      );

                      return _buildChildCard(context, child);
                    },
                  ),
                ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildSummary child) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surfaceVariant = Theme.of(context).colorScheme.surfaceVariant;
    final outline = Theme.of(context).colorScheme.outline;
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;
    final onPrimaryContainer = Theme.of(context).colorScheme.onPrimaryContainer;

    final readingCompletionPercent =
        child.totalTasks > 0 ? (child.completedTasks / child.totalTasks) : 0.0;

    final borderColor = readingCompletionPercent >= 0.75
        ? Colors.green
        : readingCompletionPercent >= 0.5
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        color: surface,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChildDetailPage(
                  studentId: child.studentId,
                  studentName: child.studentName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // PROFILE PICTURE
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: borderColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: primaryContainer,
                        backgroundImage: _getProfileImage(child),
                        child: _getProfileImage(child) == null
                            ? Text(
                                child.studentName.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // NAME
                          Text(
                            child.studentName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // READING LEVEL AND SCORE
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '📚 ${child.readingLevel} • ⭐ ${child.averageScore.toStringAsFixed(0)}% Avg',
                              style: TextStyle(
                                fontSize: 13,
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: outline,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(height: 1, thickness: 1, color: outline.withOpacity(0.3)),
                const SizedBox(height: 16),
                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatChip(
                      icon: Icons.quiz_outlined,
                      label: 'Quizzes',
                      value: '${child.completedQuizzes}',
                      color: Colors.orange[700]!,
                    ),
                    _buildStatChip(
                      icon: Icons.star_rounded,
                      label: 'Avg Score',
                      value: '${child.averageScore.toStringAsFixed(0)}%',
                      color: Colors.green[700]!,
                    ),
                    _buildStatChip(
                      icon: Icons.check_circle_rounded,
                      label: 'Completed',
                      value: child.totalTasks > 0
                          ? '${((child.completedTasks / child.totalTasks) * 100).toInt()}%'
                          : '0%',
                      color: primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reading Task Progress
                      _buildProgressItem(
                        icon: Icons.book_rounded,
                        title: 'Reading Tasks',
                        completed: child.completedTasks,
                        total: child.totalTasks,
                        percent: readingCompletionPercent,
                        color: primaryColor,
                        progressColor: _getProgressColor(readingCompletionPercent),
                      ),
                      const SizedBox(height: 16),

                      // Quiz Progress - Using same formula as ChildDetailPage with linear indicator
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.quiz_rounded,
                                  color: primaryColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Quizzes',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                '${child.completedQuizzes}/${child.totalQuizzes}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: outline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearPercentIndicator(
                            lineHeight: 8.0,
                            percent: _calculateQuizCompletion(child),
                            backgroundColor: outline.withOpacity(0.2),
                            progressColor: _getProgressColor(_calculateQuizCompletion(child)),
                            barRadius: const Radius.circular(4),
                            animation: true,
                            animationDuration: 1000,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getQuizProgressText(_calculateQuizCompletion(child)),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getProgressColor(_calculateQuizCompletion(child)),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${(_calculateQuizCompletion(child) * 100).toStringAsFixed(0)}% Complete',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: outline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required String title,
    required int completed,
    required int total,
    required double percent,
    required Color color,
    required Color progressColor,
  }) {
    final outline = Theme.of(context).colorScheme.outline;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
            ),
            Text(
              '$completed/$total',
              style: TextStyle(
                fontSize: 12,
                color: outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 8.0,
          percent: percent.clamp(0.0, 1.0),
          backgroundColor: outline.withOpacity(0.2),
          progressColor: progressColor,
          barRadius: const Radius.circular(4),
          animation: true,
          animationDuration: 1000,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getProgressText(percent),
              style: TextStyle(
                fontSize: 11,
                color: progressColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(percent * 100).toStringAsFixed(0)}% Complete',
              style: TextStyle(
                fontSize: 11,
                color: outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final outline = Theme.of(context).colorScheme.outline;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: outline,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percent) {
    if (percent >= 0.75) return Colors.green;
    if (percent >= 0.5) return Colors.orange;
    return Colors.red;
  }

  String _getProgressText(double percent) {
    if (percent >= 0.75) return 'Excellent Progress';
    if (percent >= 0.5) return 'Good Progress';
    if (percent > 0) return 'Needs Improvement';
    return 'No Progress Yet';
  }
}

ImageProvider<Object>? _getProfileImage(ChildSummary child) {
  final pic = child.profilePicture;
  if (pic == null || pic.isEmpty) return null;

  // If it already starts with http, treat it as full URL
  if (pic.startsWith('http')) {
    return NetworkImage(pic);
  }

  // Otherwise, generate the Supabase public URL
  final profileUrl =
      Supabase.instance.client.storage.from('document').getPublicUrl(pic);

  debugPrint('Profile URL for ${child.studentName}: $profileUrl');

  return NetworkImage(profileUrl);
}

class ChildSummary {
  final String studentId;
  final String studentName;
  final String readingLevel;
  final int totalTasks;
  final int completedTasks;
  final double averageScore;
  final int completedQuizzes;
  final int totalQuizzes;
  final double quizAverage;
  final String? profilePicture;

  ChildSummary({
    required this.studentId,
    required this.studentName,
    required this.readingLevel,
    required this.totalTasks,
    required this.completedTasks,
    required this.averageScore,
    required this.completedQuizzes,
    required this.totalQuizzes,
    required this.quizAverage,
    this.profilePicture,
  });
}