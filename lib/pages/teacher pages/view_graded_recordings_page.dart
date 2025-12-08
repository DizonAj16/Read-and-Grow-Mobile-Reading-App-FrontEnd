import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:just_audio/just_audio.dart';

class ViewGradedRecordingsPage extends StatefulWidget {
  final String? classId;
  final VoidCallback? onWillPop;

  const ViewGradedRecordingsPage({super.key, this.classId, this.onWillPop});

  @override
  State<ViewGradedRecordingsPage> createState() =>
      _ViewGradedRecordingsPageState();
}

class _ViewGradedRecordingsPageState extends State<ViewGradedRecordingsPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 0;
  final int pageSize = 20;

  List<Map<String, dynamic>> gradedRecordings = [];
  Map<String, String> studentNames = {};
  Map<String, Map<String, dynamic>> taskDetails = {};
  Map<String, Map<String, dynamic>> materialDetails = {};
  Map<String, String> _studentProfilePictures = {};

  // Filter states
  String? selectedStudentId;
  DateTime? startDate;
  DateTime? endDate;
  String? selectedType;
  String? selectedScoreRange;
  bool showFilters = false;

  // Audio player states
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;
  bool _isPlaying = false;
  bool _isLoadingAudio = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  // Layout states
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _filtersPanelKey = GlobalKey();
  Timer? _filterDebounceTimer;

  @override
  void initState() {
    super.initState();
    _loadGradedRecordings(reset: true);
    _scrollController.addListener(_scrollListener);
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterDebounceTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _setupAudioPlayer() async {
    // Listen to player events
    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _audioDuration = duration ?? Duration.zero;
        });
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() => _audioPosition = position);
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isLoadingAudio =
              state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });

        // Reset current playing ID when audio completes
        if (state.processingState == ProcessingState.completed) {
          _audioPlayer.seek(Duration.zero);
          if (mounted) {
            setState(() {
              _currentlyPlayingId = null;
              _isPlaying = false;
              _audioPosition = Duration.zero;
            });
          }
        }
      }
    });
  }

  Future<void> _playRecording(String recordingId, String? audioUrl) async {
    if (audioUrl == null || audioUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No recording available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      setState(() {
        _isLoadingAudio = true;
      });

      // If already playing this recording, pause it
      if (_currentlyPlayingId == recordingId && _isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
        return;
      }

      // If playing a different recording, stop it first
      if (_currentlyPlayingId != null && _currentlyPlayingId != recordingId) {
        await _audioPlayer.stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Play the new recording
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();

      if (mounted) {
        setState(() {
          _currentlyPlayingId = recordingId;
          _isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint('Error playing recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play recording: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
        });
      }
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    if (mounted) {
      setState(() {
        _currentlyPlayingId = null;
        _isPlaying = false;
        _audioPosition = Duration.zero;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        hasMore &&
        !isLoadingMore) {
      _loadMoreRecordings();
    }
  }

  Future<void> _loadGradedRecordings({bool reset = false}) async {
    if (reset) {
      if (mounted) {
        setState(() {
          isLoading = true;
          currentPage = 0;
          gradedRecordings.clear();
          hasMore = true;
        });
      }
    } else {
      if (mounted) {
        setState(() => isLoading = true);
      }
    }

    try {
      studentNames.clear();
      taskDetails.clear();
      materialDetails.clear();

      var query = supabase
          .from('student_recordings')
          .select('*')
          .eq('needs_grading', false)
          .not('score', 'is', null);

      if (widget.classId != null) {
        query = query.eq('class_id', widget.classId!);
      }

      if (selectedStudentId != null) {
        query = query.eq('student_id', selectedStudentId!);
      }

      if (startDate != null) {
        query = query.gte('graded_at', startDate!.toIso8601String());
      }

      if (endDate != null) {
        final endDatePlusOne = endDate!.add(const Duration(days: 1));
        query = query.lt('graded_at', endDatePlusOne.toIso8601String());
      }

      if (selectedType == 'task') {
        query = query.not('task_id', 'is', null);
      } else if (selectedType == 'material') {
        query = query.not('material_id', 'is', null);
      }

      if (selectedScoreRange == 'high') {
        query = query.gte('score', 4.0);
      } else if (selectedScoreRange == 'medium') {
        query = query.gte('score', 3.0).lt('score', 4.0);
      } else if (selectedScoreRange == 'low') {
        query = query.lt('score', 3.0);
      }

      final from = currentPage * pageSize;
      final to = (currentPage + 1) * pageSize - 1;

      final recordingsRes = await query
          .order('graded_at', ascending: false)
          .range(from, to);

      final newRecordings = List<Map<String, dynamic>>.from(recordingsRes);

      if (newRecordings.length < pageSize) {
        hasMore = false;
      }

      final studentIds =
          newRecordings
              .map((r) => r['student_id'])
              .whereType<String>()
              .toSet()
              .toList();

      final taskIds =
          newRecordings
              .map((r) => r['task_id'])
              .whereType<String>()
              .toSet()
              .toList();

      final materialIds =
          newRecordings
              .map((r) => r['material_id'])
              .whereType<String>()
              .toSet()
              .toList();

      if (studentIds.isNotEmpty) {
        final studentsRes = await supabase
            .from('students')
            .select('id, student_name, profile_picture')
            .inFilter('id', studentIds);

        for (var student in studentsRes) {
          final uid = student['id']?.toString();
          if (uid != null) {
            studentNames[uid] = student['student_name'] ?? 'Unknown';
            _studentProfilePictures[uid] =
                student['profile_picture']?.toString() ?? '';
          }
        }
      }

      if (taskIds.isNotEmpty) {
        final tasksRes = await supabase
            .from('tasks')
            .select('id, title, description')
            .inFilter('id', taskIds);

        for (var task in tasksRes) {
          final tid = task['id']?.toString();
          if (tid != null) taskDetails[tid] = Map<String, dynamic>.from(task);
        }
      }

      if (materialIds.isNotEmpty) {
        final materialsRes = await supabase
            .from('reading_materials')
            .select('id, title')
            .inFilter('id', materialIds);

        for (var material in materialsRes) {
          final mid = material['id']?.toString();
          if (mid != null) {
            materialDetails[mid] = Map<String, dynamic>.from(material);
          }
        }
      }

      if (mounted) {
        setState(() {
          if (reset) {
            gradedRecordings = newRecordings;
          } else {
            gradedRecordings.addAll(newRecordings);
          }
          isLoading = false;
          currentPage++;
        });
      }
    } catch (e) {
      debugPrint('Error loading graded recordings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading graded recordings: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadMoreRecordings() async {
    if (isLoadingMore || !hasMore) return;

    if (mounted) {
      setState(() => isLoadingMore = true);
    }

    try {
      await _loadGradedRecordings(reset: false);
    } finally {
      if (mounted) {
        setState(() => isLoadingMore = false);
      }
    }
  }

  void _applyFilters() {
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadGradedRecordings(reset: true);
      if (mounted && showFilters) {
        setState(() => showFilters = false);
      }
    });
  }

  void _clearFilters() {
    if (mounted) {
      setState(() {
        selectedStudentId = null;
        startDate = null;
        endDate = null;
        selectedType = null;
        selectedScoreRange = null;
      });
    }
    _applyFilters();
  }

  Widget _buildFiltersPanel() {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: showFilters ? null : 0,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child:
          showFilters
              ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter Recordings',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[900],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: Colors.grey[600],
                              size: isMobile ? 22 : 24,
                            ),
                            onPressed: () {
                              if (mounted) {
                                setState(() => showFilters = false);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Student Filter
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Student',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(
                            isMobile ? 12 : 16,
                          ),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStudentId,
                            hint: const Text('All Students'),
                            isExpanded: true,
                            icon: Icon(
                              Icons.expand_more,
                              color: Colors.grey[600],
                              size: isMobile ? 20 : 24,
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'All Students',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              ...studentNames.entries.map((entry) {
                                return DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              if (mounted) {
                                setState(() => selectedStudentId = value);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date Range
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Grading Date Range',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null && mounted) {
                                  setState(() => startDate = date);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 12 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 12 : 16,
                                  ),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: isMobile ? 18 : 20,
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(width: isMobile ? 8 : 12),
                                    Expanded(
                                      child: Text(
                                        startDate != null
                                            ? DateFormat(
                                              'MMM d, y',
                                            ).format(startDate!)
                                            : 'Start Date',
                                        style: TextStyle(
                                          color:
                                              startDate != null
                                                  ? Colors.grey[900]
                                                  : Colors.grey[500],
                                          fontWeight:
                                              startDate != null
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                          fontSize: isMobile ? 14 : 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isMobile ? 8 : 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: endDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null && mounted) {
                                  setState(() => endDate = date);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 12 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 12 : 16,
                                  ),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: isMobile ? 18 : 20,
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(width: isMobile ? 8 : 12),
                                    Expanded(
                                      child: Text(
                                        endDate != null
                                            ? DateFormat(
                                              'MMM d, y',
                                            ).format(endDate!)
                                            : 'End Date',
                                        style: TextStyle(
                                          color:
                                              endDate != null
                                                  ? Colors.grey[900]
                                                  : Colors.grey[500],
                                          fontWeight:
                                              endDate != null
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                          fontSize: isMobile ? 14 : 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Type Filter
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Recording Type',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(
                            isMobile ? 12 : 16,
                          ),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedType,
                            hint: const Text('All Types'),
                            isExpanded: true,
                            icon: Icon(
                              Icons.expand_more,
                              color: Colors.grey[600],
                              size: isMobile ? 20 : 24,
                            ),
                            items: const [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'All Types',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              DropdownMenuItem<String>(
                                value: 'task',
                                child: Text(
                                  'Task Recordings',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              DropdownMenuItem<String>(
                                value: 'material',
                                child: Text(
                                  'Reading Material Recordings',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (mounted) {
                                setState(() => selectedType = value);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Score Range Filter
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Score Range',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(
                            isMobile ? 12 : 16,
                          ),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedScoreRange,
                            hint: const Text('All Scores'),
                            isExpanded: true,
                            icon: Icon(
                              Icons.expand_more,
                              color: Colors.grey[600],
                              size: isMobile ? 20 : 24,
                            ),
                            items: const [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'All Scores',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              DropdownMenuItem<String>(
                                value: 'high',
                                child: Text(
                                  'High (4.0 - 5.0)',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              DropdownMenuItem<String>(
                                value: 'medium',
                                child: Text(
                                  'Medium (3.0 - 3.9)',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              DropdownMenuItem<String>(
                                value: 'low',
                                child: Text(
                                  'Low (0.0 - 2.9)',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (mounted) {
                                setState(() => selectedScoreRange = value);
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 20 : 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _clearFilters,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: isMobile ? 14 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 12 : 16,
                                  ),
                                ),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                'Clear Filters',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isMobile ? 10 : 14),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _applyFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: isMobile ? 14 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 12 : 16,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Apply Filters',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildStatsHeader() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isMobile = MediaQuery.of(context).size.width < 600;

    double averageScore = 0;
    if (gradedRecordings.isNotEmpty) {
      final totalScore = gradedRecordings
          .map((r) => r['score'] is num ? r['score'].toDouble() : 0.0)
          .reduce((a, b) => a + b);
      averageScore = totalScore / gradedRecordings.length;
    }

    int highCount = 0;
    int mediumCount = 0;
    int lowCount = 0;
    for (var recording in gradedRecordings) {
      final score =
          recording['score'] is num ? recording['score'].toDouble() : 0.0;
      if (score >= 4.0) {
        highCount++;
      } else if (score >= 3.0) {
        mediumCount++;
      } else {
        lowCount++;
      }
    }

    int activeFilterCount = 0;
    if (selectedStudentId != null) activeFilterCount++;
    if (startDate != null) activeFilterCount++;
    if (endDate != null) activeFilterCount++;
    if (selectedType != null) activeFilterCount++;
    if (selectedScoreRange != null) activeFilterCount++;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.08),
            primaryColor.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                ),
                child: Icon(
                  Iconsax.tick_circle,
                  color: primaryColor,
                  size: isMobile ? 22 : 24,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Graded Recordings',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                      ),
                    ),
                    SizedBox(height: isMobile ? 2 : 4),
                    Text(
                      '${gradedRecordings.length} recording${gradedRecordings.length == 1 ? '' : 's'} reviewed',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 10,
                        vertical: isMobile ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getScoreColor(averageScore / 5.0, primaryColor),
                            _getScoreColor(
                              averageScore / 5.0,
                              primaryColor,
                            ).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Avg: ${averageScore.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 13 : 14,
                            ),
                          ),
                          SizedBox(width: isMobile ? 4 : 6),
                          _buildStarRating(
                            averageScore,
                            size: isMobile ? 14 : 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),

          // Performance Distribution
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDistributionItem(
                  'High',
                  highCount,
                  Colors.green,
                  isMobile,
                ),
                _buildDistributionItem(
                  'Medium',
                  mediumCount,
                  Colors.orange,
                  isMobile,
                ),
                _buildDistributionItem('Low', lowCount, primaryColor, isMobile),
              ],
            ),
          ),

          if (activeFilterCount > 0) ...[
            SizedBox(height: isMobile ? 8 : 12),
            Container(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt_rounded,
                    size: isMobile ? 14 : 16,
                    color: primaryColor,
                  ),
                  SizedBox(width: isMobile ? 6 : 8),
                  Expanded(
                    child: Text(
                      '$activeFilterCount filter${activeFilterCount > 1 ? 's' : ''} active',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: primaryColor.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDistributionItem(
    String label,
    int count,
    Color color,
    bool isMobile,
  ) {
    return Column(
      children: [
        Container(
          width: isMobile ? 36 : 40,
          height: isMobile ? 36 : 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 4 : 6),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 11 : 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 6 : 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (mounted) {
                  setState(() => showFilters = !showFilters);
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 20,
                  vertical: isMobile ? 14 : 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: Colors.grey[500],
                      size: isMobile ? 20 : 22,
                    ),
                    SizedBox(width: isMobile ? 10 : 12),
                    Expanded(
                      child: Text(
                        'Search & Filter',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isMobile ? 15 : 16,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: showFilters ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: primaryColor,
                        size: isMobile ? 22 : 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: isMobile ? 20 : 24,
              ),
              onPressed: () => _loadGradedRecordings(reset: true),
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: () async {
        if (widget.onWillPop != null) {
          widget.onWillPop!();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Graded Recordings',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              if (widget.classId != null)
                Text(
                  'Class View',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: isMobile ? 12 : 16),
              child: CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.1),
                radius: isMobile ? 20 : 22,
                child: IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: primaryColor,
                    size: isMobile ? 20 : 24,
                  ),
                  onPressed: widget.onWillPop,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildFilterChip(),
              Expanded(
                child:
                    isLoading && gradedRecordings.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: primaryColor,
                                strokeWidth: 2.5,
                              ),
                              SizedBox(height: isMobile ? 20 : 24),
                              Text(
                                'Loading Graded Recordings...',
                                style: TextStyle(
                                  fontSize: isMobile ? 15 : 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                        : gradedRecordings.isEmpty
                        ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.all(isMobile ? 20 : 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: isMobile ? 100 : 120,
                                height: isMobile ? 100 : 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.withOpacity(0.1),
                                      Colors.lightBlue.withOpacity(0.1),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.assignment_outlined,
                                  size: isMobile ? 48 : 64,
                                  color: Colors.blue[400],
                                ),
                              ),
                              SizedBox(height: isMobile ? 20 : 24),
                              Text(
                                'No Graded Recordings',
                                style: TextStyle(
                                  fontSize: isMobile ? 20 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              SizedBox(height: isMobile ? 8 : 12),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 24 : 40,
                                ),
                                child: Text(
                                  widget.classId != null
                                      ? 'No graded recordings found for this class.'
                                      : 'Graded recordings will appear here once you\'ve reviewed student submissions.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              SizedBox(height: isMobile ? 24 : 32),
                              ElevatedButton.icon(
                                onPressed:
                                    () => _loadGradedRecordings(reset: true),
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  size: isMobile ? 18 : 20,
                                ),
                                label: Text(
                                  'Refresh List',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 20 : 24,
                                    vertical: isMobile ? 14 : 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      isMobile ? 14 : 16,
                                    ),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        )
                        : Column(
                          children: [
                            _buildFiltersPanel(),
                            _buildStatsHeader(),
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: () async {
                                  await _loadGradedRecordings(reset: true);
                                },
                                color: primaryColor,
                                backgroundColor: Colors.white,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.only(
                                    bottom: isMobile ? 60 : 80,
                                  ),
                                  itemCount:
                                      gradedRecordings.length +
                                      (hasMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index >= gradedRecordings.length) {
                                      return _buildLoadingMoreIndicator();
                                    }
                                    return Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        isMobile ? 12 : 16,
                                        0,
                                        isMobile ? 12 : 16,
                                        index == gradedRecordings.length - 1
                                            ? (isMobile ? 20 : 24)
                                            : (isMobile ? 12 : 16),
                                      ),
                                      child: _buildRecordingCard(
                                        gradedRecordings[index],
                                        index,
                                      ),
                                    );
                                  },
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
  }

  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child:
            isLoadingMore
                ? CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                )
                : const SizedBox(),
      ),
    );
  }

  Widget _buildRecordingCard(Map<String, dynamic> recording, int index) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final studentId = recording['student_id']?.toString() ?? '';
    final taskId = recording['task_id']?.toString();
    final studentName = studentNames[studentId] ?? 'Unknown Student';
    final recordingId = recording['id']?.toString() ?? '';
    final recordingUrl =
        recording['file_url']?.toString() ??
        recording['recording_url']?.toString() ??
        '';
    final isPlaying = _currentlyPlayingId == recordingId && _isPlaying;

    String title = 'Unknown Task';
    String typeLabel = 'Task';
    Color typeColor = Colors.blue;

    if (taskId != null && taskId.isNotEmpty) {
      final task = taskDetails[taskId];
      title = task?['title']?.toString() ?? 'Unknown Task';
      typeLabel = 'Task';
      typeColor = Colors.blue;
    } else {
      final materialId = recording['material_id']?.toString();
      if (materialId != null) {
        final material = materialDetails[materialId];
        title = material?['title']?.toString() ?? 'Unknown Reading Material';
        typeLabel = 'Reading';
        typeColor = Colors.purple;
      }
    }

    final materialId = recording['material_id']?.toString();
    if (materialId != null && materialDetails.containsKey(materialId)) {
      final material = materialDetails[materialId];
      title = material?['title']?.toString() ?? 'Unknown Reading Material';
      typeLabel = 'Reading';
      typeColor = Colors.purple;
    }

    final score = recording['score'];
    final scoreValue =
        score is num
            ? score.toDouble()
            : double.tryParse(score.toString()) ?? 0.0;
    final comments = recording['teacher_comments']?.toString();
    final gradedAt = recording['graded_at']?.toString();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          leading: _buildStudentAvatar(studentId, studentName, isMobile),
          title: Text(
            studentName,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? 4 : 6),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 10,
                      vertical: isMobile ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 11,
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 10),
                  if (gradedAt != null)
                    Expanded(
                      child: Text(
                        _formatDateTime(gradedAt),
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 12,
              vertical: isMobile ? 6 : 8,
            ),
            decoration: BoxDecoration(
              gradient: _getScoreGradient(scoreValue / 5.0, primaryColor),
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${scoreValue.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
                SizedBox(width: isMobile ? 4 : 6),
                _buildStarRating(scoreValue, size: isMobile ? 14 : 16),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          ),
          tilePadding: EdgeInsets.all(isMobile ? 16 : 20),
          childrenPadding: EdgeInsets.zero,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(isMobile ? 16 : 20),
                  bottomRight: Radius.circular(isMobile ? 16 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Score Details
                  Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Score Rating Stars (Visual representation)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < 5; i++)
                              Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 2 : 4,
                                ),
                                child: Icon(
                                  i < scoreValue.floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: isMobile ? 28 : 32,
                                  color:
                                      i < scoreValue.floor()
                                          ? Colors.amber
                                          : Colors.grey[400],
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),

                        // Score Assessment Text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Score Assessment: ',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              '${scoreValue.toStringAsFixed(1)}/5',
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey[900],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 8 : 12),

                        // Percentage Circle
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 20 : 24,
                            vertical: isMobile ? 10 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: _getScoreColor(
                              scoreValue / 5.0,
                              primaryColor,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              isMobile ? 12 : 16,
                            ),
                            border: Border.all(
                              color: _getScoreColor(
                                scoreValue / 5.0,
                                primaryColor,
                              ).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'PERCENTAGE',
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: _getScoreColor(
                                    scoreValue / 5.0,
                                    primaryColor,
                                  ),
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(height: isMobile ? 4 : 6),
                              Text(
                                '${(scoreValue / 5 * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: isMobile ? 32 : 36,
                                  fontWeight: FontWeight.bold,
                                  color: _getScoreColor(
                                    scoreValue / 5.0,
                                    primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Recording Playback
                  SizedBox(height: isMobile ? 12 : 16),
                  Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isMobile ? 8 : 10),
                              decoration: BoxDecoration(
                                color:
                                    isPlaying
                                        ? Colors.orange.withOpacity(0.15)
                                        : Colors.blue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(
                                  isMobile ? 10 : 12,
                                ),
                              ),
                              child: Icon(
                                isPlaying
                                    ? Iconsax.pause_circle
                                    : Iconsax.play_circle,
                                color: isPlaying ? Colors.orange : Colors.blue,
                                size: isMobile ? 22 : 24,
                              ),
                            ),
                            SizedBox(width: isMobile ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Student Recording',
                                    style: TextStyle(
                                      fontSize: isMobile ? 15 : 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blueGrey[800],
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 3 : 4),
                                  Text(
                                    recordingUrl.isNotEmpty
                                        ? (isPlaying
                                            ? 'Now playing...'
                                            : 'Listen to student\'s submission')
                                        : 'No recording available',
                                    style: TextStyle(
                                      fontSize: isMobile ? 13 : 14,
                                      color:
                                          recordingUrl.isNotEmpty
                                              ? Colors.grey[600]
                                              : Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isPlaying)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 8 : 10,
                                  vertical: isMobile ? 4 : 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 8 : 10,
                                  ),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.volume_up,
                                      size: isMobile ? 12 : 14,
                                      color: Colors.green[600],
                                    ),
                                    SizedBox(width: isMobile ? 4 : 6),
                                    Text(
                                      'Playing',
                                      style: TextStyle(
                                        fontSize: isMobile ? 11 : 12,
                                        color: Colors.green[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),

                        // Audio Player Controls
                        Container(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(
                              isMobile ? 12 : 16,
                            ),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              // Progress Bar
                              Column(
                                children: [
                                  // Duration display
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(_audioPosition),
                                        style: TextStyle(
                                          fontSize: isMobile ? 11 : 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(_audioDuration),
                                        style: TextStyle(
                                          fontSize: isMobile ? 11 : 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isMobile ? 8 : 10),
                                  // Slider
                                  Slider(
                                    value:
                                        _currentlyPlayingId == recordingId
                                            ? _audioPosition.inSeconds
                                                .toDouble()
                                                .clamp(
                                                  0.0,
                                                  _audioDuration.inSeconds
                                                      .toDouble(),
                                                )
                                            : 0.0,
                                    min: 0,
                                    max: _audioDuration.inSeconds
                                        .toDouble()
                                        .clamp(1.0, double.infinity),
                                    onChanged:
                                        recordingUrl.isNotEmpty &&
                                                _currentlyPlayingId ==
                                                    recordingId
                                            ? (value) {
                                              _audioPlayer.seek(
                                                Duration(
                                                  seconds: value.toInt(),
                                                ),
                                              );
                                            }
                                            : null,
                                    activeColor:
                                        recordingUrl.isNotEmpty &&
                                                _currentlyPlayingId ==
                                                    recordingId
                                            ? Colors.blue
                                            : Colors.grey[400],
                                    inactiveColor: Colors.grey[300],
                                    thumbColor:
                                        recordingUrl.isNotEmpty &&
                                                _currentlyPlayingId ==
                                                    recordingId
                                            ? Colors.blue
                                            : Colors.grey[400],
                                  ),
                                  SizedBox(height: isMobile ? 12 : 16),
                                ],
                              ),

                              // Player Controls
                              if (isMobile)
                                Column(
                                  children: [
                                    // Play/Pause Button (full width on mobile)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed:
                                            recordingUrl.isNotEmpty
                                                ? () async {
                                                  if (isPlaying) {
                                                    await _pauseAudio();
                                                  } else {
                                                    await _playRecording(
                                                      recordingId,
                                                      recordingUrl,
                                                    );
                                                  }
                                                }
                                                : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              _isLoadingAudio
                                                  ? Colors.grey
                                                  : isPlaying
                                                  ? Colors.orange
                                                  : Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: isMobile ? 14 : 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              isMobile ? 12 : 14,
                                            ),
                                          ),
                                          elevation: 0,
                                          disabledBackgroundColor:
                                              Colors.grey[300],
                                        ),
                                        child:
                                            _isLoadingAudio &&
                                                    _currentlyPlayingId ==
                                                        recordingId
                                                ? SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                                : Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      isPlaying
                                                          ? Icons.pause
                                                          : Icons.play_arrow,
                                                      size: isMobile ? 20 : 22,
                                                    ),
                                                    SizedBox(
                                                      width: isMobile ? 8 : 10,
                                                    ),
                                                    Text(
                                                      isPlaying
                                                          ? 'Pause'
                                                          : 'Play',
                                                      style: TextStyle(
                                                        fontSize:
                                                            isMobile ? 14 : 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                      ),
                                    ),
                                    SizedBox(height: isMobile ? 12 : 16),

                                    // Stop and Restart buttons side by side
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed:
                                                recordingUrl.isNotEmpty &&
                                                        _currentlyPlayingId ==
                                                            recordingId
                                                    ? _stopAudio
                                                    : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  recordingUrl.isNotEmpty &&
                                                          _currentlyPlayingId ==
                                                              recordingId
                                                      ? Colors.red
                                                      : Colors.grey[300],
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                vertical: isMobile ? 14 : 16,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      isMobile ? 12 : 14,
                                                    ),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.stop,
                                                  size: isMobile ? 18 : 20,
                                                ),
                                                SizedBox(
                                                  width: isMobile ? 6 : 8,
                                                ),
                                                Text(
                                                  'Stop',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isMobile ? 14 : 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: isMobile ? 12 : 16),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed:
                                                recordingUrl.isNotEmpty &&
                                                        _currentlyPlayingId ==
                                                            recordingId
                                                    ? () async {
                                                      await _audioPlayer.seek(
                                                        Duration.zero,
                                                      );
                                                    }
                                                    : null,
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color:
                                                    recordingUrl.isNotEmpty &&
                                                            _currentlyPlayingId ==
                                                                recordingId
                                                        ? Colors.grey[400]!
                                                        : Colors.grey[300]!,
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                vertical: isMobile ? 14 : 16,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      isMobile ? 12 : 14,
                                                    ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.replay,
                                                  size: isMobile ? 18 : 20,
                                                  color:
                                                      recordingUrl.isNotEmpty &&
                                                              _currentlyPlayingId ==
                                                                  recordingId
                                                          ? Colors.grey[700]
                                                          : Colors.grey[400],
                                                ),
                                                SizedBox(
                                                  width: isMobile ? 6 : 8,
                                                ),
                                                Text(
                                                  'Restart',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isMobile ? 14 : 16,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        recordingUrl.isNotEmpty &&
                                                                _currentlyPlayingId ==
                                                                    recordingId
                                                            ? Colors.grey[700]
                                                            : Colors.grey[400],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    // Stop Button
                                    ElevatedButton(
                                      onPressed:
                                          recordingUrl.isNotEmpty &&
                                                  _currentlyPlayingId ==
                                                      recordingId
                                              ? _stopAudio
                                              : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            recordingUrl.isNotEmpty &&
                                                    _currentlyPlayingId ==
                                                        recordingId
                                                ? Colors.red
                                                : Colors.grey[300],
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 16 : 20,
                                          vertical: isMobile ? 12 : 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            isMobile ? 12 : 14,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.stop,
                                            size: isMobile ? 18 : 20,
                                          ),
                                          SizedBox(width: isMobile ? 6 : 8),
                                          Text(
                                            'Stop',
                                            style: TextStyle(
                                              fontSize: isMobile ? 14 : 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Play/Pause Button
                                    ElevatedButton(
                                      onPressed:
                                          recordingUrl.isNotEmpty
                                              ? () async {
                                                if (isPlaying) {
                                                  await _pauseAudio();
                                                } else {
                                                  await _playRecording(
                                                    recordingId,
                                                    recordingUrl,
                                                  );
                                                }
                                              }
                                              : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            _isLoadingAudio
                                                ? Colors.grey
                                                : isPlaying
                                                ? Colors.orange
                                                : Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 20 : 24,
                                          vertical: isMobile ? 12 : 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            isMobile ? 12 : 14,
                                          ),
                                        ),
                                        elevation: 0,
                                        disabledBackgroundColor:
                                            Colors.grey[300],
                                      ),
                                      child:
                                          _isLoadingAudio &&
                                                  _currentlyPlayingId ==
                                                      recordingId
                                              ? SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                              : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isPlaying
                                                        ? Icons.pause
                                                        : Icons.play_arrow,
                                                    size: isMobile ? 20 : 22,
                                                  ),
                                                  SizedBox(
                                                    width: isMobile ? 6 : 8,
                                                  ),
                                                  Text(
                                                    isPlaying
                                                        ? 'Pause'
                                                        : 'Play',
                                                    style: TextStyle(
                                                      fontSize:
                                                          isMobile ? 14 : 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                    ),

                                    // Restart Button
                                    OutlinedButton(
                                      onPressed:
                                          recordingUrl.isNotEmpty &&
                                                  _currentlyPlayingId ==
                                                      recordingId
                                              ? () async {
                                                await _audioPlayer.seek(
                                                  Duration.zero,
                                                );
                                              }
                                              : null,
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color:
                                              recordingUrl.isNotEmpty &&
                                                      _currentlyPlayingId ==
                                                          recordingId
                                                  ? Colors.grey[400]!
                                                  : Colors.grey[300]!,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 16 : 20,
                                          vertical: isMobile ? 12 : 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            isMobile ? 12 : 14,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.replay,
                                            size: isMobile ? 18 : 20,
                                            color:
                                                recordingUrl.isNotEmpty &&
                                                        _currentlyPlayingId ==
                                                            recordingId
                                                    ? Colors.grey[700]
                                                    : Colors.grey[400],
                                          ),
                                          SizedBox(width: isMobile ? 6 : 8),
                                          Text(
                                            'Restart',
                                            style: TextStyle(
                                              fontSize: isMobile ? 14 : 16,
                                              color:
                                                  recordingUrl.isNotEmpty &&
                                                          _currentlyPlayingId ==
                                                              recordingId
                                                      ? Colors.grey[700]
                                                      : Colors.grey[400],
                                            ),
                                          ),
                                        ],
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

                  // Teacher Feedback
                  if (comments != null && comments.isNotEmpty) ...[
                    SizedBox(height: isMobile ? 12 : 16),
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isMobile ? 8 : 10),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(
                                isMobile ? 10 : 12,
                              ),
                            ),
                            child: Icon(
                              Iconsax.message_text,
                              color: primaryColor,
                              size: isMobile ? 22 : 24,
                            ),
                          ),
                          SizedBox(width: isMobile ? 12 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Teacher Feedback',
                                  style: TextStyle(
                                    fontSize: isMobile ? 15 : 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blueGrey[800],
                                  ),
                                ),
                                SizedBox(height: isMobile ? 10 : 12),
                                Container(
                                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(
                                      isMobile ? 10 : 12,
                                    ),
                                    border: Border.all(
                                      color: primaryColor.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Text(
                                    comments,
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 15,
                                      color: Colors.blueGrey[800],
                                      height: 1.6,
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

                  // Grading Info
                  SizedBox(height: isMobile ? 12 : 16),
                  Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isMobile ? 8 : 10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(
                              isMobile ? 10 : 12,
                            ),
                          ),
                          child: Icon(
                            Iconsax.tick_circle,
                            color: Colors.green[700],
                            size: isMobile ? 22 : 24,
                          ),
                        ),
                        SizedBox(width: isMobile ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grading Information',
                                style: TextStyle(
                                  fontSize: isMobile ? 15 : 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blueGrey[800],
                                ),
                              ),
                              SizedBox(height: isMobile ? 10 : 12),
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.calendar,
                                    size: isMobile ? 15 : 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: isMobile ? 6 : 8),
                                  Expanded(
                                    child: Text(
                                      _formatDateTime(gradedAt),
                                      style: TextStyle(
                                        fontSize: isMobile ? 13 : 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blueGrey[800],
                                      ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(
    double score, {
    double size = 20,
    bool showHalfStar = false,
  }) {
    final fullStars = score.floor();
    final hasHalfStar = (score - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, size: size, color: Colors.amber);
        } else if (index == fullStars && hasHalfStar && showHalfStar) {
          return Icon(Icons.star_half, size: size, color: Colors.amber);
        } else {
          return Icon(Icons.star_border, size: size, color: Colors.grey[400]);
        }
      }),
    );
  }

  Widget _buildStudentAvatar(String studentId, String name, bool isMobile) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final profileUrl = _studentProfilePictures[studentId];
    final avatarSize = isMobile ? 48.0 : 56.0;

    if (profileUrl == null || profileUrl.isEmpty) {
      return Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withOpacity(0.1),
              primaryColor.withOpacity(0.2),
            ],
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
        ),
      );
    }

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(avatarSize / 2),
        child: Image.network(
          profileUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[100],
              child: Center(
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                  color: primaryColor,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) {
            return Container(
              color: Colors.grey[100],
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    fontSize: isMobile ? 18 : 20,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getScoreColor(double percent, Color primaryColor) {
    if (percent >= 0.8) return Colors.green;
    if (percent >= 0.6) return Colors.orange;
    return primaryColor;
  }

  Gradient _getScoreGradient(double percent, Color primaryColor) {
    if (percent >= 0.8) {
      return LinearGradient(colors: [Colors.green[400]!, Colors.green[600]!]);
    }
    if (percent >= 0.6) {
      return LinearGradient(colors: [Colors.orange[400]!, Colors.orange[600]!]);
    }
    return LinearGradient(
      colors: [primaryColor, primaryColor.withOpacity(0.8)],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return 'Unknown';

    try {
      final dt = DateTime.parse(dateTime);
      final phTime = dt.add(const Duration(hours: 8));
      final formatted = DateFormat('MMMM d, y • h:mm a').format(phTime);
      return formatted;
    } catch (_) {
      return 'Invalid date';
    }
  }
}
