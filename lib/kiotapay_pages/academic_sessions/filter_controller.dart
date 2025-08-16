import 'package:get/get.dart';
import 'package:kiotapay/utils/dio_helper.dart';
import '../../globalclass/kiotapay_constants.dart';
import 'student_academic_session_model.dart';

class FilterController extends GetxController {
  final sessions = <StudentAcademicSession>[].obs;
  final selectedSession = Rxn<StudentAcademicSession>();
  final selectedTerm = Rxn<Term>();

  final isLoading = false.obs;

  Future<void> fetchSessions(int studentId) async {
    isLoading.value = true;

    try {
      final String url = KiotaPayConstants.getStudentAcademicSessions.replaceAll(':student_id', studentId.toString());

      final response = await DioHelper().get(url);

      if (response.statusCode == 200) {
        final List data = response.data['data'];
        sessions.value = data
            .map((item) => StudentAcademicSession.fromJson(item))
            .toList();

        // Select session where academic_session.status is "active"
        selectedSession.value = sessions.firstWhereOrNull(
              (s) => s.status.toLowerCase() == 'active',
        );

        selectedTerm.value = selectedSession.value?.terms.firstWhereOrNull(
              (t) => t.id == selectedSession.value?.termId,
        );
      } else {
        Get.snackbar('Error', 'Failed to load academic sessions');
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong');
      print(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void setSelectedSession(StudentAcademicSession session) {
    selectedSession.value = session;
    selectedTerm.value = session.terms.firstWhereOrNull((t) => t.id == session.termId);
  }

  void setSelectedTerm(Term term) {
    selectedTerm.value = term;
  }
}
