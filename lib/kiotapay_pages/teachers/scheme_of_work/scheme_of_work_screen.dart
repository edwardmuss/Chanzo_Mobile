import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../globalclass/kiotapay_constants.dart';
import '../../../globalclass/chanzo_color.dart';
import '../../../utils/dio_helper.dart';
import '../../kiotapay_authentication/AuthController.dart';
import '../../../widgets/error.dart';
import 'add_edit_scheme_of_work_screen.dart';
import 'show_scheme_of_work_screen.dart';

class SchemeOfWorkScreen extends StatefulWidget {
  const SchemeOfWorkScreen({super.key});

  @override
  State<SchemeOfWorkScreen> createState() => _SchemeOfWorkScreenState();
}

class _SchemeOfWorkScreenState extends State<SchemeOfWorkScreen> {
  final AuthController authController = Get.find<AuthController>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _schemes = [];
  List<dynamic> _filteredSchemes = [];
  int? _teacherId;

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
    canAdd = authController.hasPermission('record_of_work-add') || authController.userRole == 'teacher';
    canEdit = authController.hasPermission('record_of_work-edit') || authController.userRole == 'teacher';
    canDelete = authController.hasPermission('record_of_work-delete') || authController.userRole == 'teacher';

    _fetchSchemes();
    _scrollController.addListener(_scrollListener);

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _filterSchemes();
      });
    });
  }

  Future<void> _fetchSchemes({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _schemes.clear();
      _filteredSchemes.clear();
    }

    setState(() {
      if (refresh || _schemes.isEmpty) _isLoading = true;
      else _isLoadingMore = true;
      _hasError = false;
    });

    try {
      final response = await DioHelper().get(
        KiotaPayConstants.schemeOfWork,
        queryParameters: {'page': _currentPage},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List;
        final pagination = response.data['pagination'];

        if (response.data['teacher'] != null) {
          _teacherId = response.data['teacher']['teacher_id'];
        }

        setState(() {
          _schemes.addAll(data);
          _filterSchemes();
          _lastPage = pagination['last_page'] ?? 1;
          _currentPage++;
        });
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _filterSchemes() {
    if (_searchQuery.isEmpty) {
      _filteredSchemes = List.from(_schemes);
    } else {
      _filteredSchemes = _schemes.where((s) {
        return (s['subject']?.toString().toLowerCase() ?? '').contains(_searchQuery) ||
            (s['class']?.toString().toLowerCase() ?? '').contains(_searchQuery) ||
            (s['work_covered']?.toString().toLowerCase() ?? '').contains(_searchQuery);
      }).toList();
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore && _currentPage <= _lastPage) {
      _fetchSchemes();
    }
  }

  void _deleteScheme(int id) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      title: 'Delete Scheme of Work?',
      desc: 'Are you sure you want to delete this record? This action cannot be undone.',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        try {
          final response = await DioHelper().delete('${KiotaPayConstants.schemeOfWork}/$id');
          if (response.statusCode == 200) {
            setState(() {
              _schemes.removeWhere((s) => s['id'] == id);
              _filterSchemes();
            });
            Get.snackbar('Success', 'Record deleted.', backgroundColor: Colors.green, colorText: Colors.white);
          }
        } catch (e) {
          Get.snackbar('Error', 'Failed to delete record.', backgroundColor: Colors.red, colorText: Colors.white);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Schemes of Work"), elevation: 0),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => AddEditSchemeOfWorkScreen(teacherId: _teacherId!))?.then((res) {
            if (res == true) _fetchSchemes(refresh: true);
          });
        },
        backgroundColor: ChanzoColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Record", style: TextStyle(color: Colors.white)),
      )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search subject, class, or work covered...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildShimmerLoader()
                : _hasError
                ? ErrorWidgetUniversal(title: "Failed to load", description: "Couldn't fetch records.", onRetry: () => _fetchSchemes(refresh: true))
                : RefreshIndicator(
              onRefresh: () => _fetchSchemes(refresh: true),
              color: ChanzoColors.primary,
              child: _filteredSchemes.isEmpty
                  ? const Center(child: Text("No records found."))
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 80, left: 12, right: 12),
                itemCount: _filteredSchemes.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _filteredSchemes.length) return const Center(child: CircularProgressIndicator());
                  final scheme = _filteredSchemes[index];
                  final statusColor = _getStatusColor(scheme['status']);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(scheme['subject'] ?? 'Unknown Subject', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: statusColor.withOpacity(0.5))),
                                child: Text((scheme['status'] ?? 'Draft').toString().toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text("${scheme['class']} (${scheme['stream']}) - Week ${scheme['week'] ?? 'N/A'}", style: TextStyle(color: ChanzoColors.primary, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text("Work Covered: ${scheme['work_covered'] ?? 'N/A'}", maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700)),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(scheme['date'] != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(scheme['date'])) : 'No Date', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              if (canEdit || canDelete)
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                  onSelected: (value) {
                                    if (value == 'view') {
                                      Get.to(() => ShowSchemeOfWorkScreen(schemeId: scheme['id']));
                                    } else if (value == 'edit') {
                                      Get.to(() => AddEditSchemeOfWorkScreen(teacherId: _teacherId!, scheme: scheme));
                                    } else if (value == 'delete') {
                                      _deleteScheme(scheme['id']);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'view', child: Text('View Details')),
                                    if (canEdit) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    if (canDelete) const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                )
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
      ),
    );
  }
}