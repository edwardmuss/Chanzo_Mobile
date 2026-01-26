import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../globalclass/choose_student_page.dart';
import 'AuthController.dart';
import 'BranchContext.dart';
import 'SelectRolePage.dart';
import '../kiotapay_dahsboard/kiotapay_dahsboard.dart';

class SelectBranchPage extends StatelessWidget {
  SelectBranchPage({super.key});

  final auth = Get.find<AuthController>();
  final query = ''.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Branch'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search branch...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => query.value = v.trim().toLowerCase(),
            ),
          ),
        ),
      ),
      body: Obx(() {
        final branches = auth.availableContexts.where((b) {
          final q = query.value;
          if (q.isEmpty) return true;
          return b.branchName.toLowerCase().contains(q);
        }).toList();

        if (branches.isEmpty) {
          return const Center(child: Text('No branches found'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: branches.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final b = branches[i];
            final current = auth.activeContext.value;
            final isCurrent = (current?.branchId == b.branchId);

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                // If multiple roles, go pick role
                if (b.roles.length > 1) {
                  Get.to(() => SelectRolePage(branch: b));
                  return;
                }

                // Single role -> switch immediately
                final role = b.roles.first;
                await _switchAndRoute(
                  context: context,
                  branchId: b.branchId,
                  role: role,
                  branchName: b.branchName,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                  ),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      child: Text(
                        b.branchName.isNotEmpty ? b.branchName[0].toUpperCase() : '?',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  b.branchName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                  ),
                                  child: Text(
                                    'Current',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            b.roles.length == 1 ? 'Role: ${b.roles.first}' : '${b.roles.length} roles available',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      b.roles.length == 1 ? Icons.chevron_right : Icons.admin_panel_settings_outlined,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Future<void> _switchAndRoute({
    required BuildContext context,
    required int branchId,
    required String role,
    required String branchName,
  }) async {
    final overlay = _showBlockingLoader(context, 'Switching to $branchName...');

    try {
      final updated = await auth.switchContextOnServer(branchId: branchId, role: role);
      final d = Map<String, dynamic>.from(updated['data'] ?? {});

      // Update controller
      if (d['current_context'] != null) {
        auth.activeContext.value =
            ActiveContext.fromJson(Map<String, dynamic>.from(d['current_context']));
      } else {
        auth.activeContext.value =
            ActiveContext(branchId: branchId, role: role, branchName: branchName);
      }

      if (d['school'] != null) auth.setSchool(Map<String, dynamic>.from(d['school']));
      if (d['current_academic_session'] != null) {
        auth.setCurrentAcademicSession(Map<String, dynamic>.from(d['current_academic_session']));
      }
      if (d['current_academic_term'] != null) {
        auth.setCurrentAcademicTerm(Map<String, dynamic>.from(d['current_academic_term']));
      }
      if (d['roles'] != null) auth.setRoles(List<String>.from(d['roles']));
      if (d['permissions'] != null) auth.setPermissions(List<String>.from(d['permissions']));

      // Parent: pick student in this branch
      if (auth.userRole == 'parent' && auth.allStudents.isNotEmpty) {
        final inBranch = auth.allStudents.where((s) => s['branch_id'] == branchId).toList();
        overlay.remove();

        if (inBranch.length == 1) {
          auth.setSelectedStudent(inBranch.first);
          Get.offAll(() => KiotaPayDashboard('0'));
        } else {
          Get.offAll(() => ChooseStudentPage());
        }
        return;
      }

      overlay.remove();
      Get.offAll(() => KiotaPayDashboard('0'));
    } catch (e) {
      overlay.remove();
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  OverlayEntry _showBlockingLoader(BuildContext context, String message) {
    final entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.25)),
          Center(
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(message)),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(entry);
    return entry;
  }
}
