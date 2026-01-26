import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../globalclass/choose_student_page.dart';
import '../kiotapay_dahsboard/kiotapay_dahsboard.dart';
import 'AuthController.dart';
import 'BranchContext.dart';

class ConfirmSwitchAndGo extends StatefulWidget {
  final int branchId;
  final String role;
  final String branchName;

  const ConfirmSwitchAndGo({
    super.key,
    required this.branchId,
    required this.role,
    required this.branchName,
  });

  @override
  State<ConfirmSwitchAndGo> createState() => _ConfirmSwitchAndGoState();
}

class _ConfirmSwitchAndGoState extends State<ConfirmSwitchAndGo> {
  final auth = Get.find<AuthController>();
  bool loading = false;

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  IconData _roleIcon(String role) {
    final r = role.toLowerCase();
    if (r.contains('parent')) return Icons.family_restroom;
    if (r.contains('teacher')) return Icons.school;
    if (r.contains('admin')) return Icons.admin_panel_settings;
    if (r.contains('bursar') || r.contains('finance')) return Icons.payments;
    return Icons.badge;
  }

  Future<void> _continue() async {
    if (loading) return;

    setState(() => loading = true);

    try {
      final updated = await auth.switchContextOnServer(
        branchId: widget.branchId,
        role: widget.role,
      );
      final d = Map<String, dynamic>.from(updated['data'] ?? {});

      // active context
      if (d['current_context'] != null) {
        auth.activeContext.value =
            ActiveContext.fromJson(Map<String, dynamic>.from(d['current_context']));
      } else {
        auth.activeContext.value = ActiveContext(
          branchId: widget.branchId,
          role: widget.role,
          branchName: widget.branchName,
        );
      }
      auth.ensureSelectedStudentInActiveBranch();

      // branch-bound data
      if (d['school'] != null) auth.setSchool(Map<String, dynamic>.from(d['school']));
      if (d['current_academic_session'] != null) {
        auth.setCurrentAcademicSession(Map<String, dynamic>.from(d['current_academic_session']));
      }
      if (d['current_academic_term'] != null) {
        auth.setCurrentAcademicTerm(Map<String, dynamic>.from(d['current_academic_term']));
      }

      // permissions/roles
      if (d['roles'] != null) auth.setRoles(List<String>.from(d['roles']));
      if (d['permissions'] != null) auth.setPermissions(List<String>.from(d['permissions']));

      // Parent: after switching branch, pick a student in that branch
      if (auth.userRole == 'parent' && auth.allStudents.isNotEmpty) {
        final activeBranch = auth.activeContext.value?.branchId;
        final inBranch = auth.allStudents.where((s) => s['branch_id'] == activeBranch).toList();

        setState(() => loading = false);

        if (inBranch.length == 1) {
          auth.setSelectedStudent(inBranch.first);
          Get.offAll(() => KiotaPayDashboard('0'));
          return;
        } else if (inBranch.isNotEmpty) {
          Get.offAll(() => ChooseStudentPage());
          return;
        }
      }

      setState(() => loading = false);
      Get.offAll(() => KiotaPayDashboard('0'));
    } catch (e) {
      setState(() => loading = false);
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = _titleCase(widget.role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Context'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    child: Icon(_roleIcon(widget.role)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.branchName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Role: $roleLabel',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tip text
            Text(
              'You can change this later from the switcher.',
              style: TextStyle(color: Colors.grey.shade700),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : _continue,
                child: loading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                )
                    : const Text('Continue'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: loading ? null : () => Get.back(),
              child: const Text('Choose another branch/role'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
