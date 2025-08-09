import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:deped_reading_app_laravel/api/classroom_service.dart';
import 'package:deped_reading_app_laravel/api/fun_fact_service.dart';
import 'package:deped_reading_app_laravel/api/prefs_service.dart';
import 'package:deped_reading_app_laravel/models/classroom.dart';
import 'widgets/class_card.dart';
import 'widgets/empty_classes_widget.dart';
import 'widgets/loading_widget.dart';

class StudentClassPage extends StatefulWidget {
  const StudentClassPage({Key? key}) : super(key: key);

  @override
  State<StudentClassPage> createState() => _StudentClassPageState();
}

class _StudentClassPageState extends State<StudentClassPage> {
  late Future<List<Classroom>> _futureClasses;
  final TextEditingController _classCodeController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingInitial = true;
  bool _isRefreshingFunFact = false;
  bool _minimumLoadingTimePassed = false;
  String _currentFunFact = "";

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  void _initializePage() {
    _futureClasses = _loadClasses();
    _fetchAndSetFunFact(); // Only one fun fact per load
    _setMinimumLoadingTime(const Duration(seconds: 10));
  }

  Future<void> _fetchAndSetFunFact() async {
    try {
      // ❌ Removed instant fact — we now wait for API
      final fresh = await FunFactService.getRandomFact();
      if (mounted) setState(() => _currentFunFact = fresh);
    } catch (e) {
      debugPrint("❌ Fun fact fetch failed: $e");
    }
  }

  void _setMinimumLoadingTime(Duration duration) {
    Future.delayed(duration, () {
      if (mounted) setState(() => _minimumLoadingTimePassed = true);
    });
  }

  Future<List<Classroom>> _loadClasses() async {
    try {
      final loadedClasses = await ClassroomService.getStudentClasses();
      await _handleLoadedClasses(loadedClasses);
      return loadedClasses;
    } catch (e) {
      debugPrint("❌ API error: $e");
      await PrefsService.clearStudentClassesFromPrefs();
      return [];
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _handleLoadedClasses(List<Classroom> loadedClasses) async {
    if (loadedClasses.isEmpty) {
      debugPrint("✅ No classes from API. Clearing SharedPreferences.");
      await PrefsService.clearStudentClassesFromPrefs();
    } else {
      debugPrint("✅ ${loadedClasses.length} classes fetched from API:");
      _logClassroomList(loadedClasses);
      await PrefsService.storeStudentClassesToPrefs(loadedClasses);
    }
  }

  void _logClassroomList(List<Classroom> classes) {
    for (var c in classes) {
      debugPrint("• ${c.id}: ${c.className} (${c.gradeLevel}-${c.section})");
    }
  }

  Future<void> refreshFunFact() async {
    if (_isRefreshingFunFact) return;
    setState(() => _isRefreshingFunFact = true);
    try {
      final fact = await FunFactService.getRandomFact();
      if (mounted) setState(() => _currentFunFact = fact);
    } catch (e) {
      debugPrint("Fun fact error: $e");
    } finally {
      if (mounted) setState(() => _isRefreshingFunFact = false);
    }
  }

  Future<void> _refresh() async {
    debugPrint("🔄 Refresh triggered by user.");
    setState(() {
      _minimumLoadingTimePassed = false;
      _isLoadingInitial = true;
      _futureClasses = _loadClasses();
    });

    _setMinimumLoadingTime(const Duration(seconds: 10)); // 👈 Longer duration

    await Future.wait([_futureClasses, _fetchAndSetFunFact()]);

    if (mounted) {
      setState(() {
        _isLoadingInitial = false;
        // 👇 Do not set _minimumLoadingTimePassed here, let the delay handle it
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCEEEE),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 16),
              _buildClassList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      "My Classes",
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildClassList() {
    return Expanded(
      child: FutureBuilder<List<Classroom>>(
        future: _futureClasses,
        builder: (context, snapshot) {
          if (_isLoadingInitial || !_minimumLoadingTimePassed) {
            return LoadingWidget(
              currentFunFact: _currentFunFact,
              isRefreshingFunFact: _isRefreshingFunFact,
            );
          } else if (snapshot.hasError) {
            return _buildErrorWidget();
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyClassesWidget(
              onJoinClassPressed: _showJoinClassDialog,
              onRefreshPressed: _refresh,
            );
          }
          return _buildClassListView(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Text(
        "Failed to load classes.",
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildClassListView(List<Classroom> classes) {
    return ListView.builder(
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classItem = classes[index];
        return ClassCard(
          classId: classItem.id ?? 0,
          className: classItem.className,
          sectionName: "${classItem.gradeLevel} - ${classItem.section}",
          teacherName: classItem.teacherName ?? "N/A",
          backgroundImage: 'assets/background/classroombg.jpg',
          realBackgroundImage:
              classItem.backgroundImage ?? 'assets/background/classroombg.jpg',
          teacherEmail: classItem.teacherEmail ?? "No email",
          teacherPosition: classItem.teacherPosition ?? "Teacher",
          teacherAvatar: classItem.teacherAvatar,
        );
      },
    );
  }

  // ... [Keep all the dialog and snackbar methods unchanged] ...

  Future<void> _showJoinClassDialog() async {
    final colorScheme = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: SingleChildScrollView(
            // ✅ Makes it scrollable
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🖼️ Friendly cartoon image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/icons/join_class.jpg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    "Join Your Class!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    "Enter the class code your teacher gave you.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _classCodeController,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: "ABCD1234",
                      hintStyle: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[500],
                        letterSpacing: 2,
                      ),
                      prefixIcon: Icon(
                        Icons.school,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      filled: true,
                      fillColor: Colors.deepPurple.shade50,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          _classCodeController.clear();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text("Cancel"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle),
                        onPressed: () async {
                          Navigator.pop(context);
                          if (_classCodeController.text.trim().isNotEmpty) {
                            await _joinClass(_classCodeController.text.trim());
                          }
                        },
                        label: const Text(
                          "Join Class",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleErrorMessage(String apiMessage) {
    String message;

    if (apiMessage.contains("grade does not match")) {
      message = "Your grade does not match this classroom";
    } else if (apiMessage.contains("section does not match")) {
      message = "Your section does not match this classroom";
    } else if (apiMessage.contains("not found")) {
      message = "Classroom doesn’t exist";
    } else if (apiMessage.contains("invalid")) {
      message = "Invalid classroom code";
    } else if (apiMessage.contains("already in")) {
      message = "You are already in this class";
    } else if (apiMessage.contains("already assigned")) {
      message = "You are already assigned to another class";
    } else {
      message = "Something went wrong";
    }

    _showSnackBar(message, success: false);
  }

  Widget _buildLoadingDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 120,
              child: Lottie.asset('assets/animation/searching_file.json'),
            ),
            const SizedBox(height: 12),
            Text(
              "Verifying Class Code...",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinClass(String classCode) async {
    setState(() => _isLoading = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildLoadingDialog(),
    );

    try {
      final res = await ClassroomService.joinClass(classCode);
      await Future.delayed(const Duration(seconds: 3));
      if (context.mounted) Navigator.pop(context);

      if (res.statusCode == 200) {
        _showSnackBar("Successfully joined the class!", success: true);
        _classCodeController.clear();
        await _refresh();
      } else {
        _handleErrorMessage(res.body);
      }
    } catch (_) {
      await Future.delayed(const Duration(seconds: 3));
      if (context.mounted) Navigator.pop(context);
      _showSnackBar("Network error. Try again.", success: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
