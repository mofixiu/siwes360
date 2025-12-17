import 'package:flutter/material.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/utils/role_router.dart';
import 'package:siwes360/widgets/customButton.dart';

class FirstLoginSetup extends StatefulWidget {
  final Map<String, dynamic> userData;

  const FirstLoginSetup({super.key, required this.userData});

  @override
  State<FirstLoginSetup> createState() => _FirstLoginSetupState();
}

class _FirstLoginSetupState extends State<FirstLoginSetup> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _workplaceNameController =
      TextEditingController();
  final TextEditingController _workplaceAddressController =
      TextEditingController();
  final TextEditingController _workplaceLocationController =
      TextEditingController();
  final TextEditingController _supervisorNameController =
      TextEditingController();
  final TextEditingController _supervisorPhoneController =
      TextEditingController();
  final TextEditingController _supervisorEmailController =
      TextEditingController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _isLoading = false;
  List<Map<String, dynamic>> _supervisorSuggestions = [];
  bool _isSearching = false;

  // ADD THIS: Track selected supervisor_id
  int? _selectedSupervisorId;

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

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0A3D62),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
        _startDateController.text = _formatDate(picked);

        if (_selectedEndDate != null && _selectedEndDate!.isBefore(picked)) {
          _selectedEndDate = null;
          _endDateController.clear();
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start date first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate!.add(const Duration(days: 180)),
      firstDate: _selectedStartDate!.add(const Duration(days: 1)),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0A3D62),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
        _endDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _searchSupervisors(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _supervisorSuggestions = [];
        // MODIFIED: Clear supervisor_id when clearing search
        if (query.isEmpty) {
          _selectedSupervisorId = null;
        }
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final result = await RequestService.searchSupervisors(query);

      if (result != null && result['status'] == 'success') {
        setState(() {
          _supervisorSuggestions = List<Map<String, dynamic>>.from(
            result['data'] ?? [],
          );
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectSupervisor(Map<String, dynamic> supervisor) {
    setState(() {
      // MODIFIED: Capture the supervisor_id (which is user_id in supervisors table)
      _selectedSupervisorId = supervisor['user_id'];

      _supervisorNameController.text = supervisor['full_name'] ?? '';
      _supervisorEmailController.text = supervisor['email'] ?? '';
      _supervisorPhoneController.text = supervisor['phone'] ?? '';
      _workplaceNameController.text = supervisor['organization'] ?? '';
      _supervisorSuggestions = [];
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Supervisor "${supervisor['full_name']}" linked!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // MODIFIED: Clear supervisor_id when manually editing
  void _onSupervisorNameChanged(String value) {
    // If user starts typing again, clear the selected supervisor_id
    if (_selectedSupervisorId != null) {
      setState(() {
        _selectedSupervisorId = null;
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

    setState(() {
      _isLoading = true;
    });

    try {
      final studentId = widget.userData['role_data']['user_id'];

      // Format dates as YYYY-MM-DD
      final startDateFormatted = _selectedStartDate!.toIso8601String().split(
        'T',
      )[0];
      final endDateFormatted = _selectedEndDate!.toIso8601String().split(
        'T',
      )[0];

      final result = await RequestService.updateStudentInternshipDates(
        studentId,
        startDateFormatted,
        endDateFormatted,
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
        // Update local user data with the response from backend
        final updatedData = result['data'];

        widget.userData['role_data']['internship_start_date'] =
            updatedData['internship_start_date'];
        widget.userData['role_data']['internship_end_date'] =
            updatedData['internship_end_date'];
        widget.userData['role_data']['is_first_login'] =
            updatedData['is_first_login']; // Use value from backend
        widget.userData['role_data']['workplace_name'] =
            updatedData['workplace_name'];
        widget.userData['role_data']['workplace_address'] =
            updatedData['workplace_address'];
        widget.userData['role_data']['workplace_location'] =
            updatedData['workplace_location'];
        widget.userData['role_data']['supervisor_id'] =
            updatedData['supervisor_id'];
        widget.userData['role_data']['supervisor_name'] =
            updatedData['supervisor_name'];
        widget.userData['role_data']['supervisor_phone'] =
            updatedData['supervisor_phone'];
        widget.userData['role_data']['supervisor_email'] =
            updatedData['supervisor_email'];

        // Save updated user data to storage
        await RequestService.saveUserData(widget.userData);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internship details saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to dashboard
        RoleRouter.navigateToRoleBasedHome(context, 'student');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['message'] ?? 'Failed to save details'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = _calculateDuration();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Welcome Section
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A3D62).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.work_outline,
                              size: 60,
                              color: Color(0xFF0A3D62),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Welcome, ${widget.userData['full_name']?.split(' ')[0]}!',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A3D62),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Let\'s set up your internship details',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Section: Internship Dates
                    _buildSectionHeader(
                      'Internship Period',
                      Icons.calendar_month,
                    ),
                    const SizedBox(height: 16),

                    _buildDateField(
                      controller: _startDateController,
                      label: 'START DATE',
                      hint: 'Select internship start date',
                      onTap: _selectStartDate,
                    ),

                    const SizedBox(height: 16),

                    _buildDateField(
                      controller: _endDateController,
                      label: 'END DATE',
                      hint: 'Select proposed end date',
                      onTap: _selectEndDate,
                    ),

                    if (duration > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Duration: $duration days (${(duration / 7).floor()} weeks)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0A3D62),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Section: Workplace Information
                    _buildSectionHeader(
                      'Workplace Information',
                      Icons.business,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _workplaceNameController,
                      label: 'COMPANY/ORGANIZATION NAME',
                      hint: 'Enter company name',
                      icon: Icons.business_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter workplace name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _workplaceLocationController,
                      label: 'LOCATION/CITY',
                      hint: 'e.g., Lagos, Nigeria',
                      icon: Icons.location_city_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter workplace location';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _workplaceAddressController,
                      label: 'FULL ADDRESS',
                      hint: 'Enter complete address',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter workplace address';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Section: Industry Supervisor
                    _buildSectionHeader(
                      'Industry Supervisor',
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 8),

                    // ADDED: Supervisor linking status indicator
                    if (_selectedSupervisorId != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.link,
                              color: Colors.green[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Supervisor linked from database',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[700],
                              size: 20,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    _buildTextField(
                      controller: _supervisorNameController,
                      label: 'SUPERVISOR NAME',
                      hint: 'Start typing to search...',
                      icon: Icons.person_search_outlined,
                      onChanged: _onSupervisorNameChanged, // MODIFIED
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter supervisor name';
                        }
                        return null;
                      },
                    ),

                    // Supervisor Search Results
                    if (_supervisorSuggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: _supervisorSuggestions.map((supervisor) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF0A3D62),
                                child: Text(
                                  (supervisor['full_name'] ?? 'S')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                supervisor['full_name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${supervisor['position']} at ${supervisor['organization']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: const Icon(
                                Icons.link,
                                color: Color(0xFF0A3D62),
                              ),
                              onTap: () => _selectSupervisor(supervisor),
                            );
                          }).toList(),
                        ),
                      ),

                    if (_isSearching)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0A3D62),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Searching supervisors...',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _supervisorEmailController,
                      label: 'SUPERVISOR EMAIL',
                      hint: 'supervisor@company.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!value.contains('@')) {
                            return 'Please enter valid email';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _supervisorPhoneController,
                      label: 'SUPERVISOR PHONE',
                      hint: '+234 XXX XXX XXXX',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    CustomButton(
                      ontap: _isLoading ? () {} : _saveInternshipDetails,
                      data: _isLoading ? "Saving..." : "Submit",
                      textcolor: Colors.white,
                      backgroundcolor: _isLoading
                          ? Colors.grey
                          : const Color(0xFF0A3D62),
                      width: MediaQuery.of(context).size.width,
                      height: 50,
                    ),

                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: CircularProgressIndicator(
                            color: Color(0xFF0A3D62),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A3D62),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select date';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF0A3D62),
                size: 20,
              ),
              suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines ?? 1,
            validator: validator,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(icon, color: const Color(0xFF0A3D62), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
