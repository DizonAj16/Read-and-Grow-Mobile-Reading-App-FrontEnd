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
  bool _isLoadingInitial = true;
  bool _isRefreshingFunFact = false;
  bool _minimumLoadingTimePassed = false;
  String _currentFunFact = "";

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  @override
  void dispose() {
    _classCodeController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    _futureClasses = _loadClasses();
    await _fetchAndSetFunFact();
    _setMinimumLoadingTime(const Duration(seconds: 10));
  }

  Future<void> _fetchAndSetFunFact() async {
    try {
      final fresh = await FunFactService.getRandomFact();
      if (mounted) setState(() => _currentFunFact = fresh);
    } catch (e) {
      debugPrint("Fun fact fetch failed: $e");
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
      debugPrint("Classroom API error: $e");
      await PrefsService.clearStudentClassesFromPrefs();
      return [];
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _handleLoadedClasses(List<Classroom> loadedClasses) async {
    if (loadedClasses.isEmpty) {
      await PrefsService.clearStudentClassesFromPrefs();
    } else {
      await PrefsService.storeStudentClassesToPrefs(loadedClasses);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _minimumLoadingTimePassed = false;
      _isLoadingInitial = true;
      _futureClasses = _loadClasses();
    });
    _setMinimumLoadingTime(const Duration(seconds: 10));
    await Future.wait([_futureClasses, _fetchAndSetFunFact()]);
    if (mounted) setState(() => _isLoadingInitial = false);
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
            children: [const SizedBox(height: 16), _buildClassList()],
          ),
        ),
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
          }

          if (snapshot.hasError) {
            return _ErrorWidget(errorMessage: 'Failed to load classes');
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyClassesWidget(
              onJoinClassPressed: _showJoinClassDialog,
              onRefreshPressed: _refresh,
            );
          }

          return _ClassListView(classes: snapshot.data!);
        },
      ),
    );
  }

  Future<void> _showJoinClassDialog() async {
    await showDialog(
      context: context,
      builder:
          (_) => JoinClassDialog(
            controller: _classCodeController,
            onJoinPressed: (code) => _joinClass(code),
          ),
    );
  }

  Future<void> _joinClass(String classCode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingDialog(),
    );

    try {
      final res = await ClassroomService.joinClass(classCode);
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;
      Navigator.pop(context);

      if (res.statusCode == 200) {
        _showSuccessSnackBar("Successfully joined the class!");
        _classCodeController.clear();
        await _refresh();
      } else {
        _handleErrorMessage(res.body);
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
      _showErrorSnackBar("Network error. Try again.");
    } finally {}
  }

  void _showSuccessSnackBar(String message) {
    _showSnackBar(message, isSuccess: true);
  }

  void _showErrorSnackBar(String message) {
    _showSnackBar(message, isSuccess: false);
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            isSuccess ? Colors.green.shade600 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
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
    final message = _getErrorMessageFromApi(apiMessage);
    _showErrorSnackBar(message);
  }

  String _getErrorMessageFromApi(String apiMessage) {
    if (apiMessage.contains("grade does not match")) {
      return "Your grade does not match this classroom";
    } else if (apiMessage.contains("section does not match")) {
      return "Your section does not match this classroom";
    } else if (apiMessage.contains("not found")) {
      return "Classroom doesn't exist";
    } else if (apiMessage.contains("invalid")) {
      return "Invalid classroom code";
    } else if (apiMessage.contains("already in")) {
      return "You are already in this class";
    } else if (apiMessage.contains("already assigned")) {
      return "You are already assigned to another class";
    }
    return "Something went wrong";
  }
}

class _ErrorWidget extends StatelessWidget {
  final String errorMessage;

  const _ErrorWidget({required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        errorMessage,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ClassListView extends StatelessWidget {
  final List<Classroom> classes;

  const _ClassListView({required this.classes});

  @override
  Widget build(BuildContext context) {
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
}

class JoinClassDialog extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onJoinPressed;

  const JoinClassDialog({
    required this.controller,
    required this.onJoinPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              _buildCodeTextField(context),
              const SizedBox(height: 28),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeTextField(BuildContext context) {
    return TextField(
      controller: controller,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        filled: true,
        fillColor: Colors.deepPurple.shade50,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCancelButton(context),
        const SizedBox(width: 8),
        _buildJoinButton(context),
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        controller.clear();
        Navigator.pop(context);
      },
      icon: const Icon(Icons.cancel),
      label: const Text("Cancel"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade300,
        foregroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    );
  }

  Widget _buildJoinButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.check_circle),
      onPressed: () {
        Navigator.pop(context);
        if (controller.text.trim().isNotEmpty) {
          onJoinPressed(controller.text.trim());
        }
      },
      label: const Text(
        "Join Class",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
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
}
