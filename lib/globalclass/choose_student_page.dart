import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kiotapay/kiotapay_pages/kiotapay_dahsboard/kiotapay_dahsboard.dart';

import '../kiotapay_pages/kiotapay_authentication/AuthController.dart';
import 'chanzo_color.dart';
import 'kiotapay_constants.dart';
import 'kiotapay_icons.dart';

class ChooseStudentPage extends StatelessWidget {
  final authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Select Student'),
        backgroundColor: ChanzoColors.primary,
      ),
      body: Obx(() {
        final students = authController.allStudents;

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Choose Active Student',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ChanzoColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                ...students.map((student) {
                  final studentUser = student['user'];
                  final isActive = authController.isStudentActive(student);

                  return GestureDetector(
                    onTap: () {
                      if (isActive) {
                        authController.setSelectedStudent(student);
                        Get.off(() => KiotaPayDashboard('0'));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${studentUser['first_name']} is inactive and cannot be selected."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          if (isActive)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(
                              studentUser?['avatar'] != null
                                  ? '${KiotaPayConstants.webUrl}storage/${studentUser['avatar']}'
                                  : KiotaPayPngimage.profile,
                            ),
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.grey,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${studentUser?['first_name'] ?? ''} ${studentUser?['middle_name'] ?? ''} ${studentUser?['last_name'] ?? ''}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? Colors.black
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  student['admission_no'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isActive
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: ChanzoColors.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      }),
    );
  }
}
