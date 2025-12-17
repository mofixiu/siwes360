import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:siwes360/themes/theme.dart';
import 'package:siwes360/utils/request.dart';

class AddNewLogEntry extends StatefulWidget {
  const AddNewLogEntry({super.key});

  @override
  State<AddNewLogEntry> createState() => _AddNewLogEntryState();
}

class _AddNewLogEntryState extends State<AddNewLogEntry> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _activitiesController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _challengesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  List<PlatformFile> _attachedFiles = [];
  bool _isLoading = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled; // ADD THIS

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(_selectedDate);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _activitiesController.dispose();
    _skillsController.dispose();
    _challengesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: SIWES360.lightButtonBackground,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'jpg',
          'jpeg',
          'png',
          'xls',
          'xlsx',
        ],
      );

      if (result != null) {
        // Check total size
        int totalSize = result.files.fold(0, (sum, file) => sum + (file.size));
        if (totalSize > 10 * 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Total file size exceeds 10MB limit'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _attachedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking files: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  String _getFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _submitLog() async {
    print('=== Submit Log Called ===');

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');

      // Enable auto-validation after first failed attempt
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    print('Form validated successfully');

    setState(() {
      _isLoading = true;
    });

    try {
      // Get student ID from stored user data
      print('Loading user data...');
      final userData = await RequestService.loadUserData();
      print('User data loaded: ${userData != null}');

      if (userData == null || userData['role_data'] == null) {
        throw Exception('User data not found');
      }

      final studentId = userData['role_data']['user_id'];
      print('Student ID: $studentId');

      // Format date as YYYY-MM-DD in local timezone (no UTC conversion)
      final formattedDate =
          '${_selectedDate.year}-'
          '${_selectedDate.month.toString().padLeft(2, '0')}-'
          '${_selectedDate.day.toString().padLeft(2, '0')}';

      print('Selected date: $_selectedDate');
      print('Formatted date: $formattedDate');

      // Prepare log data
      final logData = {
        'student_id': studentId,
        'log_date': formattedDate, // Use local date format
        'description': _activitiesController.text.trim(),
        'skills_acquired': _skillsController.text.trim().isNotEmpty
            ? _skillsController.text.trim()
            : null,
        'challenges_faced': _challengesController.text.trim().isNotEmpty
            ? _challengesController.text.trim()
            : null,
      };

      print('Log data prepared: $logData');

      // Convert PlatformFile to File for upload
      List<File>? fileAttachments;
      if (_attachedFiles.isNotEmpty) {
        print('Processing ${_attachedFiles.length} attachments...');
        fileAttachments = _attachedFiles
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
        print('Converted ${fileAttachments.length} files');
      } else {
        print('No attachments to process');
      }

      // Create log with attachments
      print('Calling createDailyLog API...');
      final result = await RequestService.createDailyLog(
        logData,
        attachments: fileAttachments,
      );

      print('API Response: $result');

      if (!mounted) {
        print('Widget not mounted, returning');
        return;
      }

      if (result != null && result['status'] == 'success') {
        print('Log created successfully!');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Log entry created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _activitiesController.clear();
        _skillsController.clear();
        _challengesController.clear();
        setState(() {
          _attachedFiles.clear();
          _selectedDate = DateTime.now();
          _dateController.text = _formatDate(_selectedDate);
        });

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        print('API returned error: ${result?['message']}');
        throw Exception(result?['message'] ?? 'Failed to create log entry');
      }
    } catch (e, stackTrace) {
      print('=== Error in _submitLog ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      print('Finally block - setting loading to false');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('GestureDetector tapped - unfocusing');
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              print('Back button tapped');
              Navigator.pop(context);
            },
          ),
          title: const Text(
            'New Log Entry',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode, // ADD THIS
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Selection
                  _buildSectionHeader(
                    'Log Date',
                    Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildDateField(),
                  const SizedBox(height: 24),

                  // Activities/Tasks Completed
                  _buildSectionHeader(
                    'Activities Completed',
                    Icons.assignment_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _activitiesController,
                    hint:
                        'Describe the tasks and activities you worked on today...',
                    maxLines: 6,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please describe your activities';
                      }
                      if (value.trim().length < 20) {
                        return 'Please provide more details (minimum 20 characters)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Skills Acquired
                  _buildSectionHeader('Skills Acquired', Icons.star_outline),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _skillsController,
                    hint:
                        'What new skills or knowledge did you gain? (Optional)',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),

                  // Challenges Faced
                  _buildSectionHeader(
                    'Challenges Faced',
                    Icons.warning_amber_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _challengesController,
                    hint:
                        'Describe any challenges or difficulties encountered (Optional)',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),

                  // File Attachments
                  _buildSectionHeader('Attachments', Icons.attach_file),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickFiles,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 50,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Drag & drop files or',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Browse Files',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Maximum total size: 10MB',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Supported: PDF, DOC, DOCX, JPG, PNG, XLS, XLSX',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attached Files List
                  if (_attachedFiles.isNotEmpty)
                    ...List.generate(_attachedFiles.length, (index) {
                      final file = _attachedFiles[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getFileIconColor(
                                  file.name,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getFileIcon(file.name),
                                color: _getFileIconColor(file.name),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getFileSize(file.size),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _removeFile(index),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              print('Submit button tapped!');
                              print('Is loading: $_isLoading');
                              _submitLog();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A3D62),
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Submit Log Entry',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A3D62).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF0A3D62), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A3D62),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: _dateController,
        readOnly: true,
        onTap: _selectDate,
        decoration: InputDecoration(
          hintText: 'Select date',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(
            Icons.calendar_today_outlined,
            color: Color(0xFF0A3D62),
          ),
          suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a date';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: const TextStyle(fontSize: 15),
      ),
    );
  }
}
