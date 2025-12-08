import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentProfilePage extends StatefulWidget {
  final String name;
  final String avatarLetter;
  final Color avatarColor;
  final String? profileUrl;
  final String studentId;

  const StudentProfilePage({
    super.key,
    required this.name,
    required this.avatarLetter,
    required this.avatarColor,
    required this.profileUrl,
    required this.studentId,
  });

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _studentData;
  Map<String, dynamic>? _readingLevelData;

  @override
  void initState() {
    super.initState();
    _loadStudentReadingLevel();
  }

  Future<void> _loadStudentReadingLevel() async {
    try {
      setState(() => _isLoading = true);

      // Fetch student data including reading level
      final studentResponse = await supabase
          .from('students')
          .select('''
            id,
            student_name,
            current_reading_level_id,
            reading_level_updated_at
          ''')
          .eq('id', widget.studentId)
          .maybeSingle();

      if (studentResponse != null) {
        _studentData = Map<String, dynamic>.from(studentResponse);
        
        // Fetch reading level details if available
        final readingLevelId = _studentData!['current_reading_level_id']?.toString();
        if (readingLevelId != null && readingLevelId.isNotEmpty) {
          final readingLevelResponse = await supabase
              .from('reading_levels')
              .select('level_number, title, description')
              .eq('id', readingLevelId)
              .maybeSingle();
          
          if (readingLevelResponse != null) {
            _readingLevelData = Map<String, dynamic>.from(readingLevelResponse);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading student reading level: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final surfaceVariant = theme.colorScheme.surfaceVariant;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final primaryContainer = theme.colorScheme.primaryContainer;
    final onPrimaryContainer = theme.colorScheme.onPrimaryContainer;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Student Profile",
          style: TextStyle(
            fontFamily: 'ComicNeue',
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _isLoading
          ? _buildLoadingView(primaryColor)
          : SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    // Animated avatar container
                    Hero(
                      tag: 'avatar_${widget.name}',
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor,
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: (widget.profileUrl != null && widget.profileUrl!.isNotEmpty)
                              ? FadeInImage.assetNetwork(
                                  placeholder: 'assets/placeholder/avatar_placeholder.png',
                                  image: widget.profileUrl!,
                                  fit: BoxFit.cover,
                                  imageErrorBuilder: (_, __, ___) => _buildAvatarFallback(primaryColor, onPrimary),
                                )
                              : _buildAvatarFallback(primaryColor, onPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Name badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.1),
                            primaryColor.withOpacity(0.05)
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ComicNeue',
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Reading Level Information
                          _buildReadingLevelSection(theme, primaryColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Back button
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios_new, color: onPrimary),
                      label: Text(
                        "Back to Class",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'ComicNeue',
                          color: onPrimary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: onPrimary,
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                        shadowColor: primaryColor.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingView(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: primaryColor,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text(
            "Loading reading level...",
            style: TextStyle(
              fontSize: 16,
              color: primaryColor.withOpacity(0.8),
              fontFamily: 'ComicNeue',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingLevelSection(ThemeData theme, Color primaryColor) {
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final surfaceVariant = theme.colorScheme.surfaceVariant;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final primaryContainer = theme.colorScheme.primaryContainer;
    final onPrimaryContainer = theme.colorScheme.onPrimaryContainer;
    final secondaryContainer = theme.colorScheme.secondaryContainer;
    final onSecondaryContainer = theme.colorScheme.onSecondaryContainer;
    final tertiaryContainer = theme.colorScheme.tertiaryContainer;
    final onTertiaryContainer = theme.colorScheme.onTertiaryContainer;

    if (_readingLevelData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 40,
              color: onPrimaryContainer,
            ),
            const SizedBox(height: 12),
            Text(
              "No Reading Level Assigned",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: onPrimaryContainer,
                fontFamily: 'ComicNeue',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "This student hasn't been assigned a reading level yet.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: onPrimaryContainer.withOpacity(0.8),
                fontFamily: 'ComicNeue',
              ),
            ),
          ],
        ),
      );
    }

    final levelNumber = _readingLevelData!['level_number']?.toString() ?? 'N/A';
    final levelTitle = _readingLevelData!['title']?.toString() ?? 'Unknown';
    final levelDescription = _readingLevelData!['description']?.toString();
    final updatedAt = _studentData?['reading_level_updated_at']?.toString();
    
    // Format the last updated date
    String formattedDate = 'Not available';
    if (updatedAt != null) {
      try {
        final date = DateTime.parse(updatedAt).toLocal();
        formattedDate = '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Reading Level Icon and Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 28,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reading Level",
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurfaceVariant,
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                  Text(
                    "$levelTitle (Level $levelNumber)",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Level Description
          if (levelDescription != null && levelDescription.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Level Description:",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: onPrimaryContainer,
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    levelDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: onPrimaryContainer,
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Last Updated
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tertiaryContainer ?? primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (tertiaryContainer ?? primaryColor.withOpacity(0.2)).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.update_rounded,
                  size: 20,
                  color: onTertiaryContainer ?? primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Last updated: $formattedDate",
                    style: TextStyle(
                      fontSize: 14,
                      color: onTertiaryContainer ?? onSurface,
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Progress Indicator
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: secondaryContainer ?? primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (secondaryContainer ?? primaryColor.withOpacity(0.1)).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 20,
                      color: onSecondaryContainer ?? primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Reading Progress",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: onSecondaryContainer ?? onSurface,
                        fontFamily: 'ComicNeue',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.3, // Replace with actual progress data
                  backgroundColor: (secondaryContainer ?? primaryColor.withOpacity(0.1)).withOpacity(0.3),
                  color: primaryColor,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Level $levelNumber",
                      style: TextStyle(
                        fontSize: 12,
                        color: onSecondaryContainer?.withOpacity(0.8) ?? onSurfaceVariant,
                        fontFamily: 'ComicNeue',
                      ),
                    ),
                    Text(
                      "Level ${int.tryParse(levelNumber) != null ? int.parse(levelNumber) + 1 : 'N/A'}",
                      style: TextStyle(
                        fontSize: 12,
                        color: onSecondaryContainer?.withOpacity(0.8) ?? onSurfaceVariant,
                        fontFamily: 'ComicNeue',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Keep reading to advance to the next level!",
                  style: TextStyle(
                    fontSize: 12,
                    color: onSecondaryContainer?.withOpacity(0.6) ?? onSurfaceVariant,
                    fontFamily: 'ComicNeue',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(Color backgroundColor, Color textColor) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: Text(
        widget.avatarLetter.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          fontFamily: 'ComicNeue',
        ),
      ),
    );
  }
}