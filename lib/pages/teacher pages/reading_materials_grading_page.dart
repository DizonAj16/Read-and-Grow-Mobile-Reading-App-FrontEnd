  import 'dart:async';
  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:audio_session/audio_session.dart';
  import 'package:just_audio/just_audio.dart';
  import 'package:iconsax/iconsax.dart';

  class ReadingMaterialGradingPage extends StatefulWidget {
    final String materialId;
    final String materialTitle;
    final VoidCallback? onWillPop;

    const ReadingMaterialGradingPage({
      super.key,
      required this.materialId,
      required this.materialTitle,
      this.onWillPop,
    });

    @override
    State<ReadingMaterialGradingPage> createState() =>
        _ReadingMaterialGradingPageState();
  }

  class _ReadingMaterialGradingPageState extends State<ReadingMaterialGradingPage>
      with SingleTickerProviderStateMixin {
    final supabase = Supabase.instance.client;
    late TabController _tabController;

    // Data for both tabs
    List<Map<String, dynamic>> _pendingRecordings = [];
    List<Map<String, dynamic>> _gradedRecordings = [];
    Map<String, String> _studentNames = {};
    Map<String, Map<String, dynamic>> _studentData = {};
    Map<String, String> _studentProfilePictures = {};
    Map<String, Map<String, dynamic>> _studentReadingLevels = {};

    // Loading states
    bool _isLoadingPending = true;
    bool _isLoadingGraded = true;
    bool _hasMorePending = true;
    bool _hasMoreGraded = true;
    int _pendingPage = 0;
    int _gradedPage = 0;
    bool _isRefreshingPending = false;
    bool _isRefreshingGraded = false;
    // Add these loading states near your other loading variables
    bool _isFullRefreshLoading = false;
    bool _isPendingPullRefresh = false;
    bool _isGradedPullRefresh = false;
    final int _pageSize = 50;

    // Filter states for pending tab
    String? _selectedStudentId;
    DateTime? _startDate;
    DateTime? _endDate;
    bool _showFilters = false;
    Timer? _filterDebounceTimer;

    // Filter states for graded tab
    String? _gradedSelectedStudentId;
    DateTime? _gradedStartDate;
    DateTime? _gradedEndDate;
    String? _selectedScoreRange;
    bool _showGradedFilters = false;

    // Audio player management - SINGLE PLAYER INSTANCE
    final AudioPlayer _audioPlayer = AudioPlayer();
    String? _currentlyPlayingRecordingId;
    bool _isAudioPlaying = false;
    bool _isAudioLoading = false;
    Duration? _currentDuration;
    Duration? _currentPosition;

    // Expansion states for pending recordings
    final Map<String, bool> _expandedStates = {};

    // Reading levels cache

    final ScrollController _pendingScrollController = ScrollController();
    final ScrollController _gradedScrollController = ScrollController();

    @override
    void initState() {
      super.initState();
      _tabController = TabController(length: 2, vsync: this);
      _tabController.addListener(_handleTabChange);
      _loadInitialData();
      _pendingScrollController.addListener(_handlePendingScroll);
      _gradedScrollController.addListener(_handleGradedScroll);
      _setupAudioPlayer();
    }

    @override
    void dispose() {
      _tabController.dispose();
      _pendingScrollController.dispose();
      _gradedScrollController.dispose();
      _filterDebounceTimer?.cancel();
      _audioPlayer.dispose();
      super.dispose();
    }

    void _handleTabChange() {
      if (_tabController.indexIsChanging) {
        setState(() {
        });
      }
    }

    void _handlePendingScroll() {
      if (_pendingScrollController.offset >=
              _pendingScrollController.position.maxScrollExtent &&
          !_pendingScrollController.position.outOfRange &&
          _hasMorePending &&
          !_isLoadingPending) {
        _loadMorePendingRecordings();
      }
    }

    void _handleGradedScroll() {
      if (_gradedScrollController.offset >=
              _gradedScrollController.position.maxScrollExtent &&
          !_gradedScrollController.position.outOfRange &&
          _hasMoreGraded &&
          !_isLoadingGraded) {
        _loadMoreGradedRecordings();
      }
    }

    Future<void> _setupAudioPlayer() async {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());

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
      setState(() => _isFullRefreshLoading = true);

      try {
        await Future.wait([
          _loadPendingRecordings(reset: true),
          _loadGradedRecordings(reset: true),
        ]);
      } finally {
        if (mounted) {
          setState(() => _isFullRefreshLoading = false);
        }
      }
    }

    Future<void> _handlePendingRefresh() async {
      setState(() {
        _isPendingPullRefresh = true;
        _isRefreshingPending = true;
      });

      try {
        await _loadPendingRecordings(reset: true);
      } finally {
        if (mounted) {
          setState(() {
            _isPendingPullRefresh = false;
            _isRefreshingPending = false;
          });
        }
      }
    }

    Future<void> _handleGradedRefresh() async {
      setState(() {
        _isGradedPullRefresh = true;
        _isRefreshingGraded = true;
      });

      try {
        await _loadGradedRecordings(reset: true);
      } finally {
        if (mounted) {
          setState(() {
            _isGradedPullRefresh = false;
            _isRefreshingGraded = false;
          });
        }
      }
    }

    // Add this method for full refresh (when clicking refresh buttons)
    Future<void> _handleFullRefresh() async {
      setState(() => _isFullRefreshLoading = true);

      try {
        await Future.wait([
          _loadPendingRecordings(reset: true),
          _loadGradedRecordings(reset: true),
        ]);
      } finally {
        if (mounted) {
          setState(() => _isFullRefreshLoading = false);
        }
      }
    }

    Future<void> _loadPendingRecordings({bool reset = false}) async {
      if (reset) {
        setState(() {
          _pendingPage = 0;
          _pendingRecordings.clear();
          _hasMorePending = true;
          _expandedStates.clear();
          _isLoadingPending = true; // Add this line
        });
      } else {
        // setState(() => _isLoadingPending = true);
      }

      try {
        if (reset) {
          _studentNames.clear();
          _studentData.clear();
          _studentProfilePictures.clear();
          _studentReadingLevels.clear();
        }

        var query = supabase
            .from('student_recordings')
            .select('*')
            .eq('needs_grading', true)
            .eq('material_id', widget.materialId);

        // Apply filters for pending tab
        if (_selectedStudentId != null) {
          query = query.eq('student_id', _selectedStudentId!);
        }

        if (_startDate != null) {
          query = query.gte('recorded_at', _startDate!.toIso8601String());
        }

        if (_endDate != null) {
          final endDatePlusOne = _endDate!.add(const Duration(days: 1));
          query = query.lt('recorded_at', endDatePlusOne.toIso8601String());
        }

        final from = _pendingPage * _pageSize;
        final to = (_pendingPage + 1) * _pageSize - 1;

        final recordingsRes = await query
            .order('recorded_at', ascending: false)
            .range(from, to);

        final newRecordings = List<Map<String, dynamic>>.from(recordingsRes);

        if (newRecordings.length < _pageSize) {
          _hasMorePending = false;
        }

        // Collect student IDs
        final studentIds =
            newRecordings
                .map((r) => r['student_id'])
                .whereType<String>()
                .toSet()
                .toList();

        // Fetch student data
        if (studentIds.isNotEmpty) {
          final studentsRes = await supabase
              .from('students')
              .select(
                'id, student_name, profile_picture, current_reading_level_id',
              )
              .inFilter('id', studentIds);

          for (var student in studentsRes) {
            final uid = student['id']?.toString();
            if (uid != null) {
              _studentNames[uid] = student['student_name'] ?? 'Unknown';
              _studentProfilePictures[uid] =
                  student['profile_picture']?.toString() ?? '';
              _studentReadingLevels[uid] = student;
            }
          }
        }

        setState(() {
          if (reset) {
            _pendingRecordings = newRecordings;
          } else {
            _pendingRecordings.addAll(newRecordings);
          }

          // Initialize expanded states
          for (var r in newRecordings) {
            final recordingId = r['id']?.toString();
            if (recordingId != null &&
                !_expandedStates.containsKey(recordingId)) {
              _expandedStates[recordingId] = false;
            }
          }

          _isLoadingPending = false;
          _pendingPage++;
        });
      } catch (e) {
        debugPrint('Error loading pending recordings: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading pending recordings: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoadingPending = false);
        }
      }
    }

    Future<void> _loadMorePendingRecordings() async {
      if (_isLoadingPending || !_hasMorePending) return;
      await _loadPendingRecordings(reset: false);
    }

    Future<void> _loadGradedRecordings({bool reset = false}) async {
      if (reset) {
        setState(() {
          _gradedPage = 0;
          _gradedRecordings.clear();
          _hasMoreGraded = true;
          _isLoadingGraded = true; // Add this line
        });
      } else {
        // setState(() => _isLoadingGraded = true);
      }

      try {
        var query = supabase
            .from('student_recordings')
            .select('*')
            .eq('needs_grading', false)
            .eq('material_id', widget.materialId)
            .not('score', 'is', null);

        // Apply filters for graded tab
        if (_gradedSelectedStudentId != null) {
          query = query.eq('student_id', _gradedSelectedStudentId!);
        }

        if (_gradedStartDate != null) {
          query = query.gte('graded_at', _gradedStartDate!.toIso8601String());
        }

        if (_gradedEndDate != null) {
          final endDatePlusOne = _gradedEndDate!.add(const Duration(days: 1));
          query = query.lt('graded_at', endDatePlusOne.toIso8601String());
        }

        if (_selectedScoreRange == 'high') {
          query = query.gte('score', 4.0);
        } else if (_selectedScoreRange == 'medium') {
          query = query.gte('score', 3.0).lt('score', 4.0);
        } else if (_selectedScoreRange == 'low') {
          query = query.lt('score', 3.0);
        }

        final from = _gradedPage * _pageSize;
        final to = (_gradedPage + 1) * _pageSize - 1;

        final recordingsRes = await query
            .order('graded_at', ascending: false)
            .range(from, to);

        final newRecordings = List<Map<String, dynamic>>.from(recordingsRes);

        if (newRecordings.length < _pageSize) {
          _hasMoreGraded = false;
        }

        // Update student data if needed
        final studentIds =
            newRecordings
                .map((r) => r['student_id'])
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
              if (!_studentNames.containsKey(uid)) {
                _studentNames[uid] = student['student_name'] ?? 'Unknown';
              }
              if (!_studentProfilePictures.containsKey(uid)) {
                _studentProfilePictures[uid] =
                    student['profile_picture']?.toString() ?? '';
              }
            }
          }
        }

        setState(() {
          if (reset) {
            _gradedRecordings = newRecordings;
          } else {
            _gradedRecordings.addAll(newRecordings);
          }
          _isLoadingGraded = false;
          _gradedPage++;
        });
      } catch (e) {
        debugPrint('Error loading graded recordings: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading graded recordings: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoadingGraded = false);
        }
      }
    }

    Future<void> _loadMoreGradedRecordings() async {
      if (_isLoadingGraded || !_hasMoreGraded) return;
      await _loadGradedRecordings(reset: false);
    }

    void _applyPendingFilters() {
      _filterDebounceTimer?.cancel();
      _filterDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        _loadPendingRecordings(reset: true);
        if (mounted && _showFilters) {
          setState(() => _showFilters = false);
        }
      });
    }

    void _clearPendingFilters() {
      setState(() {
        _selectedStudentId = null;
        _startDate = null;
        _endDate = null;
      });
      _applyPendingFilters();
    }

    void _applyGradedFilters() {
      _filterDebounceTimer?.cancel();
      _filterDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        _loadGradedRecordings(reset: true);
        if (mounted && _showGradedFilters) {
          setState(() => _showGradedFilters = false);
        }
      });
    }

    void _clearGradedFilters() {
      setState(() {
        _gradedSelectedStudentId = null;
        _gradedStartDate = null;
        _gradedEndDate = null;
        _selectedScoreRange = null;
      });
      _applyGradedFilters();
    }

    Widget _buildPendingFiltersPanel() {
      final theme = Theme.of(context);
      final isMobile = MediaQuery.of(context).size.width < 600;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _showFilters ? null : 0,
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
            _showFilters
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
                              'Filter Pending Recordings',
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
                                setState(() => _showFilters = false);
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
                              value: _selectedStudentId,
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
                                ..._studentNames.entries.map((entry) {
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
                                setState(() => _selectedStudentId = value);
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
                                    initialDate: _startDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() => _startDate = date);
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
                                          _startDate != null
                                              ? DateFormat(
                                                'MMM d, y',
                                              ).format(_startDate!)
                                              : 'Start Date',
                                          style: TextStyle(
                                            color:
                                                _startDate != null
                                                    ? Colors.grey[900]
                                                    : Colors.grey[500],
                                            fontWeight:
                                                _startDate != null
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
                                    initialDate: _endDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() => _endDate = date);
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
                                          _endDate != null
                                              ? DateFormat(
                                                'MMM d, y',
                                              ).format(_endDate!)
                                              : 'End Date',
                                          style: TextStyle(
                                            color:
                                                _endDate != null
                                                    ? Colors.grey[900]
                                                    : Colors.grey[500],
                                            fontWeight:
                                                _endDate != null
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
                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _clearPendingFilters,
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
                                onPressed: _applyPendingFilters,
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

    Widget _buildGradedFiltersPanel() {
      final theme = Theme.of(context);
      final isMobile = MediaQuery.of(context).size.width < 600;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _showGradedFilters ? null : 0,
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
            _showGradedFilters
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
                              'Filter Graded Recordings',
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
                                setState(() => _showGradedFilters = false);
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
                              value: _gradedSelectedStudentId,
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
                                ..._studentNames.entries.map((entry) {
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
                                setState(() => _gradedSelectedStudentId = value);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Date Range
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Grading Date Range',
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
                                    initialDate:
                                        _gradedStartDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() => _gradedStartDate = date);
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
                                          _gradedStartDate != null
                                              ? DateFormat(
                                                'MMM d, y',
                                              ).format(_gradedStartDate!)
                                              : 'Start Date',
                                          style: TextStyle(
                                            color:
                                                _gradedStartDate != null
                                                    ? Colors.grey[900]
                                                    : Colors.grey[500],
                                            fontWeight:
                                                _gradedStartDate != null
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
                                    initialDate: _gradedEndDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() => _gradedEndDate = date);
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
                                          _gradedEndDate != null
                                              ? DateFormat(
                                                'MMM d, y',
                                              ).format(_gradedEndDate!)
                                              : 'End Date',
                                          style: TextStyle(
                                            color:
                                                _gradedEndDate != null
                                                    ? Colors.grey[900]
                                                    : Colors.grey[500],
                                            fontWeight:
                                                _gradedEndDate != null
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

                        // Score Range Filter
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Score Range',
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
                              value: _selectedScoreRange,
                              hint: const Text('All Scores'),
                              isExpanded: true,
                              icon: Icon(
                                Icons.expand_more,
                                color: Colors.grey[600],
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
                                setState(() => _selectedScoreRange = value);
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
                                onPressed: _clearGradedFilters,
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
                                onPressed: _applyGradedFilters,
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

    Widget _buildPendingTab() {
      final theme = Theme.of(context);
      final primaryColor = theme.colorScheme.primary;
      final isMobile = MediaQuery.of(context).size.width < 600;

      return Column(
        children: [
          // Filter chip for pending
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _showFilters = !_showFilters);
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
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _showFilters ? 0.5 : 0,
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
                // In _buildPendingTab(), find the refresh button section and update it:
                Container(
                  width: 48,
                  height: 48,
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap:
                          _isRefreshingPending || _isFullRefreshLoading
                              ? null
                              : () => _handleFullRefresh(),
                      child: Center(
                        child:
                            _isRefreshingPending || _isFullRefreshLoading
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildPendingFiltersPanel(),

          // Stats header for pending
          Container(
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
                        'Pending Review',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_pendingRecordings.length} recording${_pendingRecordings.length == 1 ? '' : 's'} pending',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pending recordings list
          Expanded(
            child:
                _isLoadingPending && _pendingRecordings.isEmpty
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
                            'Loading Pending Recordings...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                    : _pendingRecordings.isEmpty &&
                        !_isPendingPullRefresh &&
                        !_isFullRefreshLoading
                    ? _buildEmptyState('pending')
                    : RefreshIndicator(
                      onRefresh: _handlePendingRefresh,
                      color: primaryColor,
                      backgroundColor: Colors.white,
                      child: ListView.builder(
                        controller: _pendingScrollController,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount:
                            _pendingRecordings.length + (_hasMorePending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _pendingRecordings.length) {
                            return _buildLoadingMoreIndicator(
                              _isLoadingPending,
                              _hasMorePending,
                            );
                          }
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              index == _pendingRecordings.length - 1 ? 24 : 16,
                            ),
                            child: _buildPendingRecordingCard(
                              _pendingRecordings[index],
                              index,
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      );
    }

    Widget _buildGradedTab() {
      final theme = Theme.of(context);
      final primaryColor = theme.colorScheme.primary;
      final isMobile = MediaQuery.of(context).size.width < 600;

      // Calculate stats for graded
      double averageScore = 0;
      if (_gradedRecordings.isNotEmpty) {
        final totalScore = _gradedRecordings
            .map((r) => r['score'] is num ? r['score'].toDouble() : 0.0)
            .reduce((a, b) => a + b);
        averageScore = totalScore / _gradedRecordings.length;
      }

      int highCount = 0;
      int mediumCount = 0;
      int lowCount = 0;
      for (var recording in _gradedRecordings) {
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

      return Column(
        children: [
          // Filter chip for graded
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _showGradedFilters = !_showGradedFilters);
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
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _showGradedFilters ? 0.5 : 0,
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
                // In _buildGradedTab(), find the refresh button and update it:
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
                    icon:
                        _isRefreshingGraded || _isFullRefreshLoading
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed:
                        _isRefreshingGraded || _isFullRefreshLoading
                            ? null
                            : () => _handleFullRefresh(),
                    tooltip: 'Refresh',
                  ),
                ),
              ],
            ),
          ),

          _buildGradedFiltersPanel(),

          // Stats header for graded
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: 8,
            ),
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
                            '${_gradedRecordings.length} recording${_gradedRecordings.length == 1 ? '' : 's'} reviewed',
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
                                  _getScoreColor(
                                    averageScore / 5.0,
                                    primaryColor,
                                  ),
                                  _getScoreColor(
                                    averageScore / 5.0,
                                    primaryColor,
                                  ).withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                isMobile ? 8 : 10,
                              ),
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
                      _buildDistributionItem(
                        'Low',
                        lowCount,
                        primaryColor,
                        isMobile,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Graded recordings list
          Expanded(
            child:
                _isLoadingGraded && _gradedRecordings.isEmpty
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
                    : _gradedRecordings.isEmpty &&
                        !_isGradedPullRefresh &&
                        !_isFullRefreshLoading
                    ? _buildEmptyState('graded')
                    : RefreshIndicator(
                      onRefresh: _handleGradedRefresh,
                      color: primaryColor,
                      backgroundColor: Colors.white,
                      child: ListView.builder(
                        controller: _gradedScrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(bottom: isMobile ? 60 : 80),
                        itemCount:
                            _gradedRecordings.length + (_hasMoreGraded ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _gradedRecordings.length) {
                            return _buildLoadingMoreIndicator(
                              _isLoadingGraded,
                              _hasMoreGraded,
                            );
                          }
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              isMobile ? 12 : 16,
                              0,
                              isMobile ? 12 : 16,
                              index == _gradedRecordings.length - 1
                                  ? (isMobile ? 20 : 24)
                                  : (isMobile ? 12 : 16),
                            ),
                            child: _buildGradedRecordingCard(
                              _gradedRecordings[index],
                              index,
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      );
    }

    Widget _buildPendingRecordingCard(Map<String, dynamic> recording, int index) {
      final theme = Theme.of(context);
      final primaryColor = theme.colorScheme.primary;
      final studentId = recording['student_id']?.toString() ?? '';
      final studentName = _studentNames[studentId] ?? 'Unknown Student';
      final recordingId = recording['id']?.toString() ?? '';
      final isExpanded = _expandedStates[recordingId] ?? false;

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
            // Collapsed Header
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

            // Expanded Content
            if (isExpanded) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

    Widget _buildGradedRecordingCard(Map<String, dynamic> recording, int index) {
      final theme = Theme.of(context);
      final primaryColor = theme.colorScheme.primary;
      final isMobile = MediaQuery.of(context).size.width < 600;
      final studentId = recording['student_id']?.toString() ?? '';
      final studentName = _studentNames[studentId] ?? 'Unknown Student';
      final recordingId = recording['id']?.toString() ?? '';
      final recordingUrl = recording['file_url']?.toString() ?? '';
      final isPlaying =
          _currentlyPlayingRecordingId == recordingId && _isAudioPlaying;

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
                SizedBox(height: isMobile ? 4 : 6),
                Row(
                  children: [
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
                          // Score Rating Stars
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
                                          _formatDuration(
                                            _currentPosition ?? Duration.zero,
                                          ),
                                          style: TextStyle(
                                            fontSize: isMobile ? 11 : 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          _currentDuration != null
                                              ? _formatDuration(_currentDuration!)
                                              : '--:--',
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
                                          _currentlyPlayingRecordingId ==
                                                  recordingId
                                              ? (_currentPosition?.inSeconds
                                                          .toDouble() ??
                                                      0.0)
                                                  .clamp(
                                                    0.0,
                                                    _currentDuration?.inSeconds
                                                            .toDouble() ??
                                                        100.0,
                                                  )
                                              : 0.0,
                                      min: 0.0,
                                      max:
                                          _currentDuration?.inSeconds
                                              .toDouble() ??
                                          100.0,
                                      onChanged:
                                          recordingUrl.isNotEmpty &&
                                                  _currentlyPlayingRecordingId ==
                                                      recordingId
                                              ? (value) async {
                                                if (_currentDuration != null) {
                                                  final newPosition = Duration(
                                                    seconds: value.toInt(),
                                                  );
                                                  await _audioPlayer.seek(
                                                    newPosition,
                                                  );
                                                }
                                              }
                                              : null,
                                      activeColor:
                                          recordingUrl.isNotEmpty &&
                                                  _currentlyPlayingRecordingId ==
                                                      recordingId
                                              ? Colors.blue
                                              : Colors.grey[400],
                                      inactiveColor: Colors.grey[300],
                                      thumbColor:
                                          recordingUrl.isNotEmpty &&
                                                  _currentlyPlayingRecordingId ==
                                                      recordingId
                                              ? Colors.blue
                                              : Colors.grey[400],
                                    ),
                                    SizedBox(height: isMobile ? 12 : 16),
                                  ],
                                ),

                                // Player Controls
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Restart button
                                    IconButton(
                                      onPressed: () async {
                                        if (_isAudioLoading ||
                                            recordingUrl.isEmpty) {
                                          return;
                                        }
                                        try {
                                          if (_currentlyPlayingRecordingId ==
                                              recordingId) {
                                            await _audioPlayer.seek(
                                              Duration.zero,
                                            );
                                          }
                                        } catch (e) {
                                          debugPrint(
                                            '❌ Error restarting audio: $e',
                                          );
                                        }
                                      },
                                      icon: Icon(
                                        Icons.replay_rounded,
                                        color:
                                            recordingUrl.isNotEmpty &&
                                                    _currentlyPlayingRecordingId ==
                                                        recordingId
                                                ? theme.colorScheme.primary
                                                : Colors.grey[400],
                                        size: 28,
                                      ),
                                      tooltip: 'Restart',
                                    ),
                                    const SizedBox(width: 24),

                                    // Play/Pause button
                                    GestureDetector(
                                      onTap: () async {
                                        if (_isAudioLoading ||
                                            recordingUrl.isEmpty) {
                                          return;
                                        }

                                        try {
                                          if (_currentlyPlayingRecordingId ==
                                                  recordingId &&
                                              _isAudioPlaying) {
                                            // Pause current playback
                                            await _audioPlayer.pause();
                                          } else {
                                            // If playing a different recording, stop it first
                                            if (_currentlyPlayingRecordingId !=
                                                    null &&
                                                _currentlyPlayingRecordingId !=
                                                    recordingId) {
                                              await _audioPlayer.stop();
                                            }

                                            // Set new recording as currently playing
                                            _currentlyPlayingRecordingId =
                                                recordingId;

                                            // Load and play the audio
                                            await _audioPlayer.setUrl(
                                              recordingUrl,
                                            );
                                            await _audioPlayer.play();
                                          }
                                        } catch (e) {
                                          debugPrint('❌ Error playing audio: $e');
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Error playing audio: ${e.toString()}',
                                                ),
                                                backgroundColor: Colors.red,
                                                behavior:
                                                    SnackBarBehavior.floating,
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
                                              theme.colorScheme.primary,
                                              theme.colorScheme.primary
                                                  .withOpacity(0.8),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.colorScheme.primary
                                                  .withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child:
                                              _isAudioLoading &&
                                                      _currentlyPlayingRecordingId ==
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
                                                  : Icon(
                                                    _currentlyPlayingRecordingId ==
                                                                recordingId &&
                                                            _isAudioPlaying
                                                        ? Icons.pause_rounded
                                                        : Icons
                                                            .play_arrow_rounded,
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
                                        if (_isAudioLoading ||
                                            _currentlyPlayingRecordingId !=
                                                recordingId)
                                          return;

                                        try {
                                          await _audioPlayer.stop();
                                          _currentlyPlayingRecordingId = null;
                                        } catch (e) {
                                          debugPrint(
                                            '❌ Error stopping audio: $e',
                                          );
                                        }
                                      },
                                      icon: Icon(
                                        Icons.stop_rounded,
                                        color:
                                            recordingUrl.isNotEmpty &&
                                                    _currentlyPlayingRecordingId ==
                                                        recordingId
                                                ? Colors.red[500]
                                                : Colors.grey[400],
                                        size: 28,
                                      ),
                                      tooltip: 'Stop',
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

            // Progress bar
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
                    if (_isAudioLoading || audioUrl == null || audioUrl.isEmpty) {
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
          ],
        ),
      );
    }

    Widget _buildGradingSection(Map<String, dynamic> recording) {
      final theme = Theme.of(context);
      final primaryColor = theme.colorScheme.primary;
      final studentId = recording['student_id']?.toString() ?? '';

      final currentReadingLevelId =
          _studentReadingLevels[studentId]?['current_reading_level_id']
              ?.toString();
      int? currentScore =
          recording['score'] != null ? (recording['score'] as num).toInt() : null;
      String? currentFeedback = recording['teacher_comments']?.toString();
      bool isRetakeRequested = recording['is_retake_requested'] == true;
      String? newReadingLevelId;
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
                          showRetakeCheckbox = starNumber < 4;
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

                // Retake Request Option
                if (showRetakeCheckbox) ...[
                  Row(
                    children: [
                      Checkbox(
                        value: isRetakeRequested,
                        onChanged: (value) {
                          setStateLocal(() {
                            isRetakeRequested = value ?? false;
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

                // Reading Level Update
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

                          // Dropdown for new reading level
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

    Future<Map<String, dynamic>> _fetchCurrentAndNextReadingLevel(
      String? currentLevelId,
    ) async {
      try {
        final response = await supabase
            .from('reading_levels')
            .select('id, level_number, title, description')
            .order('level_number');

        final allLevels = List<Map<String, dynamic>>.from(response);
        Map<String, dynamic>? currentLevel;
        Map<String, dynamic>? nextLevel;

        if (currentLevelId != null && currentLevelId.isNotEmpty) {
          currentLevel = allLevels.firstWhere(
            (level) => level['id']?.toString() == currentLevelId,
            orElse: () => {},
          );

          if (currentLevel.isNotEmpty) {
            final currentLevelNumber = currentLevel['level_number'] as int?;
            if (currentLevelNumber != null) {
              final nextLevels =
                  allLevels.where((level) {
                    final levelNumber = level['level_number'] as int?;
                    return levelNumber != null &&
                        levelNumber > currentLevelNumber;
                  }).toList();

              if (nextLevels.isNotEmpty) {
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
          if (allLevels.isNotEmpty) {
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

    Future<void> _saveGrading(
      Map<String, dynamic> recording,
      int? score,
      String? feedback,
      String? newReadingLevelId,
      bool isRetakeRequested,
    ) async {
      final studentId = recording['student_id']?.toString() ?? '';
      final recordingId = recording['id']?.toString() ?? '';

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

      // Store a reference to the dialog's context
      BuildContext? dialogContext;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          dialogContext = context;
          return Dialog(
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
          );
        },
      );

      try {
        final now = DateTime.now().toUtc().toIso8601String();

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

        // Stop audio if playing
        if (_currentlyPlayingRecordingId == recordingId) {
          await _audioPlayer.stop();
          _currentlyPlayingRecordingId = null;
        }

        // Close the dialog first
        if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        }

        // Show success message
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

        // Update state immediately
        setState(() {
          // Create graded recording copy
          final gradedRecording = Map<String, dynamic>.from(recording);
          gradedRecording['score'] = score;
          gradedRecording['teacher_comments'] = feedback;
          gradedRecording['is_retake_requested'] = isRetakeRequested;
          gradedRecording['needs_grading'] = false;
          gradedRecording['graded_at'] = now;
          gradedRecording['graded_by'] = supabase.auth.currentUser?.id;

          // Remove from pending
          _pendingRecordings.removeWhere((r) => r['id'] == recordingId);
          _expandedStates.remove(recordingId);

          // Add to graded at the beginning
          _gradedRecordings.insert(0, gradedRecording);
        });

        // IMPORTANT: Switch to graded tab - but ensure we're still in the same page
        // Add a small delay to let the dialog close completely
        await Future.delayed(const Duration(milliseconds: 50));

        if (mounted) {
          // Make sure we're on the graded tab
          if (_tabController.index != 1) {
            _tabController.animateTo(1);
          }
        }

        // Refresh data in background
        await Future.wait([
          _loadPendingRecordings(reset: true),
          _loadGradedRecordings(reset: true),
        ]);
      } catch (e) {
        debugPrint('Error saving grade: $e');

        // Close dialog if still showing
        if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        }

        if (mounted) {
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

    Widget _buildStarRating(double score, {double size = 20}) {
      final fullStars = score.floor();
      final hasHalfStar = (score - fullStars) >= 0.5;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          if (index < fullStars) {
            return Icon(Icons.star, size: size, color: Colors.amber);
          } else if (index == fullStars && hasHalfStar) {
            return Icon(Icons.star_half, size: size, color: Colors.amber);
          } else {
            return Icon(Icons.star_border, size: size, color: Colors.grey[400]);
          }
        }),
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

    Widget _buildLoadingMoreIndicator(bool isLoading, bool hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child:
              isLoading
                  ? CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  )
                  : hasMore
                  ? Container()
                  : const SizedBox(),
        ),
      );
    }

    Widget _buildEmptyState(String tabType) {
      final theme = Theme.of(context);
      final primaryColor = theme.colorScheme.primary;
      final isMobile = MediaQuery.of(context).size.width < 600;

      // Check if we're currently refreshing this specific tab
      bool isRefreshing =
          (tabType == 'pending' && _isPendingPullRefresh) ||
          (tabType == 'graded' && _isGradedPullRefresh) ||
          _isFullRefreshLoading;

      if (isRefreshing) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor, strokeWidth: 2.5),
              const SizedBox(height: 24),
              Text(
                tabType == 'pending'
                    ? 'Refreshing Pending Recordings...'
                    : 'Refreshing Graded Recordings...',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

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
                  tabType == 'pending'
                      ? Icons.check_circle_outline_rounded
                      : Icons.assignment_outlined,
                  size: 64,
                  color:
                      tabType == 'pending' ? Colors.green[400] : Colors.blue[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                tabType == 'pending' ? 'All Caught Up!' : 'No Graded Recordings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      tabType == 'pending' ? Colors.green[700] : Colors.blue[700],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 32 : 80),
                child: Text(
                  tabType == 'pending'
                      ? 'No pending recordings need grading. Great work!'
                      : 'Graded recordings will appear here once you\'ve reviewed student submissions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  if (tabType == 'pending') {
                    _handlePendingRefresh();
                  } else {
                    _handleGradedRefresh();
                  }
                },
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
            ],
          ),
        ),
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

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
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
            // In ReadingMaterialGradingPage build method:
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: Colors.grey[700],
                size: isMobile ? 24 : 28,
              ),
              onPressed: () {
                // Simply pop the current route
                Navigator.pop(context);

                // If there's an onWillPop callback, call it after a short delay
                if (widget.onWillPop != null) {
                  Future.delayed(Duration(milliseconds: 100), widget.onWillPop!);
                }
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Submissions',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
                Text(
                  widget.materialTitle,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: theme.colorScheme.primary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pending, size: isMobile ? 18 : 20),
                          const SizedBox(width: 8),
                          Text('Pending'),
                          if (_pendingRecordings.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _pendingRecordings.length.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Tab(
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.grading, size: isMobile ? 18 : 20),
                          const SizedBox(width: 8),
                          Text('Graded'),
                          if (_gradedRecordings.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _gradedRecordings.length.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.bold,
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
          ),
          // In the build method, replace the TabBarView section with:
          body:
              TabBarView(
                controller: _tabController,
                children: [_buildPendingTab(), _buildGradedTab()],
              ),

        ),
      );
    }

    Widget _buildLoadingOverlay() {
      if (!_isFullRefreshLoading &&
          !_isPendingPullRefresh &&
          !_isGradedPullRefresh) {
        return const SizedBox.shrink();
      }

      return Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  _getLoadingMessage(),
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
    }

    String _getLoadingMessage() {
      if (_isFullRefreshLoading) return 'Refreshing all data...';
      if (_isPendingPullRefresh) return 'Refreshing pending recordings...';
      if (_isGradedPullRefresh) return 'Refreshing graded recordings...';
      return 'Loading...';
    }
  }
