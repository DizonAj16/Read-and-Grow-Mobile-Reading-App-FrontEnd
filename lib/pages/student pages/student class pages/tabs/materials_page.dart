import 'package:deped_reading_app_laravel/api/pdf_service.dart';
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

class _MaterialsPageState extends State<MaterialsPage> {
  List<PdfMaterial> pdfMaterials = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfMaterials();
  }

  Future<void> _loadPdfMaterials() async {
    try {
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
      body:
          isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animation/loading_rainbow.json',
                      width: 90,
                      height: 90,
                    ),
                  ],
                ),
              )
              : pdfMaterials.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animation/empty_box.json',
                      width: 250,
                      height: 250,
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
              )
              : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: pdfMaterials.length,
                  itemBuilder: (context, index) {
                    final pdf = pdfMaterials[index];
                    return _buildBookCard(pdf);
                  },
                ),
              ),
    );
  }

  Widget _buildBookCard(PdfMaterial pdf) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
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
              // Book icon with colorful background
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getRandomPastelColor(),
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
              // Playful "Read" button
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

  // Helper function to generate pastel colors for book icons
  Color _getRandomPastelColor() {
    final colors = [
      Colors.pink[300]!,
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.orange[300]!,
      Colors.purple[300]!,
      Colors.teal[300]!,
    ];
    return colors[DateTime.now().millisecondsSinceEpoch % colors.length];
  }
}
