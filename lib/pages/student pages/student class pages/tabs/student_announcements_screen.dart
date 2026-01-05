// screens/student_announcements_screen.dart
import 'package:deped_reading_app_laravel/api/classroom_service.dart';
import 'package:deped_reading_app_laravel/constants.dart';
import 'package:deped_reading_app_laravel/models/announcement_model.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20dashboard/cards/announcement_card.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';

class StudentAnnouncementsScreen extends StatefulWidget {
  final String classId;
  final String className;

  const StudentAnnouncementsScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<StudentAnnouncementsScreen> createState() =>
      _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState
    extends State<StudentAnnouncementsScreen> {
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  bool _hasError = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final announcements = await ClassroomService.getClassAnnouncements(
        widget.classId,
      );

      setState(() {
        _announcements = announcements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body: Column(
        children: [
          _AnnouncementsHeader(
            className: widget.className,
            announcementCount: _announcements.length,
          ),
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _loadAnnouncements,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Colors.white,
              child: _AnnouncementsListContent(
                isLoading: _isLoading,
                hasError: _hasError,
                announcements: _announcements,
                onRetry: _loadAnnouncements,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementsHeader extends StatelessWidget {
  final String className;
  final int announcementCount;

  const _AnnouncementsHeader({
    required this.className,
    required this.announcementCount,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WaveClipperOne(reverse: false),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryColor, Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Announcements",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'ComicNeue',
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$announcementCount announcement${announcementCount != 1 ? 's' : ''}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementsListContent extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final List<Announcement> announcements;
  final VoidCallback onRetry;

  const _AnnouncementsListContent({
    required this.isLoading,
    required this.hasError,
    required this.announcements,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _AnnouncementsLoadingView();
    if (hasError) return _AnnouncementsErrorView(onRetry: onRetry);
    if (announcements.isEmpty) return const _AnnouncementsEmptyView();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 20, left: 16, right: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween(begin: 0.8, end: 1),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AnnouncementCard(
                  announcement: announcements[index],
                  showClassInfo: false,
                  isTeacher: false,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AnnouncementsLoadingView extends StatelessWidget {
  const _AnnouncementsLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animation/loading_rainbow.json',
            width: 90,
            height: 90,
          ),
          const SizedBox(height: 20),
          Text(
            "Loading Announcements...",
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
              fontFamily: 'ComicNeue',
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementsErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _AnnouncementsErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/error.json',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 20),
          Text(
            "Failed to load announcements",
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontFamily: 'ComicNeue',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Retry",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementsEmptyView extends StatelessWidget {
  const _AnnouncementsEmptyView();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animation/empty.json',
            width: 250,
            height: 250,
          ),
          const SizedBox(height: 20),
          Text(
            "No announcements yet!",
            style: TextStyle(
              fontSize: 22,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontFamily: 'ComicNeue',
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Your teacher will post important updates and announcements here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontFamily: 'ComicNeue',
              ),
            ),
          ),
        ],
      ),
    );
  }
}