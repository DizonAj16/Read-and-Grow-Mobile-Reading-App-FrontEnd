import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> _fetchChildrenData() async {
    setState(() => _isLoading = true);

    try {
      final parentService = ParentService();
      final childrenData = await parentService.getChildrenSummary(widget.parentId);

      setState(() {
        _children = childrenData.map((data) => ChildSummary(
              studentId: data['studentId'] as String,
              studentName: data['studentName'] as String,
              readingLevel: data['readingLevel'] as String,
              totalTasks: data['totalTasks'] as int,
              completedTasks: data['completedTasks'] as int,
              averageScore: data['averageScore'] as double,
              quizCount: data['quizCount'] as int,
              quizAverage: data['quizAverage'] as double,
            )).toList();
      });
    } catch (e) {
      debugPrint('Error fetching children data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
              size: 50,
            ),
            const SizedBox(height: 8),
            const Text(
              "Logout?",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: const Text(
          "Are you sure you want to logout?",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
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
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 My Children'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchChildrenData,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _children.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.child_care, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 20),
                      Text(
                        'No children found',
                        style: TextStyle(color: Colors.grey[600], fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Contact your child\'s teacher to link your account',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )

              : RefreshIndicator(
                  onRefresh: _fetchChildrenData,

                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _children.length,
                    itemBuilder: (context, index) {
                      final child = _children[index];
                      debugPrint('📡 Loading children for parentId: ${widget.parentId}');

                      return _buildChildCard(context, child);
                    },
                  ),
                ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildSummary child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(
                      child.studentName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.studentName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.school, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              child.readingLevel,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const Divider(height: 24, thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatChip(
                    icon: Icons.quiz,
                    label: 'Quizzes',
                    value: '${child.quizCount}',
                    color: Colors.orange,
                  ),
                  _buildStatChip(
                    icon: Icons.star,
                    label: 'Avg Score',
                    value: '${child.averageScore.toStringAsFixed(0)}%',
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearPercentIndicator(
                lineHeight: 8.0,
                percent: child.totalTasks > 0
                    ? (child.completedTasks / child.totalTasks).clamp(0.0, 1.0)
                    : 0.0,
                backgroundColor: Colors.grey[200]!,
                progressColor: Colors.indigo,
                barRadius: const Radius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class ChildSummary {
  final String studentId;
  final String studentName;
  final String readingLevel;
  final int totalTasks;
  final int completedTasks;
  final double averageScore;
  final int quizCount;
  final double quizAverage;

  ChildSummary({
    required this.studentId,
    required this.studentName,
    required this.readingLevel,
    required this.totalTasks,
    required this.completedTasks,
    required this.averageScore,
    required this.quizCount,
    required this.quizAverage,
  });
}
