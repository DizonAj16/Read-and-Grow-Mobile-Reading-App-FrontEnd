import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:deped_reading_app_laravel/api/pdf_service.dart';
import 'package:deped_reading_app_laravel/constants.dart';
import 'package:deped_reading_app_laravel/models/pdf_material.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20classes/pdf%20helper/pdf_viewer.dart';

class MaterialsPage extends StatefulWidget {
  final int classId;
  const MaterialsPage({super.key, required this.classId});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  late List<PdfMaterial> _pdfMaterials;
  late bool _isLoading;
  late bool _hasError;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeState();
    _loadPdfMaterials();
  }

  void _initializeState() {
    _pdfMaterials = [];
    _isLoading = true;
    _hasError = false;
  }

  Future<void> _loadPdfMaterials() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final fetchedPdfs = await PdfService.fetchStudentPdfMaterials();
      if (!mounted) return;

      setState(() {
        _pdfMaterials =
            fetchedPdfs.where((pdf) => pdf.classId == widget.classId).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      _showErrorSnackbar("Failed to load materials. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body: Column(
        children: [
          const _MaterialsHeader(),
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _loadPdfMaterials,
              color: Colors.blue,
              backgroundColor: Colors.white,
              child: _ContentBuilder(
                isLoading: _isLoading,
                hasError: _hasError,
                pdfMaterials: _pdfMaterials,
                onRetry: _loadPdfMaterials,
                onPdfTap: _navigateToPdfViewer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
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

  void _navigateToPdfViewer(String url) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfViewerPage(pdfUrl: url)),
    );
  }
}

class _MaterialsHeader extends StatelessWidget {
  const _MaterialsHeader();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        height: 140,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryColor, Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Text(
            "Class Materials",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentBuilder extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final List<PdfMaterial> pdfMaterials;
  final VoidCallback onRetry;
  final Function(String) onPdfTap;

  const _ContentBuilder({
    required this.isLoading,
    required this.hasError,
    required this.pdfMaterials,
    required this.onRetry,
    required this.onPdfTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _LoadingView();
    if (hasError) return _ErrorView(onRetry: onRetry);
    if (pdfMaterials.isEmpty) return const _EmptyView();
    return _PdfListView(pdfs: pdfMaterials, onPdfTap: onPdfTap);
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animation/loading_rainbow.json',
            width: 90,
            height: 90,
          ),
          const SizedBox(height: 20),
          const Text(
            "Loading materials...",
            style: TextStyle(fontSize: 16, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animation/error.json', width: 150, height: 150),
          const SizedBox(height: 20),
          const Text(
            "Failed to load materials",
            style: TextStyle(
              fontSize: 18,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: onRetry, child: const Text("Retry")),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
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
                "No Materials Yet!",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Your teacher will add materials soon",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PdfListView extends StatelessWidget {
  final List<PdfMaterial> pdfs;
  final Function(String) onPdfTap;

  const _PdfListView({required this.pdfs, required this.onPdfTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: pdfs.length,
      itemBuilder: (context, index) {
        return _PdfCard(
          pdf: pdfs[index],
          onTap: () => onPdfTap(pdfs[index].url),
        );
      },
    );
  }
}

class _PdfCard extends StatelessWidget {
  final PdfMaterial pdf;
  final VoidCallback onTap;

  const _PdfCard({required this.pdf, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.95, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
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
              onTap: onTap,
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
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                        onPressed: onTap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);

    final firstControlPoint = Offset(size.width / 4, size.height);
    final firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(
      size.width - (size.width / 4),
      size.height - 60,
    );
    final secondEndPoint = Offset(size.width, size.height - 20);
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
