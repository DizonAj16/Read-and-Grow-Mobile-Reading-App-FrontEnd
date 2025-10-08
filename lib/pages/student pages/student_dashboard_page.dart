import 'package:deped_reading_app_laravel/api/supabase_auth_service.dart';
import 'package:deped_reading_app_laravel/models/student_model.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'student page widgets/horizontal_card.dart';
import 'student page widgets/activity_tile.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  String? username;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  bool _isLoading = false;
  bool _minimumLoadingTimeElapsed = false;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startMinimumLoadingTimer();
  }

  void _startMinimumLoadingTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _minimumLoadingTimeElapsed = true;
          _updateLoadingState();
        });
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseAuthService.getAuthProfile();
      final profileJson = (response?['profile'] ?? {}) as Map<String, dynamic>;
      final student = Student.fromJson(profileJson);
      await student.saveToPrefs();

      if (student.username != null && student.username!.isNotEmpty) {
        setState(() => username = student.username);
      }
    } catch (e) {
      debugPrint('API fetch failed: $e');
      final fallbackStudent = await Student.fromPrefs();
      setState(() => username = fallbackStudent.username ?? '');
    } finally {
      setState(() {
        _dataLoaded = true;
        _updateLoadingState();
      });
    }
  }

  void _updateLoadingState() {
    if (_dataLoaded && _minimumLoadingTimeElapsed) {
      _isLoading = false;
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
      _minimumLoadingTimeElapsed = false;
      _dataLoaded = false;
    });

    _startMinimumLoadingTimer();
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final showLoading = _isLoading || !_minimumLoadingTimeElapsed;

    return Scaffold(
      backgroundColor: const Color(0xFFFCEEEE),
      body: SafeArea(
        child:
            showLoading
                ? Center(
                  child: Lottie.asset(
                    'assets/animation/loading_rainbow.json',
                    width: 90,
                    height: 90,
                  ),
                )
                : RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _handleRefresh,
                  color: Colors.purple,
                  backgroundColor: Colors.white,
                  strokeWidth: 3.0,
                  displacement: 40.0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20.0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(child: _buildWelcomeSection(context)),
                                const SizedBox(height: 20),
                                _buildStatisticsCards(),
                                const SizedBox(height: 30),
                                _buildRecentActivitiesSection(context),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Lottie.asset(
              'assets/animation/waving_hello.json',
              height: 150,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Hi ${username ?? ''}! 👋",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Ready to learn and have fun today?",
            style: TextStyle(fontSize: 16, color: Colors.purple.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return SizedBox(
      height: 170,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          StudentDashboardHorizontalCard(
            title: "Completed",
            value: "0",
            gradientColors: [Colors.lightGreen, Colors.green],
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(width: 16),
          StudentDashboardHorizontalCard(
            title: "Pending",
            value: "11",
            gradientColors: [Colors.orangeAccent, Colors.deepOrange],
            icon: Icons.pending_actions,
          ),
          const SizedBox(width: 16),
          StudentDashboardHorizontalCard(
            title: "Badges",
            value: "0",
            gradientColors: [Colors.pinkAccent, Colors.redAccent],
            icon: Icons.emoji_events_outlined,
          ),
          const SizedBox(width: 16),
          StudentDashboardHorizontalCard(
            title: "Badge",
            value: "N/A",
            gradientColors: [Colors.blueAccent, Colors.lightBlue],
            icon: Icons.star_border,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesSection(BuildContext context) {
    final List activities = [];

    if (activities.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.hourglass_empty_rounded,
                  size: 48,
                  color: Colors.amber.shade600,
                ),
                const SizedBox(height: 12),
                Text(
                  "No recent activities yet!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your activities will appear here once you start learning.",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "📚 Recent Activities",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children:
              activities.map((activity) {
                return StudentDashboardActivityTile(
                  title: activity.title,
                  subtitle: activity.subtitle,
                  icon: activity.icon,
                );
              }).toList(),
        ),
      ],
    );
  }
}
