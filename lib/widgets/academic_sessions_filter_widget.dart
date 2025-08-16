import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../kiotapay_pages/academic_sessions/filter_controller.dart';
import '../kiotapay_pages/academic_sessions/student_academic_session_model.dart';

class AcademicFilterWidget extends StatelessWidget {
  final FilterController controller = Get.find<FilterController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return CircularProgressIndicator();
      }

      return Row(
        children: [
          DropdownButton<StudentAcademicSession>(
            value: controller.selectedSession.value,
            hint: Text("Select Session"),
            onChanged: (value) {
              if (value != null) controller.setSelectedSession(value);
            },
            items: controller.sessions
                .map((session) => DropdownMenuItem(
              value: session,
              child: Text(session.year),
            ))
                .toList(),
          ),
          const SizedBox(width: 16),
          DropdownButton<Term>(
            value: controller.selectedTerm.value,
            hint: Text("Select Term"),
            onChanged: (value) {
              if (value != null) controller.setSelectedTerm(value);
            },
            items: controller.selectedSession.value?.terms
                .map((term) => DropdownMenuItem(
              value: term,
              child: Text("Term ${term.termNumber}"),
            ))
                .toList() ??
                [],
          ),
        ],
      );
    });
  }
}
