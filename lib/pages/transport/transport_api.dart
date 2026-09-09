import 'package:dio/dio.dart';

import '../../globalclass/constants.dart';
import '../../utils/dio_helper.dart';

/// Every transport call the app makes, in one place.
///
/// The server decides the wording and the menu, not this file. `profile()`
/// says whether the signed-in person is a parent, crew, or both, and the run
/// payload carries its own button labels — because the same three marks mean
/// opposite places on the two legs, and the phone is the wrong place to decide
/// whether getting off means school or home.
class TransportApi {
  static final DioHelper _dio = DioHelper();

  static String get _base => '${KiotaPayConstants.baseUrl}transport';

  // ---------------------------------------------------------------- profile

  static Future<Map<String, dynamic>> profile() async {
    final res = await _dio.get('$_base/me');
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  // ----------------------------------------------------------------- parent

  static Future<List<Map<String, dynamic>>> myChildren() async {
    final res = await _dio.get('$_base/my/children');
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  static Future<Map<String, dynamic>> childHistory(int studentId) async {
    final res = await _dio.get('$_base/my/children/$studentId/history');
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  // ------------------------------------------------------------------- crew

  static Future<List<Map<String, dynamic>>> myRuns({String? date}) async {
    final res = await _dio.get(
      '$_base/crew/runs',
      queryParameters: date == null ? null : {'date': date},
    );
    return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
  }

  static Future<Map<String, dynamic>> startRun({
    required int tripId,
    required String leg,
    double? odometer,
  }) async {
    final res = await _dio.post('$_base/crew/runs/start', data: {
      'trip_id': tripId,
      'leg': leg,
      if (odometer != null) 'odometer': odometer,
    });
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  static Future<Map<String, dynamic>> run(int runId) async {
    final res = await _dio.get('$_base/crew/runs/$runId');
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  static Future<String> mark({
    required int runId,
    required int studentId,
    required String eventType,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _dio.post('$_base/crew/runs/$runId/mark', data: {
      'student_id': studentId,
      'event_type': eventType,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    return res.data['message']?.toString() ?? 'Saved';
  }

  static Future<String> markBulk({
    required int runId,
    required String eventType,
    List<int>? studentIds,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _dio.post('$_base/crew/runs/$runId/mark-bulk', data: {
      'event_type': eventType,
      if (studentIds != null) 'student_ids': studentIds,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    return res.data['message']?.toString() ?? 'Saved';
  }

  static Future<String> completeRun(int runId, {double? odometer}) async {
    final res = await _dio.post('$_base/crew/runs/$runId/complete', data: {
      'mark_absent': 1,
      if (odometer != null) 'odometer': odometer,
    });
    return res.data['message']?.toString() ?? 'Run closed';
  }

  /// Best-effort. A lost fix on a Kenyan road is normal and the next one is
  /// thirty seconds away, so this never throws at the caller.
  static Future<bool> position({
    required int runId,
    required double latitude,
    required double longitude,
    double? speedKph,
    double? heading,
    double? accuracyM,
  }) async {
    try {
      await _dio.post('$_base/crew/runs/$runId/position', data: {
        'latitude': latitude,
        'longitude': longitude,
        if (speedKph != null) 'speed_kph': speedKph,
        if (heading != null) 'heading': heading,
        if (accuracyM != null) 'accuracy_m': accuracyM,
      });
      return true;
    } on DioException {
      return false;
    }
  }

  /// The server's own words for a failure, when it sent any.
  static String errorText(Object e, [String fallback = 'Something went wrong.']) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
    }
    return fallback;
  }
}
