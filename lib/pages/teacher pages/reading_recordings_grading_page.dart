import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:iconsax/iconsax.dart';

class ReadingRecordingsGradingPage extends StatefulWidget {
  final String? classId;
  final VoidCallback? onWillPop;

  const ReadingRecordingsGradingPage({super.key, this.classId, this.onWillPop});

  @override
  State<ReadingRecordingsGradingPage> createState() =>
      _ReadingRecordingsGradingPageState();
}

class _ReadingRecordingsGradingPageState
    extends State<ReadingRecordingsGradingPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 0;
  final int pageSize = 20;

  List<Map<String, dynamic>> recordings = [];
  Map<String, String> studentNames = {};
  Map<String, Map<String, dynamic>> taskDetails = {};
  Map<String, Map<String, dynamic>> materialDetails = {};
  Map<String, String> _studentProfilePictures = {};
  Map<String, Map<String, dynamic>> _studentReadingLevels = {};
  Map<int, Map<String, dynamic>> _readingLevelsCache = {};

  // Filter states
  String? selectedStudentId;
  DateTime? startDate;
  DateTime? endDate;
  String? selectedType;
  bool showFilters = false;
  Timer? _filterDebounceTimer;

  // Classroom info
  String? _className;
  List<Map<String, dynamic>> _classStudents = [];

  // Audio player management - SINGLE PLAYER INSTANCE
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingRecordingId;
  bool _isAudioPlaying = false;
  bool _isAudioLoading = false;
  Duration? _currentDuration;
  Duration? _currentPosition;

  // Expansion states for each recording card
  final Map<String, bool> _expandedStates = {};

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _filtersPanelKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_scrollListener);
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterDebounceTimer?.cancel();

    // Dispose audio player
    _audioPlayer.dispose();

    super.dispose();
  }

  Future<void> _setupAudioPlayer() async {
    // Configure audio session for better playback
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    // Listen to player events
    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _currentDuration = duration;
        });
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = state.playing;
          _isAudioLoading =
              state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });

        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isAudioPlaying = false;
            _currentlyPlayingRecordingId = null;
          });
        }
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      await _loadClassroomInfo();
      if (widget.classId != null && widget.classId!.isNotEmpty) {
        await _loadClassStudents();
      }
      await _loadRecordings(reset: true);
    } catch (e) {
      debugPrint('❌ Error in _loadInitialData: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadClassroomInfo() async {
    if (widget.classId == null) return;

    try {
      final response =
          await supabase
              .from('class_rooms')
              .select('class_name')
              .eq('id', widget.classId!)
              .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _className = response['class_name'] as String?;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading classroom info: $e');
    }
  }

  Future<void> _loadClassStudents() async {
    if (widget.classId == null) return;

  try {
    debugPrint('🔍 Loading students for class: ${widget.classId}');
    
    // Try different table names
    try {
      final response = await supabase
          .from('student_enrollments')
          .select('''
            student_id,
            students(id, student_name, profile_picture, current_reading_level_id)
          ''')
          .eq('class_room_id', widget.classId!);

      debugPrint('📊 Student enrollments response: ${response.length} students');
      
      if (mounted) {
        setState(() {
          _classStudents = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('❌ Error with student_enrollments table: $e');
      // Rest of the fallback code...
    }
    
    debugPrint('📊 Final _classStudents count: ${_classStudents.length}');
  } catch (e) {
      debugPrint('❌ Error loading class students: $e');
      if (mounted) {
        setState(() {
          _classStudents = [];
        });
      }
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

  Future<void> _loadRecordings({bool reset = false}) async {
    if (reset) {
      setState(() {
        currentPage = 0;
        recordings.clear();
        hasMore = true;
        _expandedStates.clear();
      });
    } else {
      if (currentPage == 0) {
        setState(() => isLoading = true);
      }
    }

    try {
      studentNames.clear();
      taskDetails.clear();
      materialDetails.clear();
      _studentReadingLevels.clear();
      Map<String, String> teacherNames = {};

      var query = supabase
          .from('student_recordings')
          .select('*')
          .eq('needs_grading', true);

      // Apply classroom filter
      if (widget.classId != null && widget.classId!.isNotEmpty) {
        if (_classStudents.isEmpty) {
          await _loadClassStudents();
        }

        final studentIds =
            _classStudents
                .map((cs) {
                  try {
                    if (cs['student_id'] != null) {
                      return cs['student_id'] as String?;
                    } else if (cs['students'] != null) {
                      final student = cs['students'] as Map<String, dynamic>;
                      return student['id'] as String?;
                    }
                  } catch (e) {
                    debugPrint('❌ Error extracting student ID: $e');
                  }
                  return null;
                })
                .whereType<String>()
                .toList();

        if (studentIds.isNotEmpty) {
          query = query.inFilter('student_id', studentIds);
        } else {
          // Instead of returning early with empty recordings,
          // just continue without the student filter
          // This will show recordings from all students when classroom has no students
          // or we couldn't load student data
          debugPrint(
            '⚠️ No students found in classroom, showing all pending recordings',
          );
        }
      }

      // Apply filters
      if (selectedStudentId != null) {
        query = query.eq('student_id', selectedStudentId!);
      }

      if (startDate != null) {
        query = query.gte('recorded_at', startDate!.toIso8601String());
      }

      if (endDate != null) {
        final endDatePlusOne = endDate!.add(const Duration(days: 1));
        query = query.lt('recorded_at', endDatePlusOne.toIso8601String());
      }

      if (selectedType == 'task') {
        query = query.not('task_id', 'is', null);
      } else if (selectedType == 'material') {
        query = query.not('material_id', 'is', null);
      }

      final from = currentPage * pageSize;
      final to = (currentPage + 1) * pageSize - 1;

      final recordingsRes = await query
          .order('recorded_at', ascending: false)
          .range(from, to);

      final newRecordings = List<Map<String, dynamic>>.from(recordingsRes);

      // Add debug logs to see what we're getting
      debugPrint('📊 Query result: ${newRecordings.length} recordings');
      debugPrint(
        '📊 Query conditions: needs_grading=true, classId=${widget.classId}',
      );

      if (newRecordings.length < pageSize) {
        hasMore = false;
      }

      // Collect IDs for batch fetching
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

      final teacherIds =
          newRecordings
              .map((r) => r['graded_by'])
              .whereType<String>()
              .toSet()
              .toList();

      // Fetch student data including reading levels
      if (studentIds.isNotEmpty) {
        if (widget.classId != null && _classStudents.isNotEmpty) {
          for (var cs in _classStudents) {
            try {
              final student = cs['students'] as Map<String, dynamic>?;
              if (student != null) {
                final uid = student['id']?.toString();
                if (uid != null && studentIds.contains(uid)) {
                  studentNames[uid] = student['student_name'] ?? 'Unknown';
                  _studentProfilePictures[uid] =
                      student['profile_picture']?.toString() ?? '';
                  _studentReadingLevels[uid] = student;
                }
              }
            } catch (e) {
              debugPrint('❌ Error processing classroom student: $e');
            }
          }

          final missingStudentIds =
              studentIds.where((id) => !studentNames.containsKey(id)).toList();

          if (missingStudentIds.isNotEmpty) {
            final studentsRes = await supabase
                .from('students')
                .select(
                  'id, student_name, profile_picture, current_reading_level_id',
                )
                .inFilter('id', missingStudentIds);

            for (var student in studentsRes) {
              final uid = student['id']?.toString();
              if (uid != null) {
                studentNames[uid] = student['student_name'] ?? 'Unknown';
                _studentProfilePictures[uid] =
                    student['profile_picture']?.toString() ?? '';
                _studentReadingLevels[uid] = student;
              }
            }
          }
        } else {
          final studentsRes = await supabase
              .from('students')
              .select(
                'id, student_name, profile_picture, current_reading_level_id',
              )
              .inFilter('id', studentIds);

          for (var student in studentsRes) {
            final uid = student['id']?.toString();
            if (uid != null) {
              studentNames[uid] = student['student_name'] ?? 'Unknown';
              _studentProfilePictures[uid] =
                  student['profile_picture']?.toString() ?? '';
              _studentReadingLevels[uid] = student;
            }
          }
        }
      }

      // Fetch tasks
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

      // Fetch materials
      if (materialIds.isNotEmpty) {
        final materialsRes = await supabase
            .from('reading_materials')
            .select('id, title, description')
            .inFilter('id', materialIds);

        for (var material in materialsRes) {
          final mid = material['id']?.toString();
          if (mid != null)
            materialDetails[mid] = Map<String, dynamic>.from(material);
        }
      }

      // Fetch teachers
      if (teacherIds.isNotEmpty) {
        final teachersRes = await supabase
            .from('teachers')
            .select('id, teacher_name')
            .inFilter('id', teacherIds);

        for (var teacher in teachersRes) {
          final tid = teacher['id']?.toString();
          if (tid != null)
            teacherNames[tid] = teacher['teacher_name'] ?? 'Unknown';
        }
      }

      if (mounted) {
        setState(() {
          if (reset) {
            recordings = newRecordings;
          } else {
            recordings.addAll(newRecordings);
          }

          // Initialize expanded states for new recordings (all collapsed by default)
          for (var r in newRecordings) {
            final recordingId = r['id']?.toString();
            if (recordingId != null &&
                !_expandedStates.containsKey(recordingId)) {
              _expandedStates[recordingId] = false;
            }
          }

          for (var r in recordings) {
            final tid = r['graded_by']?.toString();
            r['graded_by_name'] = tid != null ? teacherNames[tid] : null;
          }

          isLoading = false;
          currentPage++;
        });
      }
    } catch (e) {
      debugPrint('Error loading recordings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading recordings: $e'),
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

    setState(() => isLoadingMore = true);

    try {
      await _loadRecordings(reset: false);
    } finally {
      if (mounted) {
        setState(() => isLoadingMore = false);
      }
    }
  }

  void _applyFilters() {
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadRecordings(reset: true);
      if (mounted && showFilters) {
        setState(() => showFilters = false);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      selectedStudentId = null;
      startDate = null;
      endDate = null;
      selectedType = null;
    });
    _applyFilters();
  }

  Widget _buildFiltersPanel() {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    final availableStudents =
        widget.classId != null && _classStudents.isNotEmpty
            ? _classStudents
                .map((cs) {
                  final student = cs['students'] as Map<String, dynamic>?;
                  return {
                    'id': student?['id'] as String?,
                    'name': student?['student_name'] as String?,
                  };
                })
                .where((s) => s['id'] != null && s['name'] != null)
                .toList()
            : studentNames.entries.map((entry) {
              return {'id': entry.key, 'name': entry.value};
            }).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: showFilters ? null : 0,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.classId != null
                                ? 'Classroom Filters'
                                : 'Filter Recordings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[900],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() => showFilters = false);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (widget.classId != null && _className != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Colors.blue[50]!, Colors.blue[100]!],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.class_rounded,
                                color: Colors.blue[700],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Classroom: $_className',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Student Filter
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Student',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
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
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'All Students',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              ...availableStudents.map((student) {
                                return DropdownMenuItem<String>(
                                  value: student['id'] as String?,
                                  child: Text(
                                    student['name'] ?? 'Unknown',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() => selectedStudentId = value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date Range
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Date Range',
                          style: TextStyle(
                            fontSize: 16,
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
                                if (date != null) {
                                  setState(() => startDate = date);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 20,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 12),
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
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: endDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() => endDate = date);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 20,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 12),
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
                      const SizedBox(height: 20),

                      // Type Filter
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Recording Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
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
                              setState(() => selectedType = value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _clearFilters,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                              child: const Text(
                                'Clear Filters',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _applyFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              child: const Text(
                                'Apply Filters',
                                style: TextStyle(fontWeight: FontWeight.w600),
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

    int activeFilterCount = 0;
    if (selectedStudentId != null) activeFilterCount++;
    if (startDate != null) activeFilterCount++;
    if (endDate != null) activeFilterCount++;
    if (selectedType != null) activeFilterCount++;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.08),
            primaryColor.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Iconsax.microphone, color: primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.classId != null
                      ? 'Classroom Recordings'
                      : 'Pending Review',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.classId != null && _className != null) ...[
                  Text(
                    _className!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  '${recordings.length} recording${recordings.length == 1 ? '' : 's'} pending',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                if (activeFilterCount > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_alt_rounded,
                          size: 16,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$activeFilterCount filter${activeFilterCount > 1 ? 's' : ''} active',
                          style: TextStyle(
                            fontSize: 12,
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _clearFilters,
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => showFilters = !showFilters);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search & Filter',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ),
                    AnimatedRotation(
                      turns: showFilters ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: () => _loadRecordings(reset: true),
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
        appBar:
            widget.classId != null
                ? AppBar(
                  automaticallyImplyLeading:
                      false, // This disables the back button
                  backgroundColor: Colors.white,
                  elevation: 0,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Classroom Recordings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                      ),
                      if (_className != null)
                        Text(
                          _className!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  // actions: [
                  //   Padding(
                  //     padding: const EdgeInsets.only(right: 16),
                  //     child: CircleAvatar(
                  //       backgroundColor: primaryColor.withOpacity(0.1),
                  //       child: IconButton(
                  //         icon: Icon(Icons.close_rounded, color: primaryColor),
                  //         onPressed: widget.onWillPop,
                  //       ),
                  //     ),
                  //   ),
                  // ],
                )
                : null,
        body: SafeArea(
          child: Column(
            children: [
              _buildFilterChip(),
              Expanded(
                child:
                    isLoading && recordings.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: primaryColor,
                                strokeWidth: 2.5,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                widget.classId != null
                                    ? 'Loading Classroom Recordings...'
                                    : 'Loading Recordings...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
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
                                  await _loadRecordings(reset: true);
                                },
                                color: primaryColor,
                                backgroundColor: Colors.white,
                                child:
                                    recordings.isEmpty
                                        ? _buildEmptyState()
                                        : ListView.builder(
                                          controller: _scrollController,
                                          padding: const EdgeInsets.only(
                                            bottom: 80,
                                          ),
                                          itemCount:
                                              recordings.length +
                                              (hasMore ? 1 : 0),
                                          itemBuilder: (context, index) {
                                            if (index >= recordings.length) {
                                              return _buildLoadingMoreIndicator();
                                            }
                                            return Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                16,
                                                0,
                                                16,
                                                index == recordings.length - 1
                                                    ? 24
                                                    : 16,
                                              ),
                                              child: _buildRecordingCard(
                                                recordings[index],
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
                : hasMore
                ? Container()
                : const SizedBox(),
      ),
    );
  }

  Widget _buildRecordingCard(Map<String, dynamic> recording, int index) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final studentId = recording['student_id']?.toString() ?? '';
    final taskId = recording['task_id']?.toString();
    final studentName = studentNames[studentId] ?? 'Unknown Student';

    String title = 'Unknown Task';
    String typeLabel = 'Task';
    Color typeColor = Colors.blue;
    Map<String, dynamic>? taskOrMaterial;

    if (taskId != null && taskId.isNotEmpty) {
      final task = taskDetails[taskId];
      title = task?['title']?.toString() ?? 'Unknown Task';
      taskOrMaterial = task;
      typeLabel = 'Task';
      typeColor = Colors.blue;
    } else {
      final materialId = recording['material_id']?.toString();
      if (materialId != null) {
        final material = materialDetails[materialId];
        title = material?['title']?.toString() ?? 'Unknown Reading Material';
        taskOrMaterial = material;
        typeLabel = 'Reading';
        typeColor = Colors.purple;
      }
    }

    final recordingId = recording['id']?.toString() ?? '';
    final isExpanded = _expandedStates[recordingId] ?? false;

    // Check if this recording is currently playing
    final isCurrentlyPlaying = _currentlyPlayingRecordingId == recordingId;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsed Header (Always visible)
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedStates[recordingId] = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[100],
                    backgroundImage:
                        _studentProfilePictures[studentId] != null &&
                                _studentProfilePictures[studentId]!.isNotEmpty
                            ? NetworkImage(_studentProfilePictures[studentId]!)
                            : null,
                    child:
                        _studentProfilePictures[studentId] == null ||
                                _studentProfilePictures[studentId]!.isEmpty
                            ? Text(
                              studentName.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            )
                            : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, y').format(
                                DateTime.parse(
                                  recording['recorded_at'] ?? '',
                                ).toLocal(),
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('h:mm a').format(
                                DateTime.parse(
                                  recording['recorded_at'] ?? '',
                                ).toLocal(),
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Container(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 12,
                  //     vertical: 6,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color: typeColor.withOpacity(0.1),
                  //     borderRadius: BorderRadius.circular(12),
                  //   ),
                  //   child: Row(
                  //     mainAxisSize: MainAxisSize.min,
                  //     children: [
                  //       // Icon(
                  //       //   typeLabel == 'Task'
                  //       //       ? Icons.assignment_rounded
                  //       //       : Icons.book_rounded,
                  //       //   size: 14,
                  //       //   color: typeColor,
                  //       // ),
                  //       // const SizedBox(width: 4),
                  //       // Text(
                  //       //   typeLabel,
                  //       //   style: TextStyle(
                  //       //     fontSize: 12,
                  //       //     fontWeight: FontWeight.w600,
                  //       //     color: typeColor,
                  //       //   ),
                  //       // ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(width: 12),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content (Only shows when expanded)
          if (isExpanded) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (taskOrMaterial?['description'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      taskOrMaterial!['description'] ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildAudioPlayer(recording),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey[100]),
            _buildGradingSection(recording),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(Map<String, dynamic> recording) {
    final recordingId = recording['id']?.toString() ?? '';
    final audioUrl = recording['file_url']?.toString();
    final isCurrentlyPlaying = _currentlyPlayingRecordingId == recordingId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audio title and info
          Row(
            children: [
              Icon(
                Icons.audio_file_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Recording',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      audioUrl != null && audioUrl.isNotEmpty
                          ? 'Tap controls below to play'
                          : 'No audio available',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            audioUrl != null && audioUrl.isNotEmpty
                                ? Colors.grey[500]
                                : Colors.red[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrentlyPlaying && _isAudioPlaying)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up, size: 12, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Playing',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar - ALWAYS VISIBLE
          Column(
            children: [
              // Time labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition ?? Duration.zero),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _currentDuration != null
                          ? _formatDuration(_currentDuration!)
                          : '--:--',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Progress slider
              SizedBox(
                height: 24,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    value: _currentPosition?.inSeconds.toDouble() ?? 0.0,
                    min: 0.0,
                    max: _currentDuration?.inSeconds.toDouble() ?? 100.0,
                    onChanged:
                        _currentDuration != null && isCurrentlyPlaying
                            ? (value) async {
                              if (_currentDuration != null) {
                                final newPosition = Duration(
                                  seconds: value.toInt(),
                                );
                                await _audioPlayer.seek(newPosition);
                              }
                            }
                            : null,
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Audio controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Restart button
              IconButton(
                onPressed: () async {
                  if (_isAudioLoading || audioUrl == null || audioUrl.isEmpty) {
                    return;
                  }
                  try {
                    if (isCurrentlyPlaying) {
                      await _audioPlayer.seek(Duration.zero);
                    }
                  } catch (e) {
                    debugPrint('❌ Error restarting audio: $e');
                  }
                },
                icon: Icon(
                  Icons.replay_rounded,
                  color:
                      audioUrl != null &&
                              audioUrl.isNotEmpty &&
                              isCurrentlyPlaying
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[400],
                  size: 28,
                ),
                tooltip: 'Restart',
              ),

              const SizedBox(width: 24),

              // Play/Pause button
              GestureDetector(
                onTap: () async {
                  debugPrint(
                    '🎵 Play button tapped for recording: $recordingId',
                  );
                  debugPrint('🎵 Current audio URL: $audioUrl');

                  if (_isAudioLoading || audioUrl == null || audioUrl.isEmpty) {
                    debugPrint('❌ Cannot play audio - URL not available');
                    return;
                  }

                  try {
                    if (isCurrentlyPlaying) {
                      // Pause current playback
                      await _audioPlayer.pause();
                    } else {
                      // If playing a different recording, stop it first
                      if (_currentlyPlayingRecordingId != null &&
                          _currentlyPlayingRecordingId != recordingId) {
                        await _audioPlayer.stop();
                      }

                      // Set new recording as currently playing
                      _currentlyPlayingRecordingId = recordingId;

                      // Load and play the audio
                      await _audioPlayer.setUrl(audioUrl);
                      await _audioPlayer.play();
                    }
                  } catch (e) {
                    debugPrint('❌ Error playing audio: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error playing audio: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child:
                        _isAudioLoading && isCurrentlyPlaying
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Icon(
                              isCurrentlyPlaying && _isAudioPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Stop button
              IconButton(
                onPressed: () async {
                  if (_isAudioLoading || !isCurrentlyPlaying) return;

                  try {
                    await _audioPlayer.stop();
                    _currentlyPlayingRecordingId = null;
                  } catch (e) {
                    debugPrint('❌ Error stopping audio: $e');
                  }
                },
                icon: Icon(
                  Icons.stop_rounded,
                  color:
                      audioUrl != null &&
                              audioUrl.isNotEmpty &&
                              isCurrentlyPlaying
                          ? Colors.red[500]
                          : Colors.grey[400],
                  size: 28,
                ),
                tooltip: 'Stop',
              ),
            ],
          ),

          // Loading indicator
          if (_isAudioLoading && isCurrentlyPlaying) ...[
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper function to format duration
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Widget _buildGradingSection(Map<String, dynamic> recording) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final studentId = recording['student_id']?.toString() ?? '';

    // Get current reading level ID (this is a UUID string)
    final currentReadingLevelId =
        _studentReadingLevels[studentId]?['current_reading_level_id']
            ?.toString();

    // Initialize grading state
    int? currentScore =
        recording['score'] != null ? (recording['score'] as num).toInt() : null;
    String? currentFeedback = recording['teacher_comments']?.toString();
    bool isRetakeRequested = recording['is_retake_requested'] == true;
    String? newReadingLevelId;

    // Show retake checkbox based on score (hide if 4 or 5 stars)
    bool showRetakeCheckbox = currentScore == null || currentScore < 4;

    return StatefulBuilder(
      builder: (context, setStateLocal) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grade Section
              Text(
                'Grade Recording (5-star system)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 12),

              // Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNumber = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setStateLocal(() {
                        currentScore = starNumber;
                        // Update retake checkbox visibility based on score
                        showRetakeCheckbox = starNumber < 4;
                        // Clear retake request if score is 4 or 5
                        if (starNumber >= 4) {
                          isRetakeRequested = false;
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        starNumber <= (currentScore ?? 0)
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 40,
                        color:
                            starNumber <= (currentScore ?? 0)
                                ? Colors.amber
                                : Colors.grey[300],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  currentScore != null
                      ? '$currentScore out of 5 stars'
                      : 'Tap stars to rate',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        currentScore != null
                            ? Colors.grey[800]
                            : Colors.grey[500],
                    fontWeight:
                        currentScore != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Teacher Feedback
              Text(
                'Teacher Feedback',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextFormField(
                  initialValue: currentFeedback,
                  onChanged: (value) {
                    setStateLocal(() {
                      currentFeedback = value;
                    });
                  },
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter feedback for the student...',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ),
              const SizedBox(height: 20),

              // Retake Request Option - Show only for scores below 4
              if (showRetakeCheckbox) ...[
                Row(
                  children: [
                    Checkbox(
                      value: isRetakeRequested,
                      onChanged: (value) {
                        setStateLocal(() {
                          isRetakeRequested = value ?? false;
                          // Clear new reading level selection when retake is requested
                          if (isRetakeRequested) {
                            newReadingLevelId = null;
                          }
                        });
                      },
                      activeColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Request student to retake this recording',
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Text(
                    'This will mark the recording as needing improvement and notify the student.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Reading Level Update - Only show if retake is NOT requested
              if (!isRetakeRequested) ...[
                Text(
                  'Update Reading Level (Optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<Map<String, dynamic>>(
                  future: _fetchCurrentAndNextReadingLevel(
                    currentReadingLevelId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Loading reading levels...',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      debugPrint(
                        'Error loading reading levels: ${snapshot.error}',
                      );
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[400]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Failed to load reading levels. Tap to retry.',
                                style: TextStyle(color: Colors.red[600]),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.refresh,
                                color: Colors.red[400],
                                size: 20,
                              ),
                              onPressed: () {
                                // Refresh reading levels
                                setStateLocal(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    final data = snapshot.data ?? {};
                    final currentLevel =
                        data['current'] as Map<String, dynamic>?;
                    final nextLevel = data['next'] as Map<String, dynamic>?;

                    // Display current reading level
                    String currentLevelDisplay = 'No reading level assigned';
                    if (currentLevel != null) {
                      final levelNumber = currentLevel['level_number'];
                      final title = currentLevel['title']?.toString();
                      if (title != null && title.isNotEmpty) {
                        currentLevelDisplay =
                            'Current: $title (Level $levelNumber)';
                      } else if (levelNumber != null) {
                        currentLevelDisplay = 'Current: Level $levelNumber';
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current level display
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Text(
                            currentLevelDisplay,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Dropdown for new reading level - only 2 choices
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: newReadingLevelId ?? currentReadingLevelId,
                              hint: Text(
                                'Select reading level option',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              isExpanded: true,
                              icon: Icon(
                                Icons.expand_more,
                                color: Colors.grey[600],
                              ),
                              items: [
                                // Option 1: Keep current level
                                DropdownMenuItem<String?>(
                                  value: currentReadingLevelId,
                                  child: Text(
                                    'Keep current reading level',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                // Option 2: Next level (if available)
                                if (nextLevel != null)
                                  DropdownMenuItem<String?>(
                                    value: nextLevel['id']?.toString(),
                                    child: Text(
                                      _formatNextLevelText(nextLevel),
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                              onChanged: (value) {
                                setStateLocal(() => newReadingLevelId = value);
                              },
                            ),
                          ),
                        ),

                        // Help text
                        if (nextLevel != null) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'Select the next level to promote the student, or keep current level.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ] else if (currentLevel != null) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'Student is at the highest reading level.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _saveGrading(
                          recording,
                          currentScore,
                          currentFeedback,
                          newReadingLevelId,
                          isRetakeRequested,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: primaryColor),
                      ),
                      child: Text(
                        isRetakeRequested ? 'Request Retake' : 'Save Grade',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper function to format next level text
  String _formatNextLevelText(Map<String, dynamic> nextLevel) {
    final levelNumber = nextLevel['level_number'];
    final title = nextLevel['title']?.toString();

    if (title != null && title.isNotEmpty) {
      return 'Promote to: $title (Level $levelNumber)';
    } else if (levelNumber != null) {
      return 'Promote to: Level $levelNumber';
    } else {
      return 'Next Reading Level';
    }
  }

  // Fetch current and next reading level
  Future<Map<String, dynamic>> _fetchCurrentAndNextReadingLevel(
    String? currentLevelId,
  ) async {
    try {
      // First, fetch all reading levels ordered by level_number
      final response = await supabase
          .from('reading_levels')
          .select('id, level_number, title, description')
          .order('level_number');

      final allLevels = List<Map<String, dynamic>>.from(response);

      // Find current level
      Map<String, dynamic>? currentLevel;
      Map<String, dynamic>? nextLevel;

      if (currentLevelId != null && currentLevelId.isNotEmpty) {
        currentLevel = allLevels.firstWhere(
          (level) => level['id']?.toString() == currentLevelId,
          orElse: () => {},
        );

        // Find next level (higher level_number)
        if (currentLevel.isNotEmpty) {
          final currentLevelNumber = currentLevel['level_number'] as int?;
          if (currentLevelNumber != null) {
            // Find the next level with higher level_number
            final nextLevels =
                allLevels.where((level) {
                  final levelNumber = level['level_number'] as int?;
                  return levelNumber != null &&
                      levelNumber > currentLevelNumber;
                }).toList();

            if (nextLevels.isNotEmpty) {
              // Get the smallest level_number that's greater than current
              nextLevels.sort(
                (a, b) => (a['level_number'] as int).compareTo(
                  b['level_number'] as int,
                ),
              );
              nextLevel = nextLevels.first;
            }
          }
        }
      } else {
        // If student has no current level, the "next" level is the first/lowest level
        if (allLevels.isNotEmpty) {
          // Get the lowest level_number
          allLevels.sort(
            (a, b) =>
                (a['level_number'] as int).compareTo(b['level_number'] as int),
          );
          nextLevel = allLevels.first;
        }
      }

      return {'current': currentLevel, 'next': nextLevel};
    } catch (e) {
      debugPrint('Error fetching reading levels: $e');
      return {};
    }
  }

  Future<void> _saveGrading(
    Map<String, dynamic> recording,
    int? score,
    String? feedback,
    String? newReadingLevelId, // Changed from int? to String?
    bool isRetakeRequested,
  ) async {
    final studentId = recording['student_id']?.toString() ?? '';
    final recordingId = recording['id']?.toString() ?? '';

    // Validate required fields
    if (score == null && !isRetakeRequested) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please provide a star rating or select retake request',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 2.5,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Saving grade...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    try {
      final now = DateTime.now().toUtc().toIso8601String();

      // Update recording grading
      await supabase
          .from('student_recordings')
          .update({
            'score': score,
            'teacher_comments': feedback,
            'is_retake_requested': isRetakeRequested,
            'needs_grading': false,
            'graded_at': now,
            'graded_by': supabase.auth.currentUser?.id,
          })
          .eq('id', recordingId);

      // Update student's reading level if changed and retake is NOT requested
      if (!isRetakeRequested &&
          newReadingLevelId != null &&
          newReadingLevelId !=
              _studentReadingLevels[studentId]?['current_reading_level_id']
                  ?.toString()) {
        await supabase
            .from('students')
            .update({
              'current_reading_level_id': newReadingLevelId,
              'reading_level_updated_at': now,
            })
            .eq('id', studentId);
      }

      // Remove recording from list
      setState(() {
        recordings.removeWhere((r) => r['id'] == recordingId);
        _expandedStates.remove(recordingId);
      });

      // Stop audio if this recording was playing
      if (_currentlyPlayingRecordingId == recordingId) {
        await _audioPlayer.stop();
        _currentlyPlayingRecordingId = null;
      }

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRetakeRequested
                  ? 'Retake requested for student'
                  : 'Grade saved successfully',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving grade: $e');

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving grade: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

Widget _buildEmptyState() {
  final theme = Theme.of(context);
  final primaryColor = theme.colorScheme.primary;
  final isMobile = MediaQuery.of(context).size.width < 600;
  
  // Check if we're in classroom mode but have no students
  final bool isClassroomNoStudents = widget.classId != null && _classStudents.isEmpty;

  return SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.1),
                  Colors.lightGreen.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              isClassroomNoStudents ? Icons.group_off : Icons.check_circle_outline_rounded,
              size: 64,
              color: isClassroomNoStudents ? Colors.orange[400] : Colors.green[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isClassroomNoStudents 
                ? 'No Students in Classroom'
                : widget.classId != null
                    ? 'All Classroom Recordings Graded!'
                    : 'All Caught Up!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isClassroomNoStudents ? Colors.orange[700] : Colors.green[700],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 32 : 80),
            child: Text(
              isClassroomNoStudents
                  ? 'This classroom has no students enrolled. Add students to see their recordings.'
                  : widget.classId != null
                      ? 'No pending recordings from this classroom need grading.'
                      : 'No pending recordings need grading. Great work!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadRecordings,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Refresh List'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
          if (isClassroomNoStudents) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // Optionally navigate to add students
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Navigate to student management for class ${_className ?? widget.classId}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.person_add, size: 20),
              label: const Text('Add Students to Class'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
}
