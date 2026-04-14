import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../globalclass/chanzo_color.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../utils/dio_helper.dart';
import '../../widgets/shimmer_widget.dart';
import '../kiotapay_authentication/AuthController.dart';
import 'teacher_add_edit_homework_screen.dart';
import 'teacher_submissions_screen.dart';

class TeacherHomeworkScreen extends StatefulWidget {
  const TeacherHomeworkScreen({super.key});

  @override
  State<TeacherHomeworkScreen> createState() => _TeacherHomeworkScreenState();
}

class _TeacherHomeworkScreenState extends State<TeacherHomeworkScreen> {
  final AuthController authController = Get.find<AuthController>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> homeworks = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 1;
  int lastPage = 1;
  String searchQuery = '';

  late final bool canAdd;
  late final bool canEdit;
  late final bool canDelete;
  late final bool canEvaluate;

  @override
  void initState() {
    super.initState();
    canAdd = authController.hasPermission('homework-add');
    canEdit = authController.hasPermission('homework-edit');
    canDelete = authController.hasPermission('homework-delete');
    canEvaluate = authController.hasPermission('submission-edit');

    fetchHomeworks();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> fetchHomeworks({bool refresh = false}) async {
    if (refresh) {
      currentPage = 1;
      homeworks.clear();
    }

    setState(() => refresh || homeworks.isEmpty ? isLoading = true : isLoadingMore = true);

    try {
      final response = await DioHelper().get(
        KiotaPayConstants.getTeacherHomeWork,
        queryParameters: {
          'page': currentPage,
          if (searchQuery.isNotEmpty) 'search': searchQuery,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List;
        final pagination = response.data['pagination'];

        setState(() {
          homeworks.addAll(data);
          lastPage = pagination['last_page'] ?? 1;
          currentPage++;
        });
      }
    } catch (e) {
      print("Error fetching homework: $e");
      Get.snackbar('Error', 'Failed to load homeworks', snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 &&
        !isLoadingMore && currentPage <= lastPage) {
      fetchHomeworks();
    }
  }

  void _deleteHomework(int id) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      title: 'Delete Homework?',
      desc: 'Are you sure you want to delete this homework? This action cannot be undone.',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        try {
          final response = await DioHelper().delete('${KiotaPayConstants.baseUrl}/homeworks/$id');
          if (response.statusCode == 200) {
            setState(() {
              homeworks.removeWhere((hw) => hw['id'] == id);
            });
            Get.snackbar('Success', 'Homework deleted.', backgroundColor: Colors.green, colorText: Colors.white);
          }
        } catch (e) {
          Get.snackbar('Error', 'Failed to delete homework.');
        }
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Homework")),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
        onPressed: () {
          // Navigate to the unified screen WITHOUT passing a homework object
          Get.to(() => const TeacherAddEditHomeworkScreen())?.then((res) {
            if(res == true) fetchHomeworks(refresh: true);
          });
        },
        backgroundColor: ChanzoColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Homework", style: TextStyle(color: Colors.white)),
      )
          : null,
      body: RefreshIndicator(
        onRefresh: () => fetchHomeworks(refresh: true),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search subject or class...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (value) {
                  searchQuery = value;
                  fetchHomeworks(refresh: true);
                },
              ),
            ),

            // Homework List
            Expanded(
              child: isLoading
                  ? _buildShimmerLoader()
                  : homeworks.isEmpty
                  ? const Center(child: Text("No homework found."))
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 80, left: 12, right: 12),
                itemCount: homeworks.length + (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == homeworks.length) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final hw = homeworks[index];
                  final submissionCount = hw['submissions_count'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  hw['subject']['name'] ?? 'Subject',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              // Menu options
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    // PASS THE 'hw' OBJECT!
                                    Get.to(() => TeacherAddEditHomeworkScreen(homework: hw))?.then((res) {
                                      if(res == true) fetchHomeworks(refresh: true);
                                    });
                                  } else if (value == 'delete') {
                                    _deleteHomework(hw['id']);
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (canEdit) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  if (canDelete) const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              )
                            ],
                          ),
                          Text(
                            "${hw['class']['name']} (${hw['stream']['name']})",
                            style: TextStyle(color: ChanzoColors.primary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text("Due: ${DateFormat('MMM d, yyyy').format(DateTime.parse(hw['submission_date']))}"),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // View Submissions Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Get.to(() => TeacherSubmissionsScreen(homework: hw));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ChanzoColors.secondary.withOpacity(0.1),
                                foregroundColor: ChanzoColors.secondary,
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.grading),
                              label: Text("View Submissions ($submissionCount)"),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(12),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerWidget.rectangular(height: 140, width: double.infinity),
      ),
    );
  }
}