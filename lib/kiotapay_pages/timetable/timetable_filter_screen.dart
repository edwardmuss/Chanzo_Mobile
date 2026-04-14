import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

import '../../globalclass/chanzo_color.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../utils/dio_helper.dart';
import '../../widgets/class_stream_selector.dart';
import '../kiotapay_authentication/AuthController.dart';
import 'timetable_screen.dart';

class TimetableFilterScreen extends StatefulWidget {
  const TimetableFilterScreen({super.key});

  @override
  State<TimetableFilterScreen> createState() => _TimetableFilterScreenState();
}

class _TimetableFilterScreenState extends State<TimetableFilterScreen> {
  final AuthController authController = Get.find<AuthController>();

  List<dynamic> _apiClasses = [];
  bool _isLoading = true;

  // Variables to hold the final selection
  int? finalClassId;
  int? finalStreamId;
  String? finalClassName;
  String? finalStreamName;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    // Get the active branch ID safely (fallback to main school ID if needed)
    final branchId = authController.activeBranchId ?? authController.user['branch_id'];

    if (branchId == null) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'No active school branch found.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      // Fetch classes based on the branch ID endpoint you provided
      // Adjust the endpoint path if your KiotaPayConstants defines it differently
      final response = await DioHelper().get('${KiotaPayConstants.baseUrl}classes/$branchId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _apiClasses = response.data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch classes');
      }
    } on DioException catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Network Error',
        e.response?.data['message'] ?? 'Failed to connect to server.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ChanzoColors.secondary,
        colorText: Colors.white,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Something went wrong while loading classes.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Helper method to extract the names based on the selected IDs
  void _updateSelectedNames(int? classId, int? streamId) {
    String? cName;
    String? sName;

    if (classId != null) {
      final selectedClass = _apiClasses.firstWhere((c) => c['id'] == classId, orElse: () => null);
      if (selectedClass != null) {
        cName = selectedClass['name'];

        if (streamId != null && selectedClass['streams'] != null) {
          final selectedStream = (selectedClass['streams'] as List)
              .firstWhere((s) => s['id'] == streamId, orElse: () => null);
          if (selectedStream != null) {
            sName = selectedStream['name'];
          }
        }
      }
    }

    setState(() {
      finalClassName = cName;
      finalStreamName = sName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Class"),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _apiClasses.isEmpty
          ? _buildEmptyState()
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "View Class Timetable",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please select a class and stream to view or manage its weekly timetable.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // --- PLUG IN THE REUSABLE WIDGET HERE ---
            ClassStreamSelector(
              classes: _apiClasses,
              onChanged: (classId, streamId) {
                setState(() {
                  finalClassId = classId;
                  finalStreamId = streamId;
                });
                _updateSelectedNames(classId, streamId);
              },
            ),
            // -----------------------------------------

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChanzoColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                  ),
                  elevation: 2,
                ),
                onPressed: (finalClassId != null && finalStreamId != null)
                    ? () {
                  // Navigate and pass the names so the Timetable App Bar looks good!
                  Get.to(() => TimetableScreen(
                    classId: finalClassId!,
                    streamId: finalStreamId,
                    className: finalClassName ?? 'Class',
                    streamName: finalStreamName ?? 'Stream',
                  ));
                }
                    : null, // Disabled until both are selected
                child: const Text(
                    "View Timetable",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No Classes Found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            "There are no classes configured for this school.",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}