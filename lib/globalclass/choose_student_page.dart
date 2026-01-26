import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_dahsboard/kiotapay_dahsboard.dart';

import '../kiotapay_pages/kiotapay_authentication/AuthController.dart';
import 'chanzo_color.dart';
import 'kiotapay_constants.dart';
import 'kiotapay_icons.dart';

class ChooseStudentPage extends StatelessWidget {
  final authController = Get.find<AuthController>();

  ChooseStudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Select Student'),
        backgroundColor: ChanzoColors.primary,
        elevation: 0,
      ),
      body: Obx(() {
        final students = authController.studentsInActiveBranch;
        final selectedId = authController.selectedStudent['id'];

        if (students.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No students found for this school.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Title card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: ChanzoColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose Active Student',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authController.schoolName,
                          style: TextStyle(color: Colors.grey.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Student cards
            ...students.map((student) {
              final u = student['user'] ?? {};
              final isActive = authController.isStudentActive(student);
              final isSelected = (selectedId != null && selectedId == student['id']);

              final fullName =
              '${u['first_name'] ?? ''} ${u['middle_name'] ?? ''} ${u['last_name'] ?? ''}'
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();

              final avatar = u['avatar']?.toString();
              final avatarUrl = avatar != null
                  ? '${KiotaPayConstants.webUrl}storage/$avatar'
                  : null;

              return Opacity(
                opacity: isActive ? 1 : 0.55,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? ChanzoColors.primary : Colors.grey.shade200,
                      width: isSelected ? 1.4 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    enabled: isActive && !isSelected,
                    onTap: (!isActive || isSelected)
                        ? null
                        : () {
                      authController.setSelectedStudent(student);
                      Get.off(() => KiotaPayDashboard('0'));
                    },
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    title: Text(
                      fullName.isEmpty ? 'Unnamed student' : fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.black : Colors.grey.shade700,
                      ),
                    ),
                    subtitle: Text(
                      [
                        (student['class']?['name'] ?? '').toString(),
                        (student['admission_no'] ?? '').toString(),
                      ].where((s) => s.trim().isNotEmpty).join(' • '),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    trailing: isSelected
                        ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: ChanzoColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Current',
                        style: TextStyle(
                          color: ChanzoColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    )
                        : Icon(
                      isActive ? Icons.chevron_right : Icons.block,
                      color: isActive ? ChanzoColors.primary : Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      }),
    );
  }
}
