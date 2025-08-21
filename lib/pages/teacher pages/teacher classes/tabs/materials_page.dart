import 'dart:io';
import 'package:deped_reading_app_laravel/api/material_service.dart';
import 'package:deped_reading_app_laravel/models/material_model.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../pdf helper/pdf_viewer.dart'; 
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;

enum ActionType { view, edit, delete, add, archive }

class MaterialsPage extends StatefulWidget {
  final int classId;
 
  const MaterialsPage({super.key, required this.classId});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  List<MaterialModel> _materials = [];
  bool _isLoading = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  bool _isDisposed = false;
  File? _selectedFile;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add minimum delay of 1.5 seconds for shimmer effect
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!_isDisposed) {
        _loadMaterials().then((_) {
          if (!_isDisposed) {}
        });
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    if (!mounted && !_isDisposed) return;

    setState(() => _isLoading = true);

    try {
      final materials = await MaterialService.getClassroomMaterials(
        widget.classId,
      );

      if (!mounted && !_isDisposed) return;

      setState(() {
        _materials = materials;
      });
    } catch (e) {
      print('❌ Error loading materials: $e');
      if (mounted) {
        _showErrorSnackbar("Error loading materials: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showUploadDialog() async {
    // Reset form fields
    _titleController.clear();
    _descriptionController.clear();
    _selectedFile = null;

    await showDialog(
      context: context,
      builder: (context) => _buildUploadDialog(),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadMaterial() async {
    if (_titleController.text.isEmpty) {
      _showErrorSnackbar("Please enter a title for the material");
      return;
    }

    if (_selectedFile == null) {
      _showErrorSnackbar("Please select a file to upload");
      return;
    }

    final fileName = _selectedFile!.path.split('/').last;
    final fileExtension = fileName.split('.').last.toLowerCase();
    final materialType = _determineMaterialType(fileExtension);

    Navigator.pop(context); // Close the dialog

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildUploadingDialog(materialType),
    );

    try {
      final success = await MaterialService.uploadMaterialFile(
        file: _selectedFile!,
        materialTitle: _titleController.text,
        classroomId: widget.classId,
        materialType: materialType,
        description:
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (success) {
        _showSuccessSnackbar("$materialType uploaded successfully!");
        await _loadMaterials();
      } else {
        _showErrorSnackbar("Failed to upload $materialType.");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackbar("Upload error: ${e.toString()}");
      }
    }
  }

  String _determineMaterialType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'pdf';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
        return 'image';
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'mkv':
      case 'webm':
        return 'video';
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'm4a':
      case 'aac':
        return 'audio';
      case 'doc':
      case 'docx':
      case 'ppt':
      case 'pptx':
      case 'xls':
      case 'xlsx':
      case 'txt':
      case 'rtf':
        return 'document';
      case 'zip':
      case 'rar':
      case '7z':
        return 'archive';
      default:
        return 'document';
    }
  }

  Future<void> _confirmDelete(int id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteConfirmationDialog(title),
    );

    if (confirm != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDeletingDialog(),
    );

    try {
      final success = await MaterialService.deleteMaterial(id);

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        _showSuccessSnackbar("Material deleted successfully!");
        await _loadMaterials();
      } else {
        _showErrorSnackbar("Failed to delete material.");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackbar("Delete error: ${e.toString()}");
      }
    }
  }

  // NEW: Function to view material in-app
  Future<void> _viewMaterialInApp(MaterialModel material) async {
    try {
      switch (material.materialType) {
        case 'pdf':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfViewerPage(pdfUrl: material.materialFileUrl),
            ),
          );
          break;
        
        case 'image':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImageViewerPage(imageUrl: material.materialFileUrl),
            ),
          );
          break;
        
        case 'video':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoViewerPage(videoUrl: material.materialFileUrl),
            ),
          );
          break;
        
        case 'audio':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AudioViewerPage(audioUrl: material.materialFileUrl, title: material.materialTitle),
            ),
          );
          break;
        
        case 'document':
        case 'archive':
          // For documents and archives, download and open with external app
          _downloadAndOpenFile(material);
          break;
        
        default:
          _downloadAndOpenFile(material);
      }
    } catch (e) {
      _showErrorSnackbar("Error opening file: ${e.toString()}");
    }
  }

  // NEW: Download and open file with external app
  Future<void> _downloadAndOpenFile(MaterialModel material) async {
    try {
      final response = await http.get(Uri.parse(material.materialFileUrl));
      final bytes = response.bodyBytes;
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${material.materialTitle}');
      await file.writeAsBytes(bytes);
      
      await OpenFile.open(file.path);
    } catch (e) {
      _showErrorSnackbar("Error opening file: ${e.toString()}");
    }
  }

  Widget _buildUploadDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Upload Material",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Material Title *",
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Description (Optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // File Picker
            ElevatedButton(
              onPressed: _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                foregroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.attach_file),
                  const SizedBox(width: 8),
                  Text(
                    _selectedFile != null
                        ? _selectedFile!.path.split('/').last
                        : "Choose File",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedFile != null)
              Text(
                "Selected: ${_selectedFile!.path.split('/').last}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _uploadMaterial,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Upload"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteConfirmationDialog(String title) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Delete Material',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            'Delete "$title"?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'This action cannot be undone',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildUploadingDialog(String materialType) {
    IconData icon;
    Color color;

    switch (materialType) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'image':
        icon = Icons.image;
        color = Colors.green;
        break;
      case 'video':
        icon = Icons.videocam;
        color = Colors.purple;
        break;
      case 'audio':
        icon = Icons.audiotrack;
        color = Colors.orange;
        break;
      case 'document':
        icon = Icons.article;
        color = Colors.blue;
        break;
      case 'archive':
        icon = Icons.folder;
        color = Colors.brown;
        break;
      default:
        icon = Icons.cloud_upload;
        color = Colors.blue;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 16),
            Text(
              "Uploading ${materialType.toUpperCase()}...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletingDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              "Deleting Material...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.2),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadMaterials,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        displacement: 40,
        edgeOffset: 20,
        child: _buildContent(),
      ),
      floatingActionButton:
          _isLoading
              ? null // Hide the real FAB when loading
              : FloatingActionButton.extended(
                onPressed: _showUploadDialog,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 4,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Material'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    if (_materials.isEmpty) {
      return _buildEmptyState();
    }
    return _buildMaterialList();
  }

  Widget _buildLoadingState() {
    return Stack(
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: 4, // Number of shimmer items to show
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 120,
                              height: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      Container(width: 24, height: 24, color: Colors.white),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Shimmer effect for Floating Action Button
        Positioned(
          bottom: 16,
          right: 16,
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 170, // Wider for "Upload Material"
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 24, height: 24, color: Colors.white),
                  const SizedBox(width: 8),
                  Container(width: 80, height: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animation/empty_box.json',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 24),
                Text(
                  "No Materials Available",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Upload your first material by tapping the 'Upload Material' button below",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _materials.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final material = _materials[index];

        return Material(
          borderRadius: BorderRadius.circular(14),
          elevation: 1,
          color: Theme.of(context).colorScheme.surface,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _viewMaterialInApp(material), // UPDATED: Direct view on tap
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getMaterialColor(
                        material.materialType,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getMaterialIcon(material.materialType),
                      color: _getMaterialColor(material.materialType),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.materialTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (material.description != null &&
                            material.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              material.description!,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          "${material.materialType.toUpperCase()} • ${material.fileSize ?? 'Unknown size'}",
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed:
                        () => _showMaterialOptionsModal(context, material),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getMaterialIcon(String materialType) {
    switch (materialType) {
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

  Color _getMaterialColor(String materialType) {
    switch (materialType) {
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
        return Colors.grey;
    }
  }

  void _showMaterialOptionsModal(BuildContext context, MaterialModel material) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Material info header
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getMaterialColor(
                        material.materialType,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getMaterialIcon(material.materialType),
                      color: _getMaterialColor(material.materialType),
                    ),
                  ),
                  title: Text(
                    material.materialTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${material.materialType.toUpperCase()} • ${material.fileSize ?? 'Unknown size'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),

                const Divider(height: 24),

                // View option for all supported types
                _buildActionTile(
                  context,
                  icon: Icons.visibility,
                  label: 'View ${material.materialType.toUpperCase()}',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _viewMaterialInApp(material);
                  },
                ),

                // Download option for all types
                _buildActionTile(
                  context,
                  icon: Icons.download,
                  label: 'Download ${material.materialType.toUpperCase()}',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _downloadAndOpenFile(material);
                  },
                ),

                // Delete option
                _buildActionTile(
                  context,
                  icon: Icons.delete,
                  label: 'Delete ${material.materialType.toUpperCase()}',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(material.id, material.materialTitle);
                  },
                ),

                const SizedBox(height: 8),

                // Cancel option
                _buildActionTile(
                  context,
                  icon: Icons.close,
                  label: 'Cancel',
                  color: Colors.grey,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// NEW: Image Viewer Page
class ImageViewerPage extends StatelessWidget {
  final String imageUrl;

  const ImageViewerPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Viewer'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        ),
      ),
    );
  }
}

// NEW: Video Viewer Page
class VideoViewerPage extends StatefulWidget {
  final String videoUrl;

  const VideoViewerPage({super.key, required this.videoUrl});

  @override
  State<VideoViewerPage> createState() => _VideoViewerPageState();
}

class _VideoViewerPageState extends State<VideoViewerPage> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.blue,
        handleColor: Colors.blue,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.grey.withOpacity(0.5),
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Chewie(controller: _chewieController),
      ),
    );
  }
}

// NEW: Audio Viewer Page
class AudioViewerPage extends StatefulWidget {
  final String audioUrl;
  final String title;

  const AudioViewerPage({super.key, required this.audioUrl, required this.title});

  @override
  State<AudioViewerPage> createState() => _AudioViewerPageState();
}

class _AudioViewerPageState extends State<AudioViewerPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _audioPlayer.setSource(UrlSource(widget.audioUrl));
    
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _position = position);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.audiotrack,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Slider(
              value: _position.inSeconds.toDouble(),
              min: 0,
              max: _duration.inSeconds.toDouble(),
              onChanged: (value) async {
                await _audioPlayer.seek(Duration(seconds: value.toInt()));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.skip_previous,
                    size: 40,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 60,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    if (_isPlaying) {
                      await _audioPlayer.pause();
                    } else {
                      await _audioPlayer.resume();
                    }
                    setState(() => _isPlaying = !_isPlaying);
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.skip_next,
                    size: 40,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    return duration.inHours > 0 
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}