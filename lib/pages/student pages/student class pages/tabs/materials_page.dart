import 'package:deped_reading_app_laravel/api/pdf_service.dart';
import 'package:deped_reading_app_laravel/constants.dart';
import 'package:flutter/material.dart';
import 'package:deped_reading_app_laravel/models/pdf_material.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20classes/pdf%20helper/pdf_viewer.dart';
import 'package:lottie/lottie.dart';

class MaterialsPage extends StatefulWidget {
  final int classId;

  const MaterialsPage({super.key, required this.classId});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage>
    with SingleTickerProviderStateMixin {
  List<PdfMaterial> pdfMaterials = [];
  bool isLoading = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadPdfMaterials();
  }

  Future<void> _loadPdfMaterials() async {
    try {
      setState(() => isLoading = true);
      final fetchedPdfs = await PdfService.fetchStudentPdfMaterials();
      final filteredPdfs =
          fetchedPdfs.where((pdf) => pdf.classId == widget.classId).toList();

      setState(() {
        pdfMaterials = filteredPdfs;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackbar("Oops! Couldn't load books. Try again!");
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
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
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _loadPdfMaterials,
              color: Colors.blue,
              backgroundColor: Colors.white,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: 140,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kPrimaryColor, // main primary color
              Color(0xFFB71C1C), // darker shade for depth
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: const Text(
          "Class Materials",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return _buildCenteredLottie('assets/animation/loading_rainbow.json', 90);
    }
    if (pdfMaterials.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: pdfMaterials.length,
      itemBuilder: (context, index) {
        final pdf = pdfMaterials[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 80)),
          curve: Curves.easeOutBack,
          builder:
              (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
          child: _buildBookCard(pdf),
        );
      },
    );
  }

  Widget _buildBookCard(PdfMaterial pdf) {
    var primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PdfViewerPage(pdfUrl: pdf.url)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdf.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "By: ${pdf.teacherName ?? 'Teacher'}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey[400],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfViewerPage(pdfUrl: pdf.url),
                      ),
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

  Widget _buildCenteredLottie(String path, double size) {
    return Center(child: Lottie.asset(path, width: size, height: size));
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animation/empty_box.json',
                width: 220,
                height: 220,
              ),
              const SizedBox(height: 20),
              Text(
                "No Materials yet!",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Your teacher will add Materials soon!",
                style: TextStyle(fontSize: 16, color: Colors.blue[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Reusable wave clipper
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 20);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    var secondControlPoint = Offset(
      size.width - (size.width / 4),
      size.height - 60,
    );
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
