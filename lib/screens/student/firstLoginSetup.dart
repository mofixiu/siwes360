import 'package:flutter/material.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/utils/role_router.dart';
import 'package:siwes360/widgets/paper.dart';

/// Shown once, the first time a student signs in: internship dates, workplace
/// and workplace supervisor. If the supervisor already has an account, picking
/// them from the search links the student to them.
class FirstLoginSetup extends StatefulWidget {
  final Map<String, dynamic> userData;

  const FirstLoginSetup({super.key, required this.userData});

  @override
  State<FirstLoginSetup> createState() => _FirstLoginSetupState();
}

class _FirstLoginSetupState extends State<FirstLoginSetup> {
  final _formKey = GlobalKey<FormState>();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _workplaceNameController = TextEditingController();
  final _workplaceAddressController = TextEditingController();
  final _workplaceLocationController = TextEditingController();
  final _supervisorNameController = TextEditingController();
  final _supervisorPhoneController = TextEditingController();
  final _supervisorEmailController = TextEditingController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _isLoading = false;
  List<Map<String, dynamic>> _supervisorSuggestions = [];
  bool _isSearching = false;

  /// The supervisor's user_id once one is picked from the search, sent as supervisor_id.
  int? _selectedSupervisorId;

  /// The picked supervisor's search result, shown as the linked row.
  Map<String, dynamic>? _linkedSupervisor;

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _workplaceNameController.dispose();
    _workplaceAddressController.dispose();
    _workplaceLocationController.dispose();
    _supervisorNameController.dispose();
    _supervisorPhoneController.dispose();
    _supervisorEmailController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Internship start date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedStartDate = picked;
      _startDateController.text = Dates.full(picked);
      if (_selectedEndDate != null && _selectedEndDate!.isBefore(picked)) {
        _selectedEndDate = null;
        _endDateController.clear();
      }
    });
  }

  Future<void> _selectEndDate() async {
    if (_selectedStartDate == null) {
      showNote(context, 'Choose the start date first');
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate!.add(const Duration(days: 180)),
      firstDate: _selectedStartDate!.add(const Duration(days: 1)),
      lastDate: DateTime(2030),
      helpText: 'Internship end date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedEndDate = picked;
      _endDateController.text = Dates.full(picked);
    });
  }

  Future<void> _searchSupervisors(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _supervisorSuggestions = [];
        if (query.isEmpty) {
          _selectedSupervisorId = null;
          _linkedSupervisor = null;
        }
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final result = await RequestService.searchSupervisors(query);
      if (!mounted) return;
      setState(() {
        if (result != null && result['status'] == 'success') {
          _supervisorSuggestions = List<Map<String, dynamic>>.from(result['data'] ?? []);
        }
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  void _selectSupervisor(Map<String, dynamic> supervisor) {
    setState(() {
      _selectedSupervisorId = supervisor['user_id'];
      _linkedSupervisor = supervisor;
      _supervisorNameController.text = supervisor['full_name'] ?? '';
      _supervisorEmailController.text = supervisor['email'] ?? '';
      _supervisorPhoneController.text = supervisor['phone'] ?? '';
      _workplaceNameController.text = supervisor['organization'] ?? '';
      _supervisorSuggestions = [];
    });
    FocusScope.of(context).unfocus();
    showNote(context, '${supervisor['full_name'] ?? 'Supervisor'} linked as your supervisor');
  }

  /// Typing in the name field again drops the link and searches afresh.
  void _onSupervisorNameChanged(String value) {
    if (_selectedSupervisorId != null) {
      setState(() {
        _selectedSupervisorId = null;
        _linkedSupervisor = null;
      });
    }
    _searchSupervisors(value);
  }

  int _calculateDuration() {
    if (_selectedStartDate != null && _selectedEndDate != null) {
      return _selectedEndDate!.difference(_selectedStartDate!).inDays;
    }
    return 0;
  }

  Future<void> _saveInternshipDetails() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final studentId = widget.userData['role_data']['user_id'];

      final result = await RequestService.updateStudentInternshipDates(
        studentId,
        apiDay(_selectedStartDate!),
        apiDay(_selectedEndDate!),
        workplaceName: _workplaceNameController.text.trim(),
        workplaceAddress: _workplaceAddressController.text.trim(),
        workplaceLocation: _workplaceLocationController.text.trim(),
        supervisorId: _selectedSupervisorId,
        supervisorName: _supervisorNameController.text.trim(),
        supervisorPhone: _supervisorPhoneController.text.trim(),
        supervisorEmail: _supervisorEmailController.text.trim(),
      );
      if (!mounted) return;

      if (result != null && result['status'] == 'success') {
        // Keep the stored session in step with what the server saved.
        final updatedData = result['data'];
        final roleData = widget.userData['role_data'];
        for (final key in const [
          'internship_start_date',
          'internship_end_date',
          'is_first_login',
          'workplace_name',
          'workplace_address',
          'workplace_location',
          'supervisor_id',
          'supervisor_name',
          'supervisor_phone',
          'supervisor_email',
        ]) {
          roleData[key] = updatedData[key];
        }

        await RequestService.saveUserData(widget.userData);
        if (!mounted) return;

        showNote(context, 'Internship details saved');
        RoleRouter.navigateToRoleBasedHome(context, 'student');
      } else {
        showNote(context, result?['message'] ?? 'Could not save your details', error: true);
      }
    } catch (_) {
      if (!mounted) return;
      showNote(context, 'Could not save your details. Check your connection and try again.', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = _calculateDuration();
    final firstName = firstNameOf(widget.userData['full_name']?.toString());

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        bottomNavigationBar: BottomAction(
          child: PrimaryButton(label: 'Save and continue', onPressed: _saveInternshipDetails, busy: _isLoading),
        ),
        body: SafeArea(
          bottom: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.xxl, Space.page, Space.xxl),
              children: [
                Text(firstName.isEmpty ? 'Welcome' : 'Welcome, $firstName', style: Txt.displayStyle),
                const SizedBox(height: Space.xs),
                Text(
                  'Add your internship dates, workplace and supervisor before you start your logbook. '
                  'You can change them later in Settings.',
                  style: Txt.smallStyle,
                ),

                _heading('Internship period'),
                const Rule(),
                const SizedBox(height: Space.lg),
                _dateField('Start date', _startDateController, _selectStartDate),
                _dateField('End date', _endDateController, _selectEndDate),
                if (duration > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: Text(
                      '${plural(duration, 'day')} · ${plural((duration / 7).floor(), 'week')}',
                      style: Txt.mono(Txt.small, color: Palette.inkSoft),
                    ),
                  ),

                _heading('Workplace'),
                const Rule(),
                const SizedBox(height: Space.lg),
                _field(
                  'Company name',
                  _workplaceNameController,
                  hint: 'Where you are doing your SIWES',
                  validator: (v) => _required(v, 'Enter the company name'),
                ),
                _field(
                  'Location',
                  _workplaceLocationController,
                  hint: 'e.g. Ikeja, Lagos',
                  validator: (v) => _required(v, 'Enter the company location'),
                ),
                _field(
                  'Address',
                  _workplaceAddressController,
                  hint: 'Street address',
                  maxLines: 2,
                  validator: (v) => _required(v, 'Enter the company address'),
                ),

                _heading('Workplace supervisor'),
                const Rule(),
                const SizedBox(height: Space.md),
                Text(
                  'Start typing their name. If they already use SIWES360, choose them from the list '
                  'to link your logbook to their account.',
                  style: Txt.smallStyle,
                ),
                const SizedBox(height: Space.lg),
                _field(
                  'Name',
                  _supervisorNameController,
                  hint: 'Full name',
                  onChanged: _onSupervisorNameChanged,
                  validator: (v) => _required(v, "Enter your supervisor's name"),
                  bottom: Space.sm,
                ),
                _supervisorResults(),
                const SizedBox(height: Space.lg),
                _field(
                  'Email',
                  _supervisorEmailController,
                  hint: 'name@company.com',
                  keyboardType: TextInputType.emailAddress,
                  mono: true,
                  optional: true,
                  validator: (v) {
                    if (v != null && v.isNotEmpty && !v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                _field(
                  'Phone',
                  _supervisorPhoneController,
                  hint: '0800 000 0000',
                  keyboardType: TextInputType.phone,
                  mono: true,
                  optional: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Search results under the name field, or the linked supervisor once one is picked.
  Widget _supervisorResults() {
    if (_isSearching) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: Space.sm),
            Text('Searching', style: Txt.smallStyle),
          ],
        ),
      );
    }

    if (_supervisorSuggestions.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Rule(),
          for (final supervisor in _supervisorSuggestions)
            LedgerRow(
              padding: const EdgeInsets.symmetric(vertical: Space.md),
              showChevron: false,
              onTap: () => _selectSupervisor(supervisor),
              trailing: Text('Link', style: Txt.sans(Txt.small, weight: FontWeight.w600, color: Palette.navy)),
              child: _supervisorDetails(supervisor),
            ),
        ],
      );
    }

    final linked = _linkedSupervisor;
    if (_selectedSupervisorId != null && linked != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Rule(),
          LedgerRow(
            padding: const EdgeInsets.symmetric(vertical: Space.md),
            trailing: const Icon(Icons.check_outlined, size: 20, color: Palette.olive),
            child: _supervisorDetails(linked),
          ),
          const SizedBox(height: Space.xs),
          Text('Linked to their SIWES360 account', style: Txt.sans(Txt.small, color: Palette.olive)),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _supervisorDetails(Map<String, dynamic> supervisor) {
    final organisation = '${supervisor['organization'] ?? ''}';
    final email = '${supervisor['email'] ?? ''}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${supervisor['full_name'] ?? ''}', style: Txt.sans(Txt.body, weight: FontWeight.w500)),
        if (organisation.isNotEmpty) Text(organisation, style: Txt.smallStyle),
        if (email.isNotEmpty) Text(email, style: Txt.mono(Txt.small, color: Palette.inkSoft)),
      ],
    );
  }

  static String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  Widget _heading(String text) => SectionLabel(text, padding: const EdgeInsets.only(top: Space.xl, bottom: Space.sm));

  Widget _label(String label, {bool optional = false}) {
    return Row(
      children: [
        Text(label.toUpperCase(), style: Txt.labelStyle),
        if (optional) ...[
          const SizedBox(width: Space.sm),
          Text('optional', style: Txt.sans(Txt.label, color: Palette.inkFaint)),
        ],
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool mono = false,
    bool optional = false,
    double bottom = Space.lg,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label, optional: optional),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: mono ? Txt.mono(Txt.body) : Txt.bodyStyle,
            decoration: InputDecoration(hintText: hint),
            validator: validator,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, TextEditingController controller, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            style: Txt.mono(Txt.body),
            decoration: const InputDecoration(
              hintText: 'Choose a date',
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Choose a date' : null,
          ),
        ],
      ),
    );
  }
}
