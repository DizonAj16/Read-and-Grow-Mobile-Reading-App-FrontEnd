import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class StudentReadingProgressPage extends StatefulWidget {
  final String classId;

  const StudentReadingProgressPage({super.key, required this.classId});

  @override
  State<StudentReadingProgressPage> createState() =>
      _StudentReadingProgressPageState();
}

class _StudentReadingProgressPageState
    extends State<StudentReadingProgressPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;

  List<Map<String, dynamic>> students = [];
  Map<String, Map<String, dynamic>> readingLevels = {};

  // Filter states
  String? selectedReadingLevel;
  bool showFilters = false;
  String? selectedGrade;
  String? selectedSection;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  // Graph states
  bool _showGraph = true;
  int? _hoveredStudentIndex;
  double _zoomLevel = 1.0;
  final double _minZoom = 0.5;
  final double _maxZoom = 2.0;
  bool _isFullScreen = false;
  bool _isLandscape = false;

  // Responsive layout values
  late bool _isMobile;
  late bool _isTablet;
  late bool _isDesktop;

  @override
  void initState() {
    super.initState();
    _loadReadingLevels();
    _loadStudents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadStudents();
    });
  }

  Timer? _filterDebounceTimer;

  Future<void> _loadReadingLevels() async {
    try {
      final levelsRes = await supabase
          .from('reading_levels')
          .select('*')
          .order('level_number', ascending: true);

      for (var level in levelsRes) {
        final lid = level['id']?.toString();
        if (lid != null) {
          readingLevels[lid] = Map<String, dynamic>.from(level);
        }
      }
    } catch (e) {
      debugPrint('Error loading reading levels: $e');
    }
  }

  Future<void> _loadStudents() async {
    setState(() => isLoading = true);

    try {
      // First get enrolled student IDs for this class
      final enrollmentsRes = await supabase
          .from('student_enrollments')
          .select('student_id')
          .eq('class_room_id', widget.classId);

      final enrolledStudentIds =
          enrollmentsRes
              .map((e) => e['student_id']?.toString())
              .whereType<String>()
              .toList();

      if (enrolledStudentIds.isEmpty) {
        if (mounted) {
          setState(() {
            isLoading = false;
            students = [];
          });
        }
        return;
      }

      // Now get student details with reading levels
      var query = supabase
          .from('students')
          .select('*, reading_levels!left(*)')
          .inFilter('id', enrolledStudentIds);

      // Apply filters
      if (selectedReadingLevel != null) {
        query = query.eq('current_reading_level_id', selectedReadingLevel!);
      }

      if (selectedGrade != null) {
        query = query.eq('student_grade', selectedGrade!);
      }

      if (selectedSection != null) {
        query = query.eq('student_section', selectedSection!);
      }

      final searchTerm = _searchController.text.trim();
      if (searchTerm.isNotEmpty) {
        query = query.or(
          'student_name.ilike.%$searchTerm%,student_lrn.ilike.%$searchTerm%',
        );
      }

      final studentsRes = await query.order('student_name', ascending: true);

      final newStudents = List<Map<String, dynamic>>.from(studentsRes);

      if (mounted) {
        setState(() {
          students = newStudents;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => isLoading = false);
      }
    }
  }

  void _clearFilters() {
    setState(() {
      selectedReadingLevel = null;
      selectedGrade = null;
      selectedSection = null;
      _searchController.clear();
    });
    _loadStudents();
  }

  // Get initials from student name
  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.length == 1) {
      return parts[0].length >= 2 
          ? parts[0].substring(0, 2).toUpperCase()
          : parts[0].toUpperCase();
    }
    return '??';
  }

  // Get color for avatar based on student ID (consistent color per student)
  Color _getAvatarColor(String? studentId, int levelNumber) {
    if (studentId == null) {
      // Fallback to level-based color
      return _getLevelColor(levelNumber);
    }
    
    // Generate consistent color from student ID hash
    final hash = studentId.hashCode;
    final hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.85).toColor();
  }

  Color _getLevelColor(int levelNumber) {
    final colors = [
      const Color(0xFFEF5350), // Level 1 - Red
      const Color(0xFFFF9800), // Level 2 - Orange
      const Color(0xFFFFEB3B), // Level 3 - Yellow
      const Color(0xFF4CAF50), // Level 4 - Green
      const Color(0xFF2196F3), // Level 5 - Blue
      const Color(0xFF3F51B5), // Level 6 - Indigo
      const Color(0xFF9C27B0), // Level 7 - Purple
      const Color(0xFFE91E63), // Level 8 - Pink
    ];
    return colors[(levelNumber - 1) % colors.length];
  }

  // Prepare data for graph
  List<Map<String, dynamic>> _getGraphData() {
    // Sort students by level and then name for better visualization
    final sortedStudents = List<Map<String, dynamic>>.from(students)
      ..sort((a, b) {
        final levelA = readingLevels[a['current_reading_level_id']?.toString()];
        final levelB = readingLevels[b['current_reading_level_id']?.toString()];
        final levelNumA = levelA?['level_number'] ?? 0;
        final levelNumB = levelB?['level_number'] ?? 0;
        if (levelNumA != levelNumB) {
          return levelNumA.compareTo(levelNumB);
        }
        return (a['student_name'] ?? '').compareTo(b['student_name'] ?? '');
      });

    return sortedStudents.asMap().entries.map((entry) {
      final index = entry.key;
      final student = entry.value;
      final studentName = student['student_name'] ?? 'Unknown';
      final levelId = student['current_reading_level_id']?.toString();
      final readingLevel = levelId != null ? readingLevels[levelId] : null;
      final levelNumber = readingLevel?['level_number'] ?? 0;
      final studentId = student['id']?.toString();
      final profilePicture = student['profile_picture'];

      return {
        'index': index,
        'studentName': studentName,
        'levelNumber': levelNumber,
        'levelTitle': readingLevel?['title'] ?? 'No Level',
        'studentId': studentId,
        'initials': _getInitials(studentName),
        'avatarColor': _getAvatarColor(studentId, levelNumber),
        'profilePicture': profilePicture,
        'levelColor': _getLevelColor(levelNumber),
      };
    }).toList();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen && MediaQuery.of(context).orientation == Orientation.landscape) {
        _isLandscape = true;
      } else {
        _isLandscape = false;
      }
    });
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
    });
  }

  Widget _buildCustomLineGraph() {
    final graphData = _getGraphData();
    if (graphData.isEmpty) {
      return Container(
        height: _isFullScreen ? double.infinity : 400,
        margin: _isFullScreen ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: _isFullScreen ? const EdgeInsets.all(32) : const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: _isFullScreen ? BorderRadius.zero : BorderRadius.circular(20),
          boxShadow: _isFullScreen ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: _isFullScreen ? 120 : 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No data available for graph',
                style: TextStyle(
                  fontSize: _isFullScreen ? 24 : 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxLevel = readingLevels.values.fold<int>(
      0,
      (max, level) => level['level_number'] > max ? level['level_number'] : max,
    );
    final minLevel = 0;
    final totalStudents = graphData.length;
    final levelRange = maxLevel - minLevel;

    return Container(
      margin: _isFullScreen ? EdgeInsets.zero : EdgeInsets.symmetric(
        horizontal: _isMobile ? 8 : 16,
        vertical: 12,
      ),
      padding: _isFullScreen ? const EdgeInsets.all(24) : EdgeInsets.all(_isMobile ? 12 : 20),
      constraints: BoxConstraints(
        minHeight: _isFullScreen ? double.infinity : (_isMobile ? 300 : 400),
        maxHeight: _isFullScreen ? double.infinity : MediaQuery.of(context).size.height * (_isMobile ? 0.6 : 0.7),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _isFullScreen ? BorderRadius.zero : BorderRadius.circular(20),
        boxShadow: _isFullScreen ? [] : [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Responsive layout
          if (!_isFullScreen) ...[
            _isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Reading Progress',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          Tooltip(
                            message: _showGraph ? 'Hide Graph' : 'Show Graph',
                            child: IconButton(
                              icon: Icon(
                                _showGraph ? Icons.visibility_off : Icons.visibility,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showGraph = !_showGraph;
                                });
                              },
                            ),
                          ),
                          Tooltip(
                            message: 'Full Screen',
                            child: IconButton(
                              icon: Icon(
                                Icons.fullscreen,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              onPressed: _toggleFullScreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${students.length} Students • ${maxLevel} Levels',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Mobile zoom controls
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Tooltip(
                              message: 'Zoom Out',
                              child: IconButton(
                                icon: Icon(Icons.zoom_out,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 18),
                                onPressed: _zoomLevel > _minZoom
                                    ? () {
                                        setState(() {
                                          _zoomLevel = (_zoomLevel - 0.2).clamp(_minZoom, _maxZoom);
                                        });
                                      }
                                    : null,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(_zoomLevel * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Tooltip(
                              message: 'Zoom In',
                              child: IconButton(
                                icon: Icon(Icons.zoom_in,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 18),
                                onPressed: _zoomLevel < _maxZoom
                                    ? () {
                                        setState(() {
                                          _zoomLevel = (_zoomLevel + 0.2).clamp(_minZoom, _maxZoom);
                                        });
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reading Progress Dashboard',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${students.length} Students • ${maxLevel} Reading Levels',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Zoom controls
                          Tooltip(
                            message: 'Zoom Out',
                            child: IconButton(
                              icon: Icon(Icons.zoom_out,
                                  color: Theme.of(context).colorScheme.primary),
                              onPressed: _zoomLevel > _minZoom
                                  ? () {
                                      setState(() {
                                        _zoomLevel = (_zoomLevel - 0.2).clamp(_minZoom, _maxZoom);
                                      });
                                    }
                                  : null,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(_zoomLevel * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Tooltip(
                            message: 'Zoom In',
                            child: IconButton(
                              icon: Icon(Icons.zoom_in,
                                  color: Theme.of(context).colorScheme.primary),
                              onPressed: _zoomLevel < _maxZoom
                                  ? () {
                                      setState(() {
                                        _zoomLevel = (_zoomLevel + 0.2).clamp(_minZoom, _maxZoom);
                                      });
                                    }
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: _showGraph ? 'Hide Graph' : 'Show Graph',
                            child: IconButton(
                              icon: Icon(
                                _showGraph ? Icons.visibility_off : Icons.visibility,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showGraph = !_showGraph;
                                });
                              },
                            ),
                          ),
                          Tooltip(
                            message: 'Full Screen',
                            child: IconButton(
                              icon: Icon(
                                Icons.fullscreen,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: _toggleFullScreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
            const SizedBox(height: 16),
          ] else ...[
            // Full screen header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
                        onPressed: _toggleFullScreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Full Screen Progress Graph',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Tooltip(
                        message: _isLandscape ? 'Portrait View' : 'Landscape View',
                        child: IconButton(
                          icon: Icon(
                            _isLandscape ? Icons.screen_rotation : Icons.screen_rotation_alt,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: _toggleOrientation,
                        ),
                      ),
                      Tooltip(
                        message: 'Zoom Out',
                        child: IconButton(
                          icon: Icon(Icons.zoom_out,
                              color: Theme.of(context).colorScheme.primary),
                          onPressed: _zoomLevel > _minZoom
                              ? () {
                                  setState(() {
                                    _zoomLevel = (_zoomLevel - 0.2).clamp(_minZoom, _maxZoom);
                                  });
                                }
                              : null,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(_zoomLevel * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Zoom In',
                        child: IconButton(
                          icon: Icon(Icons.zoom_in,
                              color: Theme.of(context).colorScheme.primary),
                          onPressed: _zoomLevel < _maxZoom
                              ? () {
                                  setState(() {
                                    _zoomLevel = (_zoomLevel + 0.2).clamp(_minZoom, _maxZoom);
                                  });
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Exit Full Screen',
                        child: IconButton(
                          icon: Icon(
                            Icons.fullscreen_exit,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: _toggleFullScreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Graph area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Adjust spacing for full screen and orientation
                final baseStudentSpacing = _isFullScreen
                    ? (_isLandscape ? 80.0 : 100.0) * _zoomLevel
                    : (_isMobile ? 60.0 : 70.0) * _zoomLevel;
                
                final baseLevelSpacing = _isFullScreen
                    ? (_isLandscape ? 80.0 : 60.0) * _zoomLevel
                    : (_isMobile ? 40.0 : 60.0) * _zoomLevel;

                final studentSpacing = baseStudentSpacing.clamp(
                  _isFullScreen ? 60.0 : (_isMobile ? 40.0 : 50.0),
                  _isFullScreen ? 200.0 : (_isMobile ? 120.0 : 150.0),
                );
                final levelSpacing = baseLevelSpacing.clamp(
                  _isFullScreen ? 50.0 : (_isMobile ? 30.0 : 40.0),
                  _isFullScreen ? 150.0 : (_isMobile ? 80.0 : 100.0),
                );

                final totalGraphWidthNeeded = levelRange * levelSpacing;
                final totalGraphHeightNeeded = studentSpacing * totalStudents;

                final avatarColumnWidth = _isFullScreen 
                    ? (_isLandscape ? 120.0 : 150.0)
                    : (_isMobile ? 80.0 : 100.0);
                
                final levelLabelsHeight = _isFullScreen 
                    ? (_isLandscape ? 60.0 : 70.0)
                    : (_isMobile ? 40.0 : 50.0);

                final availableWidth = constraints.maxWidth - avatarColumnWidth;
                final availableHeight = constraints.maxHeight - (_isFullScreen ? levelLabelsHeight + 32 : levelLabelsHeight + 20);

                final needsHorizontalScroll = totalGraphWidthNeeded > availableWidth;
                final needsVerticalScroll = totalGraphHeightNeeded > availableHeight;

                // Build student avatars column
                Widget buildStudentAvatarsColumn(double height) {
                  return SizedBox(
                    width: avatarColumnWidth,
                    child: SizedBox(
                      height: height,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: totalStudents,
                        itemBuilder: (context, index) {
                          final student = graphData[index];
                          final isHovered = _hoveredStudentIndex == index;
                          final studentName = student['studentName'];
                          final initials = student['initials'];
                          final profilePicture = student['profilePicture'];
                          final avatarColor = student['avatarColor'];

                          final avatarSize = _isFullScreen
                              ? (_isLandscape 
                                  ? (isHovered ? 60.0 : 52.0)
                                  : (isHovered ? 70.0 : 60.0))
                              : (_isMobile
                                  ? (isHovered ? 40.0 : 34.0)
                                  : (isHovered ? 50.0 : 42.0));

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _hoveredStudentIndex = _hoveredStudentIndex == index ? null : index;
                              });
                            },
                            child: Container(
                              height: studentSpacing,
                              padding: EdgeInsets.symmetric(
                                horizontal: _isFullScreen ? 12 : (_isMobile ? 4 : 8),
                                vertical: _isFullScreen ? 6 : (_isMobile ? 2 : 4),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Avatar Circle
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: avatarSize,
                                    height: avatarSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: isHovered 
                                              ? avatarColor.withOpacity(0.4)
                                              : Colors.grey.withOpacity(0.2),
                                          blurRadius: isHovered ? (_isFullScreen ? 12 : 8) : (_isFullScreen ? 6 : 3),
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: isHovered 
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.white,
                                        width: isHovered ? (_isFullScreen ? 3.5 : 2.5) : (_isFullScreen ? 2.5 : 2),
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: profilePicture != null
                                          ? CachedNetworkImage(
                                              imageUrl: profilePicture,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: avatarColor,
                                                child: Center(
                                                  child: Text(
                                                    initials,
                                                    style: TextStyle(
                                                      fontSize: _isFullScreen 
                                                          ? (_isLandscape ? 16 : 18)
                                                          : (_isMobile ? 12 : 14),
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: avatarColor,
                                                child: Center(
                                                  child: Text(
                                                    initials,
                                                    style: TextStyle(
                                                      fontSize: _isFullScreen 
                                                          ? (_isLandscape ? 16 : 18)
                                                          : (_isMobile ? 12 : 14),
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: avatarColor,
                                              child: Center(
                                                child: Text(
                                                  initials,
                                                  style: TextStyle(
                                                    fontSize: _isFullScreen
                                                        ? (_isLandscape
                                                            ? (isHovered ? 20 : 18)
                                                            : (isHovered ? 22 : 20))
                                                        : (_isMobile
                                                            ? (isHovered ? 14 : 12)
                                                            : (isHovered ? 16 : 14)),
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                   SizedBox(height: _isFullScreen ? 8 : 4),
                                  // Student Name (truncated)
                                  Tooltip(
                                    message: studentName,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: Text(
                                        studentName.split(' ').first,
                                        style: TextStyle(
                                          fontSize: _isFullScreen 
                                              ? (_isLandscape ? 12 : 14)
                                              : (_isMobile ? 9 : 10),
                                          fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
                                          color: isHovered
                                              ? Theme.of(context).colorScheme.primary
                                              : Colors.grey[700],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }

                // Build graph area
                Widget buildGraphArea(double width, double height) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.grey[50]!.withOpacity(0.1),
                          Colors.grey[100]!.withOpacity(0.1),
                        ],
                      ),
                      border: Border(
                        left: BorderSide(color: Colors.grey[300]!, width: 1),
                        top: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    child: CustomPaint(
                      size: Size(width, height),
                      painter: _EnhancedLineGraphPainter(
                        data: graphData,
                        maxLevel: maxLevel,
                        minLevel: minLevel,
                        hoveredIndex: _hoveredStudentIndex,
                        studentSpacing: studentSpacing,
                        levelSpacing: levelSpacing,
                        primaryColor: Theme.of(context).colorScheme.primary,
                        isMobile: _isMobile,
                        isFullScreen: _isFullScreen,
                        isLandscape: _isLandscape,
                      ),
                    ),
                  );
                }

                // Build level labels with styling
                Widget buildLevelLabels(double width) {
                  return Container(
                    height: levelLabelsHeight,
                    width: width,
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(maxLevel + 1, (index) {
                        final level = index;
                        final levelColor = _getLevelColor(level);
                        final levelData = readingLevels.values
                            .firstWhere((lvl) => lvl['level_number'] == level, orElse: () => {});
                        final levelTitle = levelData['title']?.toString() ?? 'Level $level';
                        
                        final circleSize = _isFullScreen
                            ? (_isLandscape ? 36.0 : 40.0)
                            : (_isMobile ? 24.0 : 28.0);
                        
                        final titleMaxLength = _isFullScreen
                            ? (_isLandscape ? 10 : 12)
                            : (_isMobile ? 6 : 8);

                        return SizedBox(
                          width: levelSpacing,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: circleSize,
                                height: circleSize,
                                decoration: BoxDecoration(
                                  color: levelColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: levelColor.withOpacity(0.3),
                                      blurRadius: _isFullScreen ? 6 : 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.white, width: _isFullScreen ? 3 : 2),
                                ),
                                child: Center(
                                  child: Text(
                                    'L$level',
                                    style: TextStyle(
                                      fontSize: _isFullScreen
                                          ? (_isLandscape ? 14 : 16)
                                          : (_isMobile ? 10 : 11),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Tooltip(
                                message: levelTitle,
                                child: Text(
                                  levelTitle.length > titleMaxLength 
                                      ? '${levelTitle.substring(0, titleMaxLength)}...' 
                                      : levelTitle,
                                  style: TextStyle(
                                    fontSize: _isFullScreen
                                        ? (_isLandscape ? 10 : 12)
                                        : (_isMobile ? 8 : 9),
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  );
                }

                // Always use scrollable layout to prevent overflow
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildStudentAvatarsColumn(
                            needsVerticalScroll ? availableHeight : totalGraphHeightNeeded,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: SizedBox(
                                        width: totalGraphWidthNeeded,
                                        height: totalGraphHeightNeeded,
                                        child: buildGraphArea(
                                          totalGraphWidthNeeded,
                                          totalGraphHeightNeeded,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: levelLabelsHeight,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: totalGraphWidthNeeded,
                                      child: buildLevelLabels(totalGraphWidthNeeded),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Legend - Responsive
          if (!_isFullScreen) ...[
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(_isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Legend',
                    style: TextStyle(
                      fontSize: _isMobile ? 11 : 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Reading Progress Line',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.touch_app, size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap avatars to highlight',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Reading Progress Line',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.touch_app, size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap avatars to highlight',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getLevelColor(1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Level Colors',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine screen size for responsive design
    _isMobile = screenWidth < 600;
    _isTablet = screenWidth >= 600 && screenWidth < 1024;
    _isDesktop = screenWidth >= 1024;

    // If in full screen mode, show only the graph
    if (_isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _showGraph
              ? _buildCustomLineGraph()
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bar_chart_outlined,
                          size: 80,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Graph is Hidden',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Tap the eye icon to show the reading progress graph',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showGraph = true;
                          });
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('Show Progress Graph'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    // Normal view
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Reading Progress',
          style: TextStyle(
            fontSize: _isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        actions: [
          if (students.isNotEmpty && !_isMobile)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, size: 16, color: primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '${students.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          Tooltip(
            message: 'Full Screen View',
            child: IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: _toggleFullScreen,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading student progress...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : students.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: _isMobile ? 80 : 100,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No Students Found',
                            style: TextStyle(
                              fontSize: _isMobile ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _isMobile ? 20 : 40,
                            ),
                            child: Text(
                              'Try adjusting your filters or check if students are assigned to this class.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: _isMobile ? 14 : 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _showGraph
                    ? _buildCustomLineGraph()
                    : Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: _isMobile ? 100 : 120,
                                height: _isMobile ? 100 : 120,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.bar_chart_outlined,
                                  size: _isMobile ? 50 : 60,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Progress Graph is Hidden',
                                style: TextStyle(
                                  fontSize: _isMobile ? 18 : 20,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: _isMobile ? 20 : 40,
                                ),
                                child: Text(
                                  'Tap the eye icon to show the reading progress graph',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: _isMobile ? 14 : 16,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showGraph = true;
                                  });
                                },
                                icon: const Icon(Icons.visibility),
                                label: Text(
                                  'Show Progress Graph',
                                  style: TextStyle(
                                    fontSize: _isMobile ? 14 : 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: _isMobile ? 20 : 24,
                                    vertical: _isMobile ? 12 : 12,
                                  ),
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }
}

// Enhanced custom painter for line graph with mobile support
class _EnhancedLineGraphPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final int maxLevel;
  final int minLevel;
  final int? hoveredIndex;
  final double studentSpacing;
  final double levelSpacing;
  final Color primaryColor;
  final bool isMobile;
  final bool isFullScreen;
  final bool isLandscape;

  _EnhancedLineGraphPainter({
    required this.data,
    required this.maxLevel,
    required this.minLevel,
    required this.hoveredIndex,
    required this.studentSpacing,
    required this.levelSpacing,
    required this.primaryColor,
    this.isMobile = false,
    this.isFullScreen = false,
    this.isLandscape = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final linePaint = Paint()
      ..color = primaryColor.withOpacity(isFullScreen ? 0.6 : (isMobile ? 0.4 : 0.5))
      ..strokeWidth = isFullScreen ? (isLandscape ? 4.0 : 3.5) : (isMobile ? 2.0 : 3.0)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(isFullScreen ? 0.2 : (isMobile ? 0.1 : 0.15))
      ..strokeWidth = isFullScreen ? (isLandscape ? 15.0 : 12.0) : (isMobile ? 6.0 : 10.0)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final hoverPaint = Paint()
      ..color = primaryColor.withOpacity(isFullScreen ? 0.15 : (isMobile ? 0.08 : 0.1))
      ..style = PaintingStyle.fill;

    // Draw subtle grid
    final majorGridPaint = Paint()
      ..color = Colors.grey[300]!.withOpacity(isFullScreen ? 0.4 : (isMobile ? 0.2 : 0.3))
      ..strokeWidth = isFullScreen ? 1.2 : (isMobile ? 0.8 : 1.0);

    final minorGridPaint = Paint()
      ..color = Colors.grey[200]!.withOpacity(isFullScreen ? 0.2 : (isMobile ? 0.1 : 0.15))
      ..strokeWidth = isFullScreen ? 0.8 : (isMobile ? 0.4 : 0.5);

    // Draw vertical grid lines
    for (int i = minLevel; i <= maxLevel; i++) {
      final x = i * levelSpacing;
      if (i % 5 == 0) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), majorGridPaint);
      } else {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorGridPaint);
      }
    }

    // Draw horizontal grid lines
    for (int i = 0; i < data.length; i++) {
      final y = i * studentSpacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorGridPaint);
    }

    // Draw glow effect behind lines
    for (int i = 0; i < data.length; i++) {
      final level = data[i]['levelNumber'] as int;
      final x = level * levelSpacing;
      final y = i * studentSpacing;

      if (level > minLevel) {
        // Draw glow
        canvas.drawLine(
          Offset((level - 1) * levelSpacing, y),
          Offset(x, y),
          glowPaint,
        );
      }
    }

    // Draw connecting lines
    for (int i = 0; i < data.length; i++) {
      final level = data[i]['levelNumber'] as int;
      final x = level * levelSpacing;
      final y = i * studentSpacing;

      if (level > minLevel) {
        canvas.drawLine(
          Offset((level - 1) * levelSpacing, y),
          Offset(x, y),
          linePaint,
        );
      }
    }

    // Draw points
    for (int i = 0; i < data.length; i++) {
      final level = data[i]['levelNumber'] as int;
      final x = level * levelSpacing;
      final y = i * studentSpacing;
      final levelColor = data[i]['levelColor'];
      final isHovered = hoveredIndex == i;

      // Draw hover highlight
      if (isHovered) {
        canvas.drawCircle(
          Offset(x, y),
          isFullScreen ? (isLandscape ? 32 : 30) : (isMobile ? 18 : 24),
          hoverPaint,
        );
      }

      // Draw outer glow
      final outerGlowPaint = Paint()
        ..color = levelColor.withOpacity(isFullScreen ? 0.5 : (isMobile ? 0.3 : 0.4))
        ..maskFilter =  MaskFilter.blur(BlurStyle.normal, isFullScreen ? 6 : 4);
      canvas.drawCircle(
        Offset(x, y),
        isHovered 
            ? (isFullScreen ? (isLandscape ? 16 : 14) : (isMobile ? 8 : 12))
            : (isFullScreen ? (isLandscape ? 14 : 12) : (isMobile ? 6 : 10)),
        outerGlowPaint,
      );

      // Draw main point with gradient effect
      final gradientPoint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(x, y),
          isHovered 
              ? (isFullScreen ? (isLandscape ? 10 : 9) : (isMobile ? 5 : 8))
              : (isFullScreen ? (isLandscape ? 9 : 8) : (isMobile ? 4 : 6)),
          [levelColor, levelColor.withOpacity(0.8)],
        );
      canvas.drawCircle(
        Offset(x, y),
        isHovered 
            ? (isFullScreen ? (isLandscape ? 10 : 9) : (isMobile ? 5 : 8))
            : (isFullScreen ? (isLandscape ? 9 : 8) : (isMobile ? 4 : 6)),
        gradientPoint,
      );

      // Draw inner highlight
      canvas.drawCircle(
        Offset(x - (isHovered ? (isFullScreen ? 2.0 : 1.2) : (isFullScreen ? 1.5 : 0.8)), 
               y - (isHovered ? (isFullScreen ? 2.0 : 1.2) : (isFullScreen ? 1.5 : 0.8))),
        isHovered ? (isFullScreen ? 2.5 : 1.5) : (isFullScreen ? 1.5 : 1),
        Paint()..color = Colors.white.withOpacity(0.8),
      );

      // Draw level number inside circle on hover
      if (isHovered) {
        final textSpan = TextSpan(
          text: '$level',
          style: TextStyle(
            fontSize: isFullScreen ? (isLandscape ? 12 : 14) : (isMobile ? 8 : 10),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      }
    }

    // Draw milestone indicators for every 5 levels
    if (isFullScreen || !isMobile) {
      for (int level = minLevel; level <= maxLevel; level++) {
        final x = level * levelSpacing;
        
        if (level % 5 == 0 && level > 0) {
          // Draw milestone background
          final milestoneBackground = Paint()
            ..color = primaryColor.withOpacity(isFullScreen ? 0.08 : 0.05)
            ..style = PaintingStyle.fill;
          
          canvas.drawCircle(
            Offset(x, size.height / 2),
            isFullScreen ? 40 : 30,
            milestoneBackground,
          );
          
          // Draw milestone text
          final milestoneText = TextPainter(
            text: TextSpan(
              text: '✓',
              style: TextStyle(
                fontSize: isFullScreen ? 20 : 16,
                color: primaryColor.withOpacity(isFullScreen ? 0.8 : 0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: ui.TextDirection.ltr,
          );
          milestoneText.layout();
          milestoneText.paint(
            canvas,
            Offset(x - milestoneText.width / 2, size.height / 2 - milestoneText.height / 2),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EnhancedLineGraphPainter oldDelegate) {
    return data != oldDelegate.data ||
        hoveredIndex != oldDelegate.hoveredIndex ||
        studentSpacing != oldDelegate.studentSpacing ||
        levelSpacing != oldDelegate.levelSpacing ||
        primaryColor != oldDelegate.primaryColor ||
        isMobile != oldDelegate.isMobile ||
        isFullScreen != oldDelegate.isFullScreen ||
        isLandscape != oldDelegate.isLandscape;
  }
}