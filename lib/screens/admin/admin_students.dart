import 'package:flutter/material.dart';
import 'package:siwes360/screens/admin/admin_overview.dart';
import 'package:siwes360/screens/shared/student_list.dart';
import 'package:siwes360/theme/tokens.dart';
import 'package:siwes360/utils/internship_calendar.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/widgets/paper.dart';

/// The institution's students with where each one stands. As a tab, or pushed
/// with a filter (from the overview) or for one supervisor's students.
class AdminStudents extends StatefulWidget {
  const AdminStudents({
    super.key,
    this.initialFilter = StudentFilter.all,
    this.pushed = false,
    this.supervisorId,
    this.supervisorName,
  });

  final StudentFilter initialFilter;
  final bool pushed;
  final int? supervisorId;
  final String? supervisorName;

  @override
  State<AdminStudents> createState() => _AdminStudentsState();
}

class _AdminStudentsState extends State<AdminStudents> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _students = [];
  int _behindAfter = 3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await RequestService.getAdminStudents();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result?['status'] == 'success') {
        _error = null;
        _behindAfter = (result!['data']['rules']?['behind_after_working_days'] as num?)?.toInt() ?? 3;
        _students = List<Map<String, dynamic>>.from((result['data']['students'] as List).map((e) => Map<String, dynamic>.from(e)))
            .where((s) => widget.supervisorId == null || s['supervisor_id'] == widget.supervisorId)
            .toList();
      } else {
        _error = result?['message'] ?? 'Check your connection and try again.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.supervisorName ?? 'Students';
    final content = _loading
        ? const LoadingView()
        : _error != null
            ? ErrorView(message: _error!, onRetry: _load)
            : RefreshIndicator(
                color: Palette.ink,
                onRefresh: _load,
                child: StudentList(
                  students: _students,
                  initialFilter: widget.initialFilter,
                  behindAfter: _behindAfter,
                  header: widget.pushed
                      ? null
                      : PageHeader(
                          title: title,
                          subtitle: Text(plural(_students.length, 'student'), style: Txt.mono(Txt.small, color: Palette.inkSoft)),
                        ),
                ),
              );
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: widget.pushed
            ? AppBar(
                leading: IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                title: Text(widget.supervisorName == null ? title : "$title's students"),
              )
            : null,
        bottomNavigationBar: widget.pushed ? null : const AdminNavBar(currentIndex: 1),
        body: widget.pushed ? content : SafeArea(bottom: false, child: content),
      ),
    );
  }
}
