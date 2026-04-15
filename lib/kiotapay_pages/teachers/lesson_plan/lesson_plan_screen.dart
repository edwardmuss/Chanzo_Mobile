import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../globalclass/chanzo_color.dart';
import '../../../globalclass/kiotapay_constants.dart';
import '../../../utils/dio_helper.dart';
import '../../kiotapay_authentication/AuthController.dart';
import '../../../widgets/error.dart';
import '../lesson_plan/add_edit_lesson_plan_screen.dart';
import 'show_lesson_plan_screen.dart';

class LessonPlanScreen extends StatefulWidget {
  const LessonPlanScreen({super.key});

  @override
  State<LessonPlanScreen> createState() => _LessonPlanScreenState();
}

class _LessonPlanScreenState extends State<LessonPlanScreen> {
  final AuthController authController = Get.find<AuthController>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _lessonPlans = [];
  List<dynamic> _filteredLessonPlans = [];
  int? _teacherId; // Fetched from the API response to build edit/delete URLs

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';

  late final bool canAdd;
  late final bool canEdit;
  late final bool canDelete;

  @override
  void initState() {
    super.initState();
    // Assuming you have these permissions defined in your system
    canAdd = authController.hasPermission('lesson_plan-add') || authController.userRole == 'teacher';
    canEdit = authController.hasPermission('lesson_plan-edit') || authController.userRole == 'teacher';
    canDelete = authController.hasPermission('lesson_plan-delete') || authController.userRole == 'teacher';

    _fetchLessonPlans();
    _scrollController.addListener(_scrollListener);

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _filterLessonPlans();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLessonPlans({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _lessonPlans.clear();
      _filteredLessonPlans.clear();
    }

    setState(() {
      if (refresh || _lessonPlans.isEmpty) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
      _hasError = false;
    });

    try {
      final response = await DioHelper().get(
        '${KiotaPayConstants.lessonPlan}',
        queryParameters: {
          'page': _currentPage,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List;
        final pagination = response.data['pagination'];

        // Save the teacher_id from the response so we can use it for Edit/Delete routes later
        if (response.data['teacher'] != null) {
          _teacherId = response.data['teacher']['teacher_id'];
        }

        setState(() {
          _lessonPlans.addAll(data);
          _filterLessonPlans(); // Apply any existing search filters
          _lastPage = pagination['last_page'] ?? 1;
          _currentPage++;
        });
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      debugPrint("Error fetching lesson plans: $e");
      setState(() => _hasError = true);
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _filterLessonPlans() {
    if (_searchQuery.isEmpty) {
      _filteredLessonPlans = List.from(_lessonPlans);
    } else {
      _filteredLessonPlans = _lessonPlans.where((plan) {
        final subject = plan['subject']?.toString().toLowerCase() ?? '';
        final className = plan['class']?.toString().toLowerCase() ?? '';
        final activity = plan['activity']?.toString().toLowerCase() ?? '';
        final strand = plan['strand']?.toString().toLowerCase() ?? '';

        return subject.contains(_searchQuery) ||
            className.contains(_searchQuery) ||
            activity.contains(_searchQuery) ||
            strand.contains(_searchQuery);
      }).toList();
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _currentPage <= _lastPage) {
      _fetchLessonPlans();
    }
  }

  void _deleteLessonPlan(int lessonPlanId) {
    if (_teacherId == null) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      title: 'Delete Lesson Plan?',
      desc: 'Are you sure you want to delete this lesson plan? This action cannot be undone.',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        try {
          final response = await DioHelper().delete('${KiotaPayConstants.lessonPlan}/$lessonPlanId');

          if (response.statusCode == 200) {
            setState(() {
              _lessonPlans.removeWhere((lp) => lp['id'] == lessonPlanId);
              _filterLessonPlans();
            });
            Get.snackbar('Success', 'Lesson plan deleted.', backgroundColor: Colors.green, colorText: Colors.white);
          }
        } catch (e) {
          Get.snackbar('Error', 'Failed to delete lesson plan.', backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
    ).show();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'draft': return Colors.grey;
      case 'rejected': return Colors.red;
      default: return ChanzoColors.primary;
    }
  }

  String _formatTime(Map<String, dynamic>? timeObj) {
    if (timeObj == null || timeObj['start_time'] == null || timeObj['stop_time'] == null) {
      return "Time Not Set";
    }
    return "${timeObj['start_time']} - ${timeObj['stop_time']}";
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "Date Not Set";
    try {
      return DateFormat('EEE, MMM d, yyyy').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Lesson Plans"),
        elevation: 0,
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
        onPressed: () {
          // Get.to(() => AddEditLessonPlanScreen(teacherId: _teacherId!));
          Get.to(() => AddEditLessonPlanScreen(teacherId: _teacherId!))?.then((res) {
            if (res == true) _fetchLessonPlans(refresh: true);
          });
        },
        backgroundColor: ChanzoColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Plan", style: TextStyle(color: Colors.white)),
      )
          : null,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search subject, class, or topic...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: _isLoading
                ? _buildShimmerLoader()
                : _hasError
                ? ErrorWidgetUniversal(
              title: "Failed to load",
              description: "We couldn't fetch your lesson plans.",
              onRetry: () => _fetchLessonPlans(refresh: true),
            )
                : RefreshIndicator(
              onRefresh: () => _fetchLessonPlans(refresh: true),
              color: ChanzoColors.primary,
              child: _filteredLessonPlans.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 80, left: 12, right: 12),
                itemCount: _filteredLessonPlans.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _filteredLessonPlans.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final plan = _filteredLessonPlans[index];
                  return _buildLessonPlanCard(plan);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonPlanCard(Map<String, dynamic> plan) {
    final statusColor = _getStatusColor(plan['status']);
    final timeMap = plan['time'] is Map ? plan['time'] as Map<String, dynamic> : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Subject and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    plan['subject'] ?? 'Unknown Subject',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    (plan['status'] ?? 'Draft').toString().toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Class, Stream, and Topic
            Text(
              "${plan['class']} (${plan['stream']})",
              style: TextStyle(color: ChanzoColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              "Strand: ${plan['strand'] ?? 'N/A'}\nActivity: ${plan['activity'] ?? 'N/A'}",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),

            // Footer: Date, Time and Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(_formatDate(plan['date']), style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(_formatTime(timeMap), style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                      ],
                    ),
                  ],
                ),

                // Actions Menu
                if (canEdit || canDelete)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'view') {
                        Get.to(() => ShowLessonPlanScreen(teacherId: _teacherId!, lessonPlanId: plan['id']));
                      } else if (value == 'edit') {
                        Get.to(() => AddEditLessonPlanScreen(teacherId: _teacherId!, lessonPlan: plan));
                      } else if (value == 'delete') {
                        _deleteLessonPlan(plan['id']);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('View')])),
                      if (canEdit) const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                      if (canDelete) const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                    ],
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "No lesson plans found",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 8),
              Text(
                "Click the + button below to create your first lesson plan.",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}