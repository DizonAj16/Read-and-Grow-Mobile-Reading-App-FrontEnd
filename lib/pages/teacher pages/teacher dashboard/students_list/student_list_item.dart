import 'package:deped_reading_app_laravel/models/student.dart';
import 'package:flutter/material.dart';

class StudentListItem extends StatelessWidget {
  final Student student;
  final String? imageUrl;
  final VoidCallback onViewPressed;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const StudentListItem({
    super.key,
    required this.student,
    required this.imageUrl,
    required this.onViewPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          width: 1.2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).colorScheme.primary,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  student.avatarLetter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                )
              : null,
        ),
        title: Text(
          student.studentName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              if (student.studentSection != null && student.studentSection!.isNotEmpty)
                _buildSectionTag(context),
              if (student.studentGrade != null && student.studentGrade!.isNotEmpty)
                _buildGradeTag(context),
            ],
          ),
        ),
        trailing: _buildPopupMenu(context),
      ),
    );
  }

  Widget _buildSectionTag(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Section: ${student.studentSection}",
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildGradeTag(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Grade: ${student.studentGrade}",
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'view') onViewPressed();
        if (value == 'edit') onEditPressed();
        if (value == 'delete') onDeletePressed();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, color: Colors.blue),
              SizedBox(width: 8),
              Text('View'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.orange),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );
  }
}