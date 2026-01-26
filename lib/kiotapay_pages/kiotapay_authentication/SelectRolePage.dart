import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'BranchContext.dart';
import 'ConfirmSwitchAndGo.dart';

class SelectRolePage extends StatelessWidget {
  final BranchContext branch;
  const SelectRolePage({super.key, required this.branch});

  IconData _roleIcon(String role) {
    final r = role.toLowerCase();
    if (r.contains('parent')) return Icons.family_restroom;
    if (r.contains('teacher')) return Icons.school;
    if (r.contains('admin')) return Icons.admin_panel_settings;
    if (r.contains('bursar') || r.contains('finance')) return Icons.payments;
    return Icons.badge;
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Role'),
              Text(branch.branchName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
            ],
          ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: branch.roles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final role = branch.roles[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Get.to(() => ConfirmSwitchAndGo(
              branchId: branch.branchId,
              role: role,
              branchName: branch.branchName,
            )),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    child: Icon(_roleIcon(role)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleCase(role),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Continue as ${_titleCase(role)}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade600),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
