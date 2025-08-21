import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:deped_reading_app_laravel/api/material_service.dart';
import 'package:deped_reading_app_laravel/constants.dart';
import 'package:deped_reading_app_laravel/models/material_model.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20classes/pdf%20helper/pdf_viewer.dart';

class MaterialsPage extends StatefulWidget {
  final int classId;
  const MaterialsPage({super.key, required this.classId});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  late List<MaterialModel> _materials;
  late bool _isLoading;
  late bool _hasError;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeState();
    _loadMaterials();
  }

  void _initializeState() {
    _materials = [];
    _isLoading = true;
    _hasError = false;
  }

  Future<void> _loadMaterials() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final fetchedMaterials = await MaterialService.fetchStudentMaterials();
      if (!mounted) return;

      setState(() {
        _materials = fetchedMaterials
            .where((material) => material.classRoomId == widget.classId)
            .toList();
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
              onRefresh: _loadMaterials,
              color: Colors.blue,
              backgroundColor: Colors.white,
              child: _ContentBuilder(
                isLoading: _isLoading,
                hasError: _hasError,
                materials: _materials,
                onRetry: _loadMaterials,
                onMaterialTap: _handleMaterialTap,
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

  void _handleMaterialTap(MaterialModel material) {
    if (!mounted) return;
    
    // Handle different material types
    if (material.materialType == 'pdf') {
      _navigateToPdfViewer(material.materialFileUrl);
    } else if (material.materialType == 'image') {
      _showImageDialog(material.materialFileUrl);
    } else if (material.materialType == 'video') {
      _showVideoDialog(material.materialFileUrl);
    } else if (material.materialType == 'audio') {
      _showAudioDialog(material.materialFileUrl);
    } else {
      // For documents and archives, show a download/open dialog
      _showDownloadDialog(material);
    }
  }

  void _navigateToPdfViewer(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfViewerPage(pdfUrl: url)),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(imageUrl),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVideoDialog(String videoUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Material'),
        content: const Text('This video will open in an external player.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement video player or external app opening
              Navigator.pop(context);
            },
            child: const Text('Open Video'),
          ),
        ],
      ),
    );
  }

  void _showAudioDialog(String audioUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audio Material'),
        content: const Text('This audio file will open in an external player.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement audio player or external app opening
              Navigator.pop(context);
            },
            child: const Text('Play Audio'),
          ),
        ],
      ),
    );
  }

  void _showDownloadDialog(MaterialModel material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download ${material.materialType.toUpperCase()}'),
        content: Text('Would you like to download "${material.materialTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement file download
              Navigator.pop(context);
            },
            child: const Text('Download'),
          ),
        ],
      ),
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
  final List<MaterialModel> materials;
  final VoidCallback onRetry;
  final Function(MaterialModel) onMaterialTap;

  const _ContentBuilder({
    required this.isLoading,
    required this.hasError,
    required this.materials,
    required this.onRetry,
    required this.onMaterialTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _LoadingView();
    if (hasError) return _ErrorView(onRetry: onRetry);
    if (materials.isEmpty) return const _EmptyView();
    return _MaterialListView(materials: materials, onMaterialTap: onMaterialTap);
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

class _MaterialListView extends StatelessWidget {
  final List<MaterialModel> materials;
  final Function(MaterialModel) onMaterialTap;

  const _MaterialListView({required this.materials, required this.onMaterialTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        return _MaterialCard(
          material: materials[index],
          onTap: () => onMaterialTap(materials[index]),
        );
      },
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final MaterialModel material;
  final VoidCallback onTap;

  const _MaterialCard({required this.material, required this.onTap});

  IconData _getMaterialIcon() {
    switch (material.materialType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      case 'document':
        return Icons.article;
      case 'archive':
        return Icons.folder;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getMaterialColor(BuildContext context) {
    switch (material.materialType) {
      case 'pdf':
        return Colors.red;
      case 'image':
        return Colors.green;
      case 'video':
        return Colors.purple;
      case 'audio':
        return Colors.orange;
      case 'document':
        return Colors.blue;
      case 'archive':
        return Colors.brown;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialColor = _getMaterialColor(context);

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
                        color: materialColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getMaterialIcon(),
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
                            material.materialTitle,
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
                            "By: ${material.teacherName}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey[400],
                            ),
                          ),
                          if (material.fileSize != null)
                            Text(
                              material.fileSize!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey[300],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: materialColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: materialColor.withOpacity(0.3),
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