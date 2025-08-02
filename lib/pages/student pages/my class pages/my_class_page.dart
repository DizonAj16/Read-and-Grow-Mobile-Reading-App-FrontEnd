import 'package:deped_reading_app_laravel/api/api_service.dart';
import 'package:deped_reading_app_laravel/models/classroom.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math'; // at the top
import 'class_details_page.dart';

class MyClassPage extends StatefulWidget {
  const MyClassPage({Key? key}) : super(key: key);

  @override
  State<MyClassPage> createState() => _MyClassPageState();
}

class _MyClassPageState extends State<MyClassPage> {
  late Future<List<Classroom>> _futureClasses;
  final TextEditingController _classCodeController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingInitial = true;
  bool _minimumLoadingTimePassed = false;
  String _currentFunFact = "";

  final List<String> _funFacts = [
    "Did you know? A group of flamingos is called a 'flamboyance'! 🦩",
    "Octopuses have three hearts! ❤️❤️❤️",
    "Bananas are berries, but strawberries aren't! 🍌🍓",
    "Elephants can’t jump, but they’re great swimmers! 🐘",
    "A snail can sleep for three years! 🐌💤",
    "The dot over the 'i' is called a tittle! 🔤",
    "Sloths can hold their breath longer than dolphins! 🦥",
    "Butterflies taste with their feet! 🦋👣",
    "Honey never spoils — archaeologists found 3,000-year-old honey in pyramids! 🍯",
    "Sharks existed before trees did! 🌲🦈",
    "Cows have best friends and get stressed when separated! 🐄❤️🐄",
    "Kangaroos can’t walk backward! 🦘",
    "An ostrich’s eye is bigger than its brain! 👁️🐦",
    "Some turtles can breathe through their butts! 🐢😄",
    "Giraffes only need 5–30 minutes of sleep a day! 🦒💤",
    "Frogs can freeze without dying! ❄️🐸",
    "Water can boil and freeze at the same time — it’s called the triple point! 💧🔥❄️",
    "Wombat poop is cube-shaped! 🧱🧻",
    "Starfish have no brains and no blood! ⭐🐚",
    "A bolt of lightning is five times hotter than the sun! ⚡☀️",
    "Bees can recognize human faces! 🐝🙂",
    "Some fish can cough! 🐟😮",
    "Sea otters hold hands while sleeping so they don’t drift apart! 🦦🤝",
    "Jellyfish have been around longer than dinosaurs! 🦖🌊",
    "Penguins propose with pebbles! 🐧💍",
    "Some cats are allergic to humans! 😺🤧",
    "Tigers have striped skin, not just striped fur! 🐯",
    "You can’t hum while holding your nose! 🤐🎵",
    "The moon has moonquakes — like earthquakes, but on the moon! 🌕🌍",
    "There are more trees on Earth than stars in the Milky Way! 🌳🌌",
    "Bats always turn left when exiting a cave! 🦇↩️",
    "Caterpillars melt into goo inside their cocoons before becoming butterflies! 🐛🦋",
    "Goldfish can recognize and remember human faces! 🐠👀",
    "Some ants explode to protect their colony! 🐜💥",
    "A day on Venus is longer than a year on Venus! 🌍🪐",
    "Dogs can learn over 1000 words! 🐶🗣️",
    "Tomatoes were once thought to be poisonous! 🍅☠️",
    "Polar bears have black skin under their white fur! 🐻‍❄️🖤",
  ];

  @override
  void initState() {
    super.initState();
    _futureClasses = _loadClasses();

    // Pick a random fun fact when screen opens
    _currentFunFact = _funFacts[Random().nextInt(_funFacts.length)];

    // Wait 2 seconds minimum before allowing loading to complete
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _minimumLoadingTimePassed = true;
        });
      }
    });
  }

  Future<List<Classroom>> _loadClasses() async {
    List<Classroom> loadedClasses = [];

    try {
      // Fetch classes from the API
      loadedClasses = await ApiService.getStudentClasses();

      if (loadedClasses.isEmpty) {
        debugPrint(
          "✅ No classes from API. Student likely unassigned. Clearing SharedPreferences.",
        );
        await ApiService.clearStudentClassesFromPrefs(); // ensure data is cleared
      } else {
        debugPrint("✅ ${loadedClasses.length} classes fetched from API:");
        _logClassroomList(loadedClasses);
        await ApiService.storeStudentClassesToPrefs(
          loadedClasses,
        ); // update latest classes
      }

      return loadedClasses;
    } catch (e) {
      debugPrint("❌ API error: $e");

      // Optional: Always clear prefs if API fails (to avoid using outdated data)
      debugPrint("🧹 Clearing SharedPreferences due to API failure.");
      await ApiService.clearStudentClassesFromPrefs();

      // Return empty list to reflect unassignment
      return [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
        });
      }
    }
  }

  void _logClassroomList(List<Classroom> classes) {
    for (var c in classes) {
      debugPrint("• ${c.id}: ${c.className} (${c.gradeLevel}-${c.section})");
    }
  }

  void refreshFunFact() {
    final random = Random();
    setState(() {
      _currentFunFact = _funFacts[random.nextInt(_funFacts.length)];
    });
  }

  Future<void> _refresh() async {
    debugPrint("🔄 Refresh triggered by user.");

    setState(() {
      _minimumLoadingTimePassed = false;
      _isLoadingInitial = true;
      _futureClasses = _loadClasses();
      refreshFunFact(); // 🔄 Also update the fun fact
    });

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _minimumLoadingTimePassed = true;
      });
    }
  }

  // ✅ Show Join Class Dialog
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
                      hintText: "ABC123",
                      hintStyle: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[500],
                        letterSpacing: 2,
                      ),
                      prefixIcon: const Icon(
                        Icons.school,
                        color: Colors.purple,
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

  // ✅ Join Class with Lottie Loading
  Future<void> _joinClass(String classCode) async {
    setState(() => _isLoading = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildLoadingDialog(),
    );

    try {
      final res = await ApiService.joinClass(classCode);
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

  // ✅ Loading Dialog (Lottie)
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

  // ✅ Handle API error messages (make them simple)
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

  // ✅ Show Stylized SnackBar
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                "My Classes",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Classroom>>(
                  future: _futureClasses,
                  builder: (context, snapshot) {
                    // Show loading animation if either:
                    // 1. We're still loading initially, OR
                    // 2. The minimum loading time hasn't passed yet
                    if (_isLoadingInitial || !_minimumLoadingTimePassed) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.blue.shade100,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade50.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.lightBlue.shade100,
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Lottie.asset(
                                    'assets/animation/loading_class.json',
                                    width: 160,
                                    height: 160,
                                    repeat: true,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "Getting your classroom ready...",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade700,
                                    fontFamily: 'ComicNeue',
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50.withOpacity(
                                      0.6,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.orange.shade100,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.lightbulb,
                                            color: Colors.orange,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Fun Fact!",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.orange.shade800,
                                              fontFamily: 'ComicNeue',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _currentFunFact,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.deepPurple.shade600,
                                          fontFamily: 'ComicNeue',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
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
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyClasses();
                    }

                    final classes = snapshot.data!;
                    return ListView.builder(
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        final classItem = classes[index];
                        return ClassCard(
                          classId: classItem.id ?? 0,
                          className: classItem.className,
                          sectionName:
                              "${classItem.gradeLevel} - ${classItem.section}",
                          teacherName: classItem.teacherName ?? "N/A",
                          backgroundImage: 'assets/background/classroombg.jpg',
                          realBackgroundImage:
                              classItem.backgroundImage ??
                              'assets/background/classroombg.jpg',
                          teacherEmail: classItem.teacherEmail ?? "No email",
                          teacherPosition:
                              classItem.teacherPosition ?? "Teacher",
                          teacherAvatar: classItem.teacherAvatar,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Widget for empty state
  Widget _buildEmptyClasses() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade100, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animation/empty.json',
              width: 200,
              height: 200,
              repeat: true,
            ),
            const SizedBox(height: 12),
            Text(
              "No Classrooms Yet! 🎓",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask your teacher for a class code\nthen tap the “Join Class” button below! 👇',
              style: TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _showJoinClassDialog();
              },
              icon: const Icon(Icons.school, size: 24),
              label: const Text(
                "Join Class Now",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, color: Colors.blue),
              label: const Text(
                "Try Again",
                style: TextStyle(color: Colors.blue, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ ClassCard remains unchanged
class ClassCard extends StatelessWidget {
  final int classId; // ✅ Add this
  final String className;
  final String sectionName;
  final String teacherName;
  final String backgroundImage; // static image (classroombg.jpg)
  final String realBackgroundImage; // ✅ dynamic image for details page
  final String teacherEmail;
  final String teacherPosition;
  final String? teacherAvatar;

  const ClassCard({
    Key? key,
    required this.classId, // ✅ Add this
    required this.className,
    required this.sectionName,
    required this.teacherName,
    required this.backgroundImage,
    required this.realBackgroundImage,
    required this.teacherEmail,
    required this.teacherPosition,
    this.teacherAvatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 150,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Hero(
              tag: 'class-bg-$className',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  backgroundImage,
                  fit: BoxFit.cover,
                  height: 150,
                  width: double.infinity,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7), // stronger dark overlay
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 600),
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                ClassDetailsPage(
                                  className: className,
                                  backgroundImage: realBackgroundImage,
                                  teacherName: teacherName,
                                  teacherEmail: teacherEmail,
                                  teacherPosition: teacherPosition,
                                  teacherAvatar: teacherAvatar,
                                  classId:
                                      classId, // ✅ Use the passed parameter
                                  // ✅ pass classId from model
                                ),

                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  }
                },
                itemBuilder:
                    (BuildContext context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text('View Class'),
                          ],
                        ),
                      ),
                    ],
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'class-title-$className',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        className,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    sectionName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 1.5,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      if (teacherAvatar != null && teacherAvatar!.isNotEmpty)
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(teacherAvatar!),
                          backgroundColor: Colors.grey[200],
                        )
                      else
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Text(
                            teacherName.isNotEmpty
                                ? teacherName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      const SizedBox(width: 8),
                      Text(
                        teacherName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 1.5,
                              color: Colors.black26,
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
    );
  }
}
