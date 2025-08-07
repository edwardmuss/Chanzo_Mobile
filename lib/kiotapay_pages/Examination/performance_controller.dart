import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:kiotapay/globalclass/global_methods.dart';
import 'package:kiotapay/kiotapay_pages/Examination/student_performance_trend_model.dart';
import 'package:kiotapay/utils/dio_helper.dart';
import 'package:path_provider/path_provider.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../utils/pdf_viewer_screen.dart';
import 'student_performance_model.dart';
import 'package:http/http.dart' as http;

class PerformanceController extends GetxController {
  final data = Rxn<StudentPerformance>();
  final trend_data = Rxn<StudentPerformanceTrend>();
  final isLoading = false.obs;

  final String _cacheKey = 'studentPerformance';
  final String _cacheTrendKey = 'studentPerformanceTrend';

  @override
  void onInit() {
    super.onInit();
    loadPerformance();
  }

  /// Loads student performance from cache or API
  Future<void> loadPerformance({bool refresh = false, int exam_id = 0}) async {
    isLoading.value = true;

    final box = await Hive.openBox(_cacheKey);
    final studentId = authController.selectedStudentId;
    final dynamicKey = '${_cacheKey}_$studentId';

    if (!refresh && box.containsKey(_cacheKey)) {
      try {
        final json = box.get(dynamicKey) as Map<String, dynamic>;
        data.value = StudentPerformance.fromJson(json);
        isLoading.value = false;
        return;
        // final json = Map<String, dynamic>.from(box.get(_cacheKey));
        // data.value = StudentPerformance.fromJson(json);
      } catch (e) {
        // In case cached data is malformed
        box.delete(_cacheKey);
      } finally {
        isLoading.value = false;
      }
      return;
    }

    try {
      final response = await DioHelper().get(
        KiotaPayConstants.getStudentPerformance,
        queryParameters: {
          'student_id': authController.selectedStudentId,
          if (exam_id != 0) 'exam_id': exam_id,
        },
      );
      if (response.statusCode == 200) {
        final perf = StudentPerformance.fromJson(response.data);
        data.value = perf;
        await box.put(dynamicKey, response.data['data']);
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to load performance data');
      }
    } catch (e) {
      Get.snackbar('Error', "Error loading performance");
      print("❌ Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Loads student performance Trend from cache or API
  Future<void> loadStudentExamTrend({bool refresh = false, int academic_session_id = 0}) async {
    isLoading.value = true;

    final box = await Hive.openBox(_cacheTrendKey);
    final studentId = authController.selectedStudentId;
    final academic_session_id = authController.currentAcademicSessionID;
    final dynamicKey = '${_cacheTrendKey}_$studentId';

    // Load from cache
    if (!refresh && box.containsKey(dynamicKey)) {
      try {
        final cachedJson = box.get(dynamicKey) as Map<String, dynamic>;
        trend_data.value = StudentPerformanceTrend.fromJson({'data': cachedJson});
        return;
      } catch (e) {
        await box.delete(dynamicKey);
      } finally {
        isLoading.value = false;
      }
    }

    // Load from API
    try {
      final response = await DioHelper().get(
        KiotaPayConstants.getStudentExamTrend,
        queryParameters: {
          'student_id': studentId,
          if (academic_session_id != 0) 'academic_session_id': academic_session_id,
        },
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final trend = StudentPerformanceTrend.fromJson(response.data);
        trend_data.value = trend;

        await box.put(dynamicKey, response.data['data']); // only the data part
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to load performance data');
      }
    } catch (e) {
      Get.snackbar('Error', "Error loading performance trend");
      print("❌ Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Public method to refetch performance data, bypassing cache
  Future<void> refreshData() async {
    await loadPerformance(refresh: true);
    await loadStudentExamTrend(refresh: true);
  }

  /// Public method to load student performance
  Future<void> downloadExamReports(BuildContext context,{
    required int studentId,
    required int academicSessionId,
    int? termId,
    String? reportType,
  }) async {
    final token = await storage.read(key: 'token');
    if (token == null) throw Exception('No authentication token found');

    try {
      EasyLoading.show(status: 'Generating Results...');

      final params = <String, String>{};

      if (academicSessionId > 0) {
        params['academic_session_id'] = academicSessionId.toString();
      }

      if (termId != null) {
        params['term_id'] = termId.toString();
      }

      if (reportType != null) {
        params['report_type'] = 'combined';
      }

      final String url = KiotaPayConstants.getStudentExamReport.replaceAll(':student_id', studentId.toString());
      final uri = Uri.parse(url).replace(
        queryParameters: params.isNotEmpty ? params : null,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filename = '${reportType}_${studentId.toString().padLeft(4, '0')}_${DateFormat('dd-MM-yyyy-Hms').format(DateTime.now())}.pdf';
        final file = File('${directory.path}/$filename');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        // Open PDF in custom viewer
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(filePath: file.path, title: "${capitalize(reportType!)} Results"),
          ),
        );
      } else {
        throw Exception('Server responded with ${response.statusCode}');
      }
    } catch (e) {
      EasyLoading.showError('Download failed: ${e.toString()}');
      rethrow;
    } finally {
      EasyLoading.dismiss();
    }
  }
}

String capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
