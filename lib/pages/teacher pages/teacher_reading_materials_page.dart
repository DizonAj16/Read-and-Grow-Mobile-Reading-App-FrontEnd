import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:just_audio/just_audio.dart';
import '../../api/reading_materials_service.dart';

class TeacherReadingMaterialsPage extends StatefulWidget {
  final String? classId;
  final VoidCallback? onWillPop;

  const TeacherReadingMaterialsPage({super.key, this.classId, this.onWillPop});

  @override
  State<TeacherReadingMaterialsPage> createState() =>
      _TeacherReadingMaterialsPageState();
}

class _TeacherReadingMaterialsPageState
    extends State<TeacherReadingMaterialsPage> {
  final supabase = Supabase.instance.client;
  List<ReadingMaterial> _materials = [];
  List<Map<String, dynamic>> _readingLevels = [];
  bool _isLoading = true;
  String? _className;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadReadingLevels(),
        _loadMaterials(),
        if (widget.classId != null) _loadClassName(),
      ]);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadClassName() async {
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
      debugPrint('❌ Error loading classroom name: $e');
    }
  }

  Future<void> _loadReadingLevels() async {
    try {
      final levels = await ReadingMaterialsService.getAllReadingLevels();
      if (mounted) {
        setState(() => _readingLevels = levels);
      }
    } catch (e) {
      debugPrint('❌ Error loading reading levels: $e');
    }
  }

  Future<void> _loadMaterials() async {
    try {
      final materials =
          widget.classId != null
              ? await ReadingMaterialsService.getReadingMaterialsByClassroom(
                widget.classId!,
              )
              : await ReadingMaterialsService.getAllReadingMaterials();

      if (mounted) {
        setState(() => _materials = materials);
      }
    } catch (e) {
      debugPrint('❌ Error loading materials: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _loadAvailablePrerequisites() async {
    try {
      // Get all materials except the ones already uploaded (for editing)
      final materials = widget.classId != null
          ? await ReadingMaterialsService.getReadingMaterialsByClassroom(
              widget.classId!,
            )
          : await ReadingMaterialsService.getAllReadingMaterials();

      // Convert to format needed for dropdown
      return materials.map((material) {
        return {
          'id': material.id,
          'title': material.title,
          'level': material.levelNumber ?? 'N/A',
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error loading prerequisites: $e');
      return [];
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  String _truncateFileName(String fileName, {int maxLength = 30}) {
    if (fileName.length <= maxLength) return fileName;
    return '${fileName.substring(0, maxLength - 3)}...';
  }

  Future<void> _showUploadDialog() async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedLevelId;
    File? selectedFile;
    String? fileType;
    bool hasPrerequisite = false;
    String? selectedPrerequisiteId;

    // Load available prerequisites
    final availablePrerequisites = await _loadAvailablePrerequisites();

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  insetPadding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.upload_file,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.classId != null
                                      ? 'Upload Classroom Material'
                                      : 'Upload Reading Material',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        // Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Classroom indicator if classId is provided
                                if (widget.classId != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.blue[200]!,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.class_rounded,
                                          color: Colors.blue[700],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _className != null
                                                ? 'Classroom: $_className'
                                                : 'Classroom Material',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                _buildFormField(
                                  controller: titleController,
                                  label: 'Title *',
                                  hintText: 'Enter material title',
                                  icon: Icons.title,
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  controller: descriptionController,
                                  label: 'Description',
                                  hintText: 'Optional description',
                                  icon: Icons.description,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Reading Level *',
                                      border: InputBorder.none,
                                      labelStyle: TextStyle(
                                        color: primaryColor,
                                      ),
                                    ),
                                    value: selectedLevelId,
                                    items:
                                        _readingLevels.map((level) {
                                          return DropdownMenuItem(
                                            value: level['id'] as String,
                                            child: Text(
                                              'Level ${level['level_number']}: ${level['title']}',
                                              style: TextStyle(
                                                color: Colors.blueGrey[800],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                    onChanged:
                                        (value) => setDialogState(
                                          () => selectedLevelId = value,
                                        ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Prerequisite Toggle Section
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Toggle Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.lock_outline,
                                                color: hasPrerequisite ? primaryColor : Colors.grey,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Add Prerequisite',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: hasPrerequisite ? primaryColor : Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Switch(
                                            value: hasPrerequisite,
                                            onChanged: (value) {
                                              setDialogState(() {
                                                hasPrerequisite = value;
                                                if (!value) {
                                                  selectedPrerequisiteId = null;
                                                }
                                              });
                                            },
                                            activeColor: primaryColor,
                                            inactiveTrackColor: Colors.grey[300],
                                          ),
                                        ],
                                      ),
                                      
                                      // Prerequisite Dropdown (only shown when toggle is on)
                                      if (hasPrerequisite) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          child: DropdownButtonFormField<String>(
                                            decoration: InputDecoration(
                                              labelText: 'Select Prerequisite *',
                                              border: InputBorder.none,
                                              labelStyle: TextStyle(
                                                color: primaryColor,
                                              ),
                                              hintText: 'Choose a material',
                                            ),
                                            value: selectedPrerequisiteId,
                                            items: [
                                              // Default option
                                              DropdownMenuItem(
                                                value: null,
                                                child: Text(
                                                  'Select a material',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ),
                                              ...availablePrerequisites.map((material) {
                                                return DropdownMenuItem(
                                                  value: material['id'] as String,
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        material['title'] as String,
                                                        style: TextStyle(
                                                          color: Colors.blueGrey[800],
                                                        ),
                                                      ),
                                                      Text(
                                                        'Level ${material['level']}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ],
                                            onChanged: (value) => setDialogState(
                                              () => selectedPrerequisiteId = value,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.blue[200]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                size: 18,
                                                color: Colors.blue[700],
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Students must complete this prerequisite before accessing the new material',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue[700],
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
                                const SizedBox(height: 20),
                                
                                // File Upload Section
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // File type indicator
                                      if (fileType == 'pdf')
                                        Icon(
                                          Icons.picture_as_pdf,
                                          size: 40,
                                          color: Colors.red[600],
                                        )
                                      else if (fileType == 'image')
                                        Icon(
                                          Icons.image,
                                          size: 40,
                                          color: Colors.green[600],
                                        )
                                      else
                                        Icon(
                                          Icons.insert_drive_file,
                                          size: 40,
                                          color: primaryColor,
                                        ),

                                      const SizedBox(height: 12),

                                      // File selection buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                final result = await FilePicker
                                                    .platform
                                                    .pickFiles(
                                                      type: FileType.custom,
                                                      allowedExtensions: [
                                                        'pdf',
                                                      ],
                                                    );
                                                if (result != null &&
                                                    result.files.single.path !=
                                                        null) {
                                                  setDialogState(() {
                                                    selectedFile = File(
                                                      result.files.single.path!,
                                                    );
                                                    fileType = 'pdf';
                                                  });
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.picture_as_pdf,
                                                size: 20,
                                              ),
                                              label: const Text(
                                                'PDF',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red[50],
                                                foregroundColor:
                                                    Colors.red[700],
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  side: BorderSide(
                                                    color: Colors.red[200]!,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                final result = await FilePicker
                                                    .platform
                                                    .pickFiles(
                                                      type: FileType.image,
                                                    );
                                                if (result != null &&
                                                    result.files.single.path !=
                                                        null) {
                                                  setDialogState(() {
                                                    selectedFile = File(
                                                      result.files.single.path!,
                                                    );
                                                    fileType = 'image';
                                                  });
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.image,
                                                size: 20,
                                              ),
                                              label: const Text(
                                                'Image',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.green[50],
                                                foregroundColor:
                                                    Colors.green[700],
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  side: BorderSide(
                                                    color: Colors.green[200]!,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      if (selectedFile != null) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                fileType == 'pdf'
                                                    ? Colors.red[50]
                                                    : Colors.green[50],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  fileType == 'pdf'
                                                      ? Colors.red[200]!
                                                      : Colors.green[200]!,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                fileType == 'pdf'
                                                    ? Icons.picture_as_pdf
                                                    : Icons.image,
                                                color:
                                                    fileType == 'pdf'
                                                        ? Colors.red[600]
                                                        : Colors.green[600],
                                                size: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _truncateFileName(
                                                        selectedFile!.path
                                                            .split('/')
                                                            .last,
                                                      ),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            fileType == 'pdf'
                                                                ? Colors
                                                                    .red[700]
                                                                : Colors
                                                                    .green[700],
                                                      ),
                                                    ),
                                                    Text(
                                                      fileType == 'pdf'
                                                          ? 'PDF Document'
                                                          : 'Image File',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            fileType == 'pdf'
                                                                ? Colors
                                                                    .red[600]
                                                                : Colors
                                                                    .green[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  size: 18,
                                                  color: Colors.grey,
                                                ),
                                                onPressed: () {
                                                  setDialogState(() {
                                                    selectedFile = null;
                                                    fileType = null;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ] else ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Select PDF or Image file',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Actions
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(color: Colors.grey[400]!),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      selectedFile != null &&
                                              selectedLevelId != null &&
                                              titleController.text
                                                  .trim()
                                                  .isNotEmpty &&
                                              (!hasPrerequisite || selectedPrerequisiteId != null)
                                          ? () async {
                                            Navigator.pop(context);
                                            await _uploadMaterial(
                                              file: selectedFile!,
                                              title:
                                                  titleController.text.trim(),
                                              levelId: selectedLevelId!,
                                              description:
                                                  descriptionController.text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : descriptionController
                                                          .text
                                                          .trim(),
                                              prerequisiteId: hasPrerequisite 
                                                  ? selectedPrerequisiteId 
                                                  : null,
                                            );
                                          }
                                          : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Upload',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
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
    );
  }

  Future<void> _uploadMaterial({
    required File file,
    required String title,
    required String levelId,
    String? description,
    String? prerequisiteId,
  }) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.classId != null
                          ? 'Uploading Classroom Material...'
                          : 'Uploading Material...',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final result = await ReadingMaterialsService.uploadReadingMaterial(
        file: file,
        title: title,
        levelId: levelId,
        description: description,
        classroomId: widget.classId,
        prerequisiteId: prerequisiteId,
      );

      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;

      if (result != null && !result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.classId != null
                      ? 'Classroom material uploaded successfully!'
                      : 'Material uploaded successfully!',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        await _loadMaterials();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(result?['error'] ?? 'Upload failed'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Error: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showAssignMaterialsDialog() async {
    if (widget.classId == null) return;

    final primaryColor = Theme.of(context).colorScheme.primary;
    final isMobile = MediaQuery.of(context).size.width < 600;

    setState(() => _isLoading = true);

    final unassignedMaterials =
        await ReadingMaterialsService.getUnassignedReadingMaterials(
          classroomId: widget.classId!,
        );

    setState(() => _isLoading = false);

    if (unassignedMaterials.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No unassigned materials available'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              final selectedMaterials = <String>{};

              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                insetPadding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_to_photos,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Assign Existing Materials',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      // Materials list
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: unassignedMaterials.length,
                          itemBuilder: (context, index) {
                            final material = unassignedMaterials[index];
                            final isSelected = selectedMaterials.contains(
                              material.id,
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: CheckboxListTile(
                                title: Text(material.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Level ${material.levelNumber ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (material.description != null)
                                      Text(
                                        material.description!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                                secondary: Icon(
                                  material.fileUrl.toLowerCase().endsWith(
                                        '.pdf',
                                      )
                                      ? Icons.picture_as_pdf
                                      : Icons.image,
                                  color: primaryColor,
                                ),
                                value: isSelected,
                                onChanged: (value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      selectedMaterials.add(material.id);
                                    } else {
                                      selectedMaterials.remove(material.id);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      // Actions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    selectedMaterials.isEmpty
                                        ? null
                                        : () async {
                                          await _assignMaterialsToClassroom(
                                            materialIds:
                                                selectedMaterials.toList(),
                                          );
                                          Navigator.pop(context);
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Assign (${selectedMaterials.length})',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Future<void> _assignMaterialsToClassroom({
    required List<String> materialIds,
  }) async {
    if (widget.classId == null) return;

    int successCount = 0;
    int failCount = 0;

    for (final materialId in materialIds) {
      final success = await ReadingMaterialsService.assignMaterialToClassroom(
        materialId: materialId,
        classroomId: widget.classId!,
      );

      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assigned $successCount materials. Failed: $failCount'),
          backgroundColor: successCount > 0 ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      if (successCount > 0) {
        await _loadMaterials();
      }
    }
  }

  Future<void> _deleteMaterial(ReadingMaterial material) async {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (widget.classId != null) {
      final action = await showDialog<String>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Remove Material'),
              content: Text(
                'Do you want to remove "${material.title}" from this classroom, or delete it entirely?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'cancel'),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, 'remove'),
                  child: const Text('Remove from Classroom'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, 'delete'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Delete Permanently',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
      );

      if (action == 'remove') {
        final success =
            await ReadingMaterialsService.removeMaterialFromClassroom(
              materialId: material.id,
              classroomId: widget.classId!,
            );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Material removed from classroom'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          await _loadMaterials();
        }
        return;
      } else if (action != 'delete') {
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text(
              'Are you sure you want to permanently delete "${material.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final success = await ReadingMaterialsService.deleteReadingMaterial(
      material.id,
    );
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material deleted successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        await _loadMaterials();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete material'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _viewSubmissions(ReadingMaterial material) async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final submissions = await ReadingMaterialsService.getSubmissionsForMaterial(
      material.id,
    );

    if (!mounted) return;

    final audioPlayer = AudioPlayer();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              String? playingUrl;

              return Container(
                height:
                    MediaQuery.of(context).size.height * (isMobile ? 0.9 : 0.8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.people,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Submissions for "${material.title}"',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 24,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              audioPlayer.dispose();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Container(
                        color: Colors.grey[50],
                        child:
                            submissions.isEmpty
                                ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.assignment_outlined,
                                          size: isMobile ? 60 : 80,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No submissions yet',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: isMobile ? 16 : 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Students haven\'t submitted recordings for this material',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: isMobile ? 12 : 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: submissions.length,
                                  itemBuilder: (context, index) {
                                    final submission = submissions[index];
                                    final student =
                                        submission['students']
                                            as Map<String, dynamic>?;
                                    final recordingUrl =
                                        submission['recording_url']
                                            as String? ??
                                        submission['file_url'] as String?;
                                    final isPlaying =
                                        playingUrl == recordingUrl;
                                    final needsGrading =
                                        submission['needs_grading'] == true;

                                    // Extract profile picture from student data
                                    final profilePic =
                                        student?['profile_picture'] as String?;
                                    debugPrint(
                                      'profile_picture field: $profilePic',
                                    );

                                    // Format date/time
                                    final submissionDate =
                                        submission['created_at'] ??
                                        submission['recorded_at'];
                                    final formattedDate = _formatSubmissionDate(
                                      submissionDate,
                                    );

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Material(
                                        borderRadius: BorderRadius.circular(16),
                                        elevation: 1,
                                        color: Colors.white,
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.all(
                                            16,
                                          ),
                                          leading: _buildStudentAvatar(
                                            studentName:
                                                student?['student_name']
                                                    as String?,
                                            profilePic: profilePic,
                                            primaryColor: primaryColor,
                                          ),
                                          title: Text(
                                            student?['student_name'] ??
                                                'Unknown',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueGrey[800],
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Submitted: $formattedDate',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              if (needsGrading) ...[
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Needs Grading',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.orange[800],
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          trailing:
                                              recordingUrl != null
                                                  ? Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          isPlaying
                                                              ? primaryColor
                                                              : primaryColor
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        isPlaying
                                                            ? Icons.pause
                                                            : Icons.play_arrow,
                                                        color:
                                                            isPlaying
                                                                ? Colors.white
                                                                : primaryColor,
                                                        size: 20,
                                                      ),
                                                      onPressed: () async {
                                                        try {
                                                          if (isPlaying) {
                                                            await audioPlayer
                                                                .stop();
                                                            setModalState(
                                                              () =>
                                                                  playingUrl =
                                                                      null,
                                                            );
                                                          } else {
                                                            await audioPlayer
                                                                .setUrl(
                                                                  recordingUrl,
                                                                );
                                                            await audioPlayer
                                                                .play();
                                                            setModalState(
                                                              () =>
                                                                  playingUrl =
                                                                      recordingUrl,
                                                            );

                                                            audioPlayer.playerStateStream.listen((
                                                              state,
                                                            ) {
                                                              if (state
                                                                      .processingState ==
                                                                  ProcessingState
                                                                      .completed) {
                                                                setModalState(
                                                                  () =>
                                                                      playingUrl =
                                                                          null,
                                                                );
                                                              }
                                                            });
                                                          }
                                                        } catch (e) {
                                                          debugPrint(
                                                            'Error playing audio: $e',
                                                          );
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Error playing audio: $e',
                                                              ),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  )
                                                  : Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      Icons.error,
                                                      size: 20,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    ).whenComplete(() => audioPlayer.dispose());
  }

  Widget _buildStudentAvatar({
    required String? studentName,
    required String? profilePic,
    required Color primaryColor,
  }) {
    final name = studentName ?? 'U';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    // If profile picture exists and is not empty
    if (profilePic != null && profilePic.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.network(
            profilePic,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                    strokeWidth: 2,
                    color: primaryColor,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // Fallback to initials if image fails to load
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // Fallback to initials if no profile picture
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  String _formatSubmissionDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown date';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      // Format based on how recent it is
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        // Format as date if older than a week
        final formatter = DateFormat('MMM d, y • h:mm a');
        return formatter.format(date.toLocal());
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
      return 'Invalid date';
    }
  }

  Widget _buildMaterialItem(ReadingMaterial material, int index) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final isPdf = material.fileUrl.toLowerCase().endsWith('.pdf');
    final isImage =
        material.fileUrl.toLowerCase().endsWith('.jpg') ||
        material.fileUrl.toLowerCase().endsWith('.jpeg') ||
        material.fileUrl.toLowerCase().endsWith('.png');

    IconData fileIcon;
    Color iconColor;
    Color backgroundColor;

    if (isPdf) {
      fileIcon = Icons.picture_as_pdf;
      iconColor = Colors.white;
      backgroundColor = Colors.red[600]!;
    } else if (isImage) {
      fileIcon = Icons.image;
      iconColor = Colors.white;
      backgroundColor = Colors.green[600]!;
    } else {
      fileIcon = Icons.insert_drive_file;
      iconColor = Colors.white;
      backgroundColor = primaryColor;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        color: Colors.white,
        child: ListTile(
          contentPadding: EdgeInsets.all(isMobile ? 16 : 20),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(fileIcon, color: iconColor, size: isMobile ? 24 : 28),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  material.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 15 : 16,
                    color: Colors.blueGrey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (material.hasPrerequisite ?? false) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Has prerequisite',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: isMobile ? 14 : 16,
                      color: Colors.amber[800],
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Level ${material.levelNumber ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (material.className != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        material.className!,
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (material.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  material.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              // Display prerequisite information if exists
              if (material.prerequisiteTitle != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Requires: ${material.prerequisiteTitle!}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          trailing: Wrap(
            spacing: isMobile ? 4 : 8,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.people,
                    size: isMobile ? 18 : 20,
                    color: primaryColor,
                  ),
                  onPressed: () => _viewSubmissions(material),
                  tooltip: 'View Submissions',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.delete,
                    size: isMobile ? 18 : 20,
                    color: Colors.red[700],
                  ),
                  onPressed: () => _deleteMaterial(material),
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          onTap: () {
            if (isPdf) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => Scaffold(
                        appBar: AppBar(
                          title: Text(material.title),
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        body: SfPdfViewer.network(material.fileUrl),
                      ),
                ),
              );
            } else if (isImage) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => Scaffold(
                        appBar: AppBar(
                          title: Text(material.title),
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        body: Center(
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 3.0,
                            child: Image.network(
                              material.fileUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: primaryColor,
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Failed to load image',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                ),
              );
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.classId != null
                    ? 'Classroom Materials'
                    : 'Reading Materials',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              if (widget.classId != null && _className != null)
                Text(
                  _className!,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          // actions: [
          //   if (widget.classId != null)
          //     Padding(
          //       padding: const EdgeInsets.only(right: 8),
          //       child: IconButton(
          //         icon: Icon(
          //           Icons.add_to_photos,
          //           size: isMobile ? 20 : 24,
          //           color: primaryColor,
          //         ),
          //         onPressed: _showAssignMaterialsDialog,
          //         tooltip: 'Assign Existing Materials',
          //       ),
          //     ),
          //   Padding(
          //     padding: const EdgeInsets.only(right: 16),
          //     child: CircleAvatar(
          //       backgroundColor: primaryColor.withOpacity(0.1),
          //       child: IconButton(
          //         icon: Icon(
          //           Icons.close_rounded,
          //           size: 20,
          //           color: primaryColor,
          //         ),
          //         onPressed: widget.onWillPop,
          //       ),
          //     ),
          //   ),
          // ],
        ),
        body: SafeArea(
          child:
              _isLoading
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: primaryColor,
                          strokeWidth: 2.5,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.classId != null
                              ? 'Loading Classroom Materials...'
                              : 'Loading Materials...',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                  : Column(
                    children: [
                      if (widget.classId != null)
                        Container(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          color: Colors.blue[50],
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[700],
                                size: isMobile ? 18 : 20,
                              ),
                              SizedBox(width: isMobile ? 8 : 12),
                              Expanded(
                                child: Text(
                                  'These materials are assigned to this classroom only',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _handleRefresh,
                          color: primaryColor,
                          backgroundColor: Colors.white,
                          child:
                              _materials.isEmpty
                                  ? Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        isMobile ? 24 : 32,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.library_books_outlined,
                                            size: isMobile ? 60 : 80,
                                            color: Colors.grey[400],
                                          ),
                                          SizedBox(height: isMobile ? 16 : 24),
                                          Text(
                                            widget.classId != null
                                                ? 'No Classroom Materials Yet'
                                                : 'No Reading Materials Yet',
                                            style: TextStyle(
                                              fontSize: isMobile ? 16 : 18,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: isMobile ? 8 : 12),
                                          Text(
                                            widget.classId != null
                                                ? 'Tap + to upload or assign materials'
                                                : 'Tap + to upload your first material',
                                            style: TextStyle(
                                              fontSize: isMobile ? 12 : 14,
                                              color: Colors.grey[500],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    controller: _scrollController,
                                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                                    itemCount: _materials.length,
                                    itemBuilder: (context, index) {
                                      final material = _materials[index];
                                      return _buildMaterialItem(
                                        material,
                                        index,
                                      );
                                    },
                                  ),
                        ),
                      ),
                    ],
                  ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showUploadDialog,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          child: Icon(Icons.add, size: isMobile ? 24 : 28),
        ),
      ),
    );
  }
}