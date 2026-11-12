import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/widgets/paper.dart';

/// The student's own profile. The academic record is read-only (the
/// institution owns it); the internship dates, workplace and workplace
/// supervisor can be changed. The photo is kept on this phone only.
/// Pops `true` when saved.
class EditStudentProfile extends StatefulWidget {
  final int studentId;

  const EditStudentProfile({super.key, required this.studentId});

  @override
  State<EditStudentProfile> createState() => _EditStudentProfileState();
}

enum _PhotoChoice { camera, gallery, remove }

class _EditStudentProfileState extends State<EditStudentProfile> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _supervisorNameController = TextEditingController();
  final _supervisorPhoneController = TextEditingController();
  final _supervisorEmailController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  Map<String, dynamic>? _profileData;
  String? _profileImagePath;

  String get _photoKey => 'profile_image_${widget.studentId}';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadProfileImage();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _supervisorNameController.dispose();
    _supervisorPhoneController.dispose();
    _supervisorEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    try {
      final box = await Hive.openBox('studentProfile');
      final imagePath = box.get(_photoKey);
      if (imagePath != null && await File(imagePath).exists()) {
        if (!mounted) return;
        setState(() => _profileImagePath = imagePath);
      }
    } catch (_) {
      // No saved photo; the monogram shows the student's initials.
    }
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await RequestService.getStudentProfile(widget.studentId);
      if (!mounted) return;

      if (result != null && result['status'] == 'success') {
        final data = result['data'];
        setState(() {
          _profileData = data;
          _companyController.text = data['workplace_name'] ?? '';
          _locationController.text = data['workplace_location'] ?? '';
          _addressController.text = data['workplace_address'] ?? '';
          _supervisorNameController.text = data['supervisor_name'] ?? '';
          _supervisorPhoneController.text = data['supervisor_phone'] ?? '';
          _supervisorEmailController.text = data['supervisor_email'] ?? '';
          _startDate = parseDay(data['internship_start_date']);
          _endDate = parseDay(data['internship_end_date']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result?['message'] ?? 'Check your connection and try again.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _changeProfilePhoto() async {
    final choice = await showPaperSheet<_PhotoChoice>(
      context,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profile photo', style: Txt.titleStyle),
                  const SizedBox(height: Space.xs),
                  Text('Saved on this phone only.', style: Txt.smallStyle),
                ],
              ),
            ),
            const Rule(),
            LedgerRow(
              leading: const Icon(Icons.photo_camera_outlined, size: 20),
              showChevron: false,
              onTap: () => Navigator.pop(sheetContext, _PhotoChoice.camera),
              child: Text('Take a photo', style: Txt.bodyStyle),
            ),
            LedgerRow(
              leading: const Icon(Icons.photo_library_outlined, size: 20),
              showChevron: false,
              onTap: () => Navigator.pop(sheetContext, _PhotoChoice.gallery),
              child: Text('Choose from gallery', style: Txt.bodyStyle),
            ),
            if (_profileImagePath != null)
              LedgerRow(
                leading: const Icon(Icons.delete_outline, size: 20, color: Palette.brick),
                showChevron: false,
                onTap: () => Navigator.pop(sheetContext, _PhotoChoice.remove),
                child: Text('Remove photo', style: Txt.sans(Txt.body, weight: FontWeight.w600, color: Palette.brick)),
              ),
            const SizedBox(height: Space.lg),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    switch (choice) {
      case _PhotoChoice.camera:
        await _pickImage(ImageSource.camera);
      case _PhotoChoice.gallery:
        await _pickImage(ImageSource.gallery);
      case _PhotoChoice.remove:
        await _removeProfileImage();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;

      // Keep a copy in the app's documents folder so it survives the picker's cache.
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${widget.studentId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localPath = path.join(appDir.path, fileName);
      await File(image.path).copy(localPath);

      if (_profileImagePath != null) {
        try {
          await File(_profileImagePath!).delete();
        } catch (_) {
          // The old photo was already gone.
        }
      }

      final box = await Hive.openBox('studentProfile');
      await box.put(_photoKey, localPath);

      if (!mounted) return;
      setState(() => _profileImagePath = localPath);
      showNote(context, 'Photo updated');
    } catch (_) {
      if (!mounted) return;
      showNote(context, 'Could not change your photo', error: true);
    }
  }

  Future<void> _removeProfileImage() async {
    try {
      if (_profileImagePath != null) {
        try {
          await File(_profileImagePath!).delete();
        } catch (_) {
          // The file was already gone; still clear the saved path.
        }
      }

      final box = await Hive.openBox('studentProfile');
      await box.delete(_photoKey);

      if (!mounted) return;
      setState(() => _profileImagePath = null);
      showNote(context, 'Photo removed');
    } catch (_) {
      if (!mounted) return;
      showNote(context, 'Could not remove your photo', error: true);
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: isStartDate ? 'Internship start date' : 'Internship end date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStartDate) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      showNote(context, 'Choose both a start date and an end date', error: true);
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      showNote(context, 'The end date must be after the start date', error: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final result = await RequestService.updateStudentInternshipDates(
        widget.studentId,
        apiDay(_startDate!),
        apiDay(_endDate!),
        workplaceName: _companyController.text.trim(),
        workplaceAddress: _addressController.text.trim(),
        workplaceLocation: _locationController.text.trim(),
        supervisorName: _supervisorNameController.text.trim(),
        supervisorPhone: _supervisorPhoneController.text.trim(),
        supervisorEmail: _supervisorEmailController.text.trim(),
      );
      if (!mounted) return;

      if (result != null && result['status'] == 'success') {
        showNote(context, 'Profile saved');
        Navigator.pop(context, true);
      } else {
        showNote(context, result?['message'] ?? 'Could not save your changes', error: true);
      }
    } catch (_) {
      if (!mounted) return;
      showNote(context, 'Could not save your changes. Check your connection and try again.', error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = !_isLoading && _errorMessage.isEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          title: const Text('Edit profile'),
        ),
        bottomNavigationBar: ready
            ? BottomAction(child: PrimaryButton(label: 'Save changes', onPressed: _saveChanges, busy: _isSaving))
            : null,
        body: _isLoading
            ? const LoadingView()
            : _errorMessage.isNotEmpty
                ? ErrorView(message: _errorMessage, onRetry: _loadProfileData)
                : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    final data = _profileData ?? const {};
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, Space.xxl),
        children: [
          Center(
            child: Column(
              children: [
                Monogram(name: _text(data['full_name']), size: 72, photoPath: _profileImagePath),
                const SizedBox(height: Space.xs),
                TextButton(onPressed: _changeProfilePhoto, child: const Text('Change photo')),
              ],
            ),
          ),

          _heading('Academic info'),
          Text(
            "Official records cannot be edited. Ask your institution's SIWES office to correct them.",
            style: Txt.smallStyle,
          ),
          const SizedBox(height: Space.sm),
          const Rule(),
          LockedField(label: 'Institution', value: _text(data['school_name'])),
          LockedField(label: 'Department', value: _text(data['department'])),
          LockedField(label: 'Email', value: _text(data['email']), mono: true),
          LockedField(label: 'Matric number', value: _text(data['matric_no']), mono: true),
          LockedField(label: 'Level', value: _text(data['level']), mono: true),

          _heading('Internship period'),
          const Rule(),
          const SizedBox(height: Space.lg),
          _dateField('Start date', _startDate, () => _selectDate(true)),
          _dateField('End date', _endDate, () => _selectDate(false)),

          _heading('Workplace'),
          const Rule(),
          const SizedBox(height: Space.lg),
          _field(
            'Company name',
            _companyController,
            hint: 'Where you are doing your SIWES',
            validator: (v) => _required(v, 'Enter the company name'),
          ),
          _field(
            'Location',
            _locationController,
            hint: 'e.g. Ikeja, Lagos',
            validator: (v) => _required(v, 'Enter the company location'),
          ),
          _field(
            'Address',
            _addressController,
            hint: 'Street address',
            maxLines: 2,
            validator: (v) => _required(v, 'Enter the company address'),
          ),

          _heading('Workplace supervisor'),
          const Rule(),
          const SizedBox(height: Space.lg),
          _field(
            'Name',
            _supervisorNameController,
            hint: 'Full name',
            validator: (v) => _required(v, "Enter your supervisor's name"),
          ),
          _field(
            'Phone',
            _supervisorPhoneController,
            hint: '0800 000 0000',
            keyboardType: TextInputType.phone,
            mono: true,
            validator: (v) => _required(v, "Enter your supervisor's phone number"),
          ),
          _field(
            'Email',
            _supervisorEmailController,
            hint: 'name@company.com',
            keyboardType: TextInputType.emailAddress,
            mono: true,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Enter your supervisor's email";
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
        ],
      ),
    );
  }

  static String _text(dynamic value) => value == null ? '' : '$value';

  static String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  Widget _heading(String text) => SectionLabel(text, padding: const EdgeInsets.only(top: Space.xl, bottom: Space.sm));

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool mono = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: Txt.labelStyle),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: mono ? Txt.mono(Txt.body) : Txt.bodyStyle,
            decoration: InputDecoration(hintText: hint),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, DateTime? date, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: Txt.labelStyle),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.control),
            child: InputDecorator(
              decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined, size: 18)),
              child: Text(
                date == null ? 'Choose a date' : Dates.full(date),
                style: date == null ? Txt.sans(Txt.body, color: Palette.inkFaint) : Txt.mono(Txt.body),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
