import 'package:chanzo/globalclass/global_methods.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../utils/dio_helper.dart';

class TeacherDashboardController extends GetxController {
  var isLoading = true.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Raw data
  var branchName = ''.obs;
  var rawDashboardData = <dynamic>[].obs;

  // Categorized data
  var classOverviews = <dynamic>[].obs;
  var subjectPerformances = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    isLoading(true);
    hasError(false);

    try {
      final current = authController.activeContext.value;
      final response = await DioHelper().get(
        KiotaPayConstants.teachersDashboard,
        queryParameters: current?.branchId != null
            ? {'branch_id': current!.branchId}
            : null,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        branchName.value = data['branch_name'] ?? '';
        final dashboardList = data['dashboard'] as List<dynamic>? ?? [];

        rawDashboardData.assignAll(dashboardList);

        // Filter the data into distinct lists for the UI
        classOverviews.assignAll(
            dashboardList.where((item) => item['type'] == 'class_teacher').toList()
        );

        subjectPerformances.assignAll(
            dashboardList.where((item) => item['type'] == 'class_teacher_subject').toList()
        );

      } else {
        hasError(true);
        errorMessage.value = response.data['message'] ?? 'Failed to load dashboard.';
      }
    } on DioException catch (e) {
      hasError(true);
      errorMessage.value = e.response?.data['message'] ?? 'Network error occurred.';
    } catch (e) {
      hasError(true);
      errorMessage.value = 'An unexpected error occurred.';
    } finally {
      isLoading(false);
    }
  }
}