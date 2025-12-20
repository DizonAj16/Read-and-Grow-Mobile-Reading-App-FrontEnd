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
    final primaryContainer = theme.colorScheme.primaryContainer;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final surfaceVariant = theme.colorScheme.surfaceVariant;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

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
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _isLoading
          ? _buildLoadingView(primaryColor)
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    
                    // Profile Avatar
                    _buildProfileAvatar(primaryColor),
                    
                    const SizedBox(height: 24),
                    
                    // Student Name
                    _buildStudentNameSection(widget.name, onSurface),
                    
                    const SizedBox(height: 24),
                    
                    // Reading Level Card
                    _buildReadingLevelCard(
                      theme,
                      primaryColor,
                      primaryContainer,
                      surface,
                      onSurface,
                      surfaceVariant,
                      onSurfaceVariant,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    
                    
                    // Back Button
                    _buildBackButton(primaryColor),
                    
                    const SizedBox(height: 30),
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
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            "Loading reading level...",
            style: TextStyle(
              fontSize: 16,
              color: primaryColor.withOpacity(0.8),
              fontFamily: 'ComicNeue',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(Color primaryColor) {
    return Hero(
      tag: 'avatar_${widget.name}',
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: primaryColor, width: 4),
          gradient: LinearGradient(
            colors: [
              primaryColor.withOpacity(0.1),
              primaryColor.withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: (widget.profileUrl != null && widget.profileUrl!.isNotEmpty)
              ? FadeInImage.assetNetwork(
                  placeholder: 'assets/placeholder/avatar_placeholder.png',
                  image: widget.profileUrl!,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (_, __, ___) => _buildAvatarFallback(),
                )
              : _buildAvatarFallback(),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      color: primaryColor.withOpacity(0.1),
      alignment: Alignment.center,
      child: Text(
        widget.avatarLetter.toUpperCase(),
        style: TextStyle(
          color: primaryColor,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          fontFamily: 'ComicNeue',
        ),
      ),
    );
  }

  Widget _buildStudentNameSection(String name, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'ComicNeue',
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildReadingLevelCard(
    ThemeData theme,
    Color primaryColor,
    Color primaryContainer,
    Color surface,
    Color onSurface,
    Color surfaceVariant,
    Color onSurfaceVariant,
  ) {
    if (_readingLevelData == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: primaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              "No Reading Level Assigned",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'ComicNeue',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "This student hasn't been assigned a reading level yet.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
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
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 28,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Reading Level",
                      style: TextStyle(
                        fontSize: 14,
                        color: onSurfaceVariant,
                        fontFamily: 'ComicNeue',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$levelTitle",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontFamily: 'ComicNeue',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Level $levelNumber",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'ComicNeue',
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Description
          if (levelDescription != null && levelDescription.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Level Description:",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    levelDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurfaceVariant,
                      fontFamily: 'ComicNeue',
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Last Updated
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: surfaceVariant.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.update_rounded,
                  size: 22,
                  color: primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Last updated: $formattedDate",
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurfaceVariant,
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildStatsSection(Color primaryColor, Color surfaceVariant, Color onSurfaceVariant) {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(color: primaryColor.withOpacity(0.2)),
  //       boxShadow: [
  //         BoxShadow(
  //           color: primaryColor.withOpacity(0.1),
  //           blurRadius: 10,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(
  //               Icons.trending_up_rounded,
  //               size: 24,
  //               color: primaryColor,
  //             ),
  //             const SizedBox(width: 10),
  //             Text(
  //               "Reading Progress",
  //               style: TextStyle(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.bold,
  //                 color: onSurfaceVariant,
  //                 fontFamily: 'ComicNeue',
  //               ),
  //             ),
  //           ],
  //         ),
          
  //         const SizedBox(height: 16),
          
  //         // Progress Bar
  //         Container(
  //           padding: const EdgeInsets.symmetric(vertical: 8),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Text(
  //                     "Level 1",
  //                     style: TextStyle(
  //                       fontSize: 12,
  //                       color: onSurfaceVariant,
  //                       fontFamily: 'ComicNeue',
  //                     ),
  //                   ),
  //                   Text(
  //                     "Level 10",
  //                     style: TextStyle(
  //                       fontSize: 12,
  //                       color: onSurfaceVariant,
  //                       fontFamily: 'ComicNeue',
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 6),
  //               Container(
  //                 height: 12,
  //                 decoration: BoxDecoration(
  //                   color: surfaceVariant.withOpacity(0.3),
  //                   borderRadius: BorderRadius.circular(6),
  //                 ),
  //                 child: FractionallySizedBox(
  //                   alignment: Alignment.centerLeft,
  //                   widthFactor: 0.3, // Replace with actual progress data
  //                   child: Container(
  //                     decoration: BoxDecoration(
  //                       gradient: LinearGradient(
  //                         colors: [
  //                           primaryColor,
  //                           primaryColor.withOpacity(0.8),
  //                         ],
  //                       ),
  //                       borderRadius: BorderRadius.circular(6),
  //                       boxShadow: [
  //                         BoxShadow(
  //                           color: primaryColor.withOpacity(0.3),
  //                           blurRadius: 4,
  //                           offset: const Offset(0, 2),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //               const SizedBox(height: 8),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Text(
  //                     "Current: Level 3", // Replace with actual level
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w600,
  //                       color: primaryColor,
  //                       fontFamily: 'ComicNeue',
  //                     ),
  //                   ),
  //                   Text(
  //                     "30% Complete", // Replace with actual percentage
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w600,
  //                       color: primaryColor,
  //                       fontFamily: 'ComicNeue',
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
          
  //         const SizedBox(height: 20),
          
  //         // // Quick Stats
  //         // Row(
  //         //   mainAxisAlignment: MainAxisAlignment.spaceAround,
  //         //   children: [
  //         //     _buildStatItem(
  //         //       Icons.book_rounded,
  //         //       "Books Read",
  //         //       "12", // Replace with actual data
  //         //       primaryColor,
  //         //     ),
  //         //     _buildStatItem(
  //         //       Icons.timer_rounded,
  //         //       "Reading Time",
  //         //       "24h", // Replace with actual data
  //         //       primaryColor,
  //         //     ),
  //         //     _buildStatItem(
  //         //       Icons.star_rounded,
  //         //       "Avg. Score",
  //         //       "85%", // Replace with actual data
  //         //       primaryColor,
  //         //     ),
  //         //   ],
  //         // ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildStatItem(IconData icon, String label, String value, Color primaryColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 24,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
            fontFamily: 'ComicNeue',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'ComicNeue',
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(Color primaryColor) {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 4,
        shadowColor: primaryColor.withOpacity(0.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_back_ios_new, size: 18),
          const SizedBox(width: 8),
          Text(
            "Back to Class",
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'ComicNeue',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}