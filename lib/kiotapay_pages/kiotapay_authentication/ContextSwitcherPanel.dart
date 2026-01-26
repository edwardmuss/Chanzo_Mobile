import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'AuthController.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../globalclass/kiotapay_icons.dart';
import 'BranchContext.dart';

class ContextSwitcherPanel extends StatelessWidget {
  final Future<void> Function()? onContextChanged;
  final Future<void> Function()? onStudentChanged;

  const ContextSwitcherPanel({
    super.key,
    this.onContextChanged,
    this.onStudentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isLoading = false.obs;

    Future<void> switchContext({
      required int branchId,
      required String role,
      required String branchName,
    }) async {
      if (isLoading.value) return;
      isLoading.value = true;

      try {
        final updated = await auth.switchContextOnServer(branchId: branchId, role: role);
        final d = Map<String, dynamic>.from(updated['data'] ?? {});

        if (d['current_context'] != null) {
          auth.activeContext.value =
              ActiveContext.fromJson(Map<String, dynamic>.from(d['current_context']));
        } else {
          auth.activeContext.value = ActiveContext(
            branchId: branchId,
            role: role,
            branchName: branchName,
          );
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

        auth.ensureSelectedStudentInActiveBranch();
        if (onContextChanged != null) await onContextChanged!();
      } catch (e) {
        Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> switchStudent(Map<String, dynamic> student) async {
      if (isLoading.value) return;
      isLoading.value = true;

      try {
        auth.setSelectedStudent(student);
        auth.isStudentListExpanded.value = false;
        if (onStudentChanged != null) await onStudentChanged!();
      } catch (e) {
        Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
      } finally {
        isLoading.value = false;
      }
    }

    return Obx(() {
      final isParent = auth.userRole == 'parent';
      final current = auth.activeContext.value;
      final contexts = auth.availableContexts;

      return Material(
        elevation: 10,
        color: Colors.white,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isParent ? 'Switch School / Student' : 'Switch Context',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => auth.isStudentListExpanded.value = false,
                      )
                    ],
                  ),

                  if (isParent) ...[
                    // Branches
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Schools', style: TextStyle(color: Colors.grey.shade700)),
                    ),
                    const SizedBox(height: 6),

                    ...contexts.map((b) {
                      final isActive = current?.branchId == b.branchId;
                      return ListTile(
                        dense: true,
                        title: Text(b.branchName),
                        trailing: isActive ? const Icon(Icons.check) : const Icon(Icons.chevron_right),
                        onTap: isActive
                            ? null
                            : () async {
                          final roleSlug = b.roles.isNotEmpty ? b.roles.first : 'parent';
                          await switchContext(
                            branchId: b.branchId,
                            role: roleSlug,
                            branchName: b.branchName,
                          );
                        },
                      );
                    }).toList(),

                    const Divider(),

                    // Students (filtered)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Students', style: TextStyle(color: Colors.grey.shade700)),
                    ),
                    const SizedBox(height: 6),

                    ...auth.studentsInActiveBranch.map((student) {
                      final u = student['user'] ?? {};
                      final isSelected = auth.selectedStudent['id'] == student['id'];
                      final isActiveStudent = auth.isStudentActive(student);

                      return ListTile(
                        dense: true,
                        enabled: isActiveStudent,
                        onTap: !isActiveStudent ? null : () => switchStudent(student),
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            u['avatar'] != null
                                ? '${KiotaPayConstants.webUrl}storage/${u['avatar']}'
                                : KiotaPayPngimage.profile,
                          ),
                        ),
                        title: Text('${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim()),
                        subtitle: Text(student['class']?['name'] ?? 'No class'),
                        trailing: isSelected ? const Icon(Icons.check) : null,
                      );
                    }).toList(),
                  ] else ...[
                    // Non-parent: branch -> role
                    ...contexts.expand((b) => b.roles.map((r) {
                      final isActive = current?.branchId == b.branchId && current?.role == r;
                      return ListTile(
                        dense: true,
                        title: Text(b.branchName),
                        subtitle: Text('Role: $r'),
                        trailing: isActive ? const Icon(Icons.check) : const Icon(Icons.chevron_right),
                        onTap: isActive
                            ? null
                            : () async {
                          await switchContext(
                            branchId: b.branchId,
                            role: r,
                            branchName: b.branchName,
                          );
                        },
                      );
                    })),
                  ],
                ],
              ),
            ),

            if (isLoading.value)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.12),
                  child: const Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
