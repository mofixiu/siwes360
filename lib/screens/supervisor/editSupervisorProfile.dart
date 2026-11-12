import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/widgets/paper.dart';

/// The workplace supervisor's own contact and workplace details. The photo is
/// kept on this phone only. Pops `true` when saved.
class EditSupervisorProfile extends StatefulWidget {
  final int supervisorId;

  const EditSupervisorProfile({super.key, required this.supervisorId});

  @override
  State<EditSupervisorProfile> createState() => _EditSupervisorProfileState();
}

enum _PhotoChoice { camera, gallery, remove }

class _EditSupervisorProfileState extends State<EditSupervisorProfile> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _organizationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  Map<String, dynamic>? _profileData;
  String? _profileImagePath;

  String get _photoKey => 'profile_image_${widget.supervisorId}';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadProfileImage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _organizationController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    try {
      final box = await Hive.openBox('supervisorProfile');
      final imagePath = box.get(_photoKey);
      if (imagePath != null && await File(imagePath).exists()) {
        if (!mounted) return;
        setState(() => _profileImagePath = imagePath);
      }
    } catch (_) {
      // No saved photo; the monogram shows the supervisor's initials.
    }
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await RequestService.getSupervisorById(widget.supervisorId);
      if (!mounted) return;

      if (result != null && result['status'] == 'success') {
        final data = result['data'];
        setState(() {
          _profileData = data;
          _nameController.text = data['full_name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _organizationController.text = data['organization'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _positionController.text = data['position'] ?? '';
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
      final fileName = 'supervisor_${widget.supervisorId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localPath = path.join(appDir.path, fileName);
      await File(image.path).copy(localPath);

      if (_profileImagePath != null) {
        try {
          await File(_profileImagePath!).delete();
        } catch (_) {
          // The old photo was already gone.
        }
      }

      final box = await Hive.openBox('supervisorProfile');
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

      final box = await Hive.openBox('supervisorProfile');
      await box.delete(_photoKey);

      if (!mounted) return;
      setState(() => _profileImagePath = null);
      showNote(context, 'Photo removed');
    } catch (_) {
      if (!mounted) return;
      showNote(context, 'Could not remove your photo', error: true);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final updateData = {
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'organization': _organizationController.text.trim(),
        'position': _positionController.text.trim(),
      };

      final result = await RequestService.updateSupervisorProfile(widget.supervisorId, updateData);
      if (!mounted) return;

      if (result != null && result['status'] == 'success') {
        final saved = result['data'] is Map ? Map<String, dynamic>.from(result['data']) : updateData;
        await _updateLocalUserData(saved);
        if (!mounted) return;
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

  /// Keeps the account saved at sign in (the user row plus `role_data`) in step
  /// with the new details, so other screens show them straight away.
  Future<void> _updateLocalUserData(Map<String, dynamic> updated) async {
    try {
      final userData = await RequestService.loadUserData();
      if (userData == null) return;
      userData['full_name'] = updated['full_name'];
      userData['email'] = updated['email'];
      userData['phone'] = updated['phone'];
      if (userData['role_data'] is Map) {
        final roleData = Map<String, dynamic>.from(userData['role_data']);
        roleData['organization'] = updated['organization'];
        roleData['position'] = updated['position'];
        userData['role_data'] = roleData;
      }
      await RequestService.saveUserData(userData);
    } catch (_) {
      // The server has the new details; the saved copy refreshes at the next sign in.
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

          _heading('Your details'),
          const Rule(),
          const SizedBox(height: Space.lg),
          _field(
            'Full name',
            _nameController,
            hint: 'First and last name',
            validator: (v) => _required(v, 'Enter your full name'),
          ),
          _field(
            'Email',
            _emailController,
            hint: 'name@company.com',
            keyboardType: TextInputType.emailAddress,
            mono: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your email';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          _field(
            'Phone',
            _phoneController,
            hint: '0800 000 0000',
            keyboardType: TextInputType.phone,
            mono: true,
            validator: (v) => _required(v, 'Enter your phone number'),
          ),

          _heading('Workplace'),
          const Rule(),
          const SizedBox(height: Space.lg),
          _field(
            'Organisation',
            _organizationController,
            hint: 'Company or organisation name',
            validator: (v) => _required(v, 'Enter your organisation'),
          ),
          _field(
            'Position',
            _positionController,
            hint: 'e.g. Site engineer',
            validator: (v) => _required(v, 'Enter your position'),
          ),
        ],
      ),
    );
  }

  static String _text(dynamic value) => value == null ? '' : '$value';

  static String? _required(String? value, String message) => (value == null || value.isEmpty) ? message : null;

  Widget _heading(String text) => SectionLabel(text, padding: const EdgeInsets.only(top: Space.xl, bottom: Space.sm));

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
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
            textInputAction: TextInputAction.next,
            style: mono ? Txt.mono(Txt.body) : Txt.bodyStyle,
            decoration: InputDecoration(hintText: hint),
            validator: validator,
          ),
        ],
      ),
    );
  }
}
