import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../globalclass/chanzo_color.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../utils/dio_helper.dart';

class StudentListScreen extends StatefulWidget {
  final int? classId;
  final int? streamId;
  final String? className;
  final String? streamName;

  const StudentListScreen({
    super.key,
    this.classId,
    this.streamId,
    this.className,
    this.streamName,
  });

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _apiErrorMessage; // Holds message when success == false

  List<dynamic> _students = [];
  List<dynamic> _availableClasses = [];
  List<dynamic> _availableStreams = [];
  int _currentPage = 1;
  int _lastPage = 1;
  int? _selectedClassId;
  int? _selectedStreamId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Pre-fill if passed from previous screen
    _selectedClassId = widget.classId;
    _selectedStreamId = widget.streamId;

    _fetchStudents();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _currentPage <= _lastPage) {
      _fetchStudents();
    }
  }

  Future<void> _fetchStudents({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _students.clear();
    }

    setState(() {
      _isLoading = refresh || _students.isEmpty;
      if (!refresh && _students.isNotEmpty) _isLoadingMore = true;
      _apiErrorMessage = null;
    });

    try {
      final Map<String, dynamic> queryParams = {
        'page': _currentPage,
      };

      // Use the State variables, NOT the widget variables
      if (_selectedClassId != null) queryParams['class_id'] = _selectedClassId;
      if (_selectedStreamId != null) queryParams['stream_id'] = _selectedStreamId;
      if (_searchQuery.isNotEmpty) queryParams['searchQuery'] = _searchQuery;

      // if (widget.classId != null) queryParams['class_id'] = widget.classId;
      // if (widget.streamId != null) queryParams['stream_id'] = widget.streamId;
      // if (_searchQuery.isNotEmpty) queryParams['searchQuery'] = _searchQuery;

      final response = await DioHelper().get(
        KiotaPayConstants.admission,
        queryParameters: queryParams,
      );

      // Check if the request was successful
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List;
        final pagination = response.data['pagination'] ?? {};
        final filters = response.data['filters'] ?? {};

        setState(() {
          _students.addAll(data);

          // Populate the Class Dropdown
          if (filters['classes'] != null && _availableClasses.isEmpty) {
            _availableClasses = filters['classes'];
            _updateStreams(_selectedClassId); // Populate streams if a class was pre-selected
          }

          _lastPage = pagination['last_page'] ?? 1;
          _currentPage++;
        });
      }
      // Handle 200 OK but success == false (e.g. Logic failures)
      else if (response.data['success'] == false) {
        setState(() {
          _apiErrorMessage = response.data['message'] ?? 'Failed to load students.';
        });
      }
    } on DioException catch (e) {
      // 3. Handle 403, 404, 500 errors from the backend
      setState(() {
        _apiErrorMessage = e.response?.data['message'] ?? 'An unexpected error occurred.';
      });
    } catch (e) {
      setState(() {
        _apiErrorMessage = 'An unexpected error occurred.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _updateStreams(int? classId) {
    if (classId == null) {
      setState(() {
        _availableStreams = [];
        _selectedStreamId = null;
      });
      return;
    }

    final classObj = _availableClasses.firstWhere((c) => c['id'] == classId, orElse: () => null);
    setState(() {
      _availableStreams = classObj != null ? (classObj['streams'] ?? []) : [];
      // Don't clear stream if it matches the pre-filled one
      if (!_availableStreams.any((s) => s['id'] == _selectedStreamId)) {
        _selectedStreamId = null;
      }
    });
  }

  void _onSearchSubmitted(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
    _fetchStudents(refresh: true);
  }

  Future<void> _callParent(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      Get.snackbar('Error', 'Could not open dialer for $phoneNumber.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String title = widget.className != null && widget.streamName != null
        ? "${widget.className} ${widget.streamName}"
        : "Students";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Class Stream filters
          if (_availableClasses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDropdown("All Classes", _availableClasses, _selectedClassId, (val) {
                      setState(() => _selectedClassId = val);
                      _updateStreams(val);
                      _fetchStudents(refresh: true); // Reload students!
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown("All Streams", _availableStreams, _selectedStreamId, (val) {
                      setState(() => _selectedStreamId = val);
                      _fetchStudents(refresh: true); // Reload students!
                    }),
                  ),
                ],
              ),
            ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearchSubmitted,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: "Search name or admission number...",
                hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchSubmitted('');
                  },
                )
                    : null,
                filled: true,
                fillColor: isDark ? Theme.of(context).cardColor : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                ),
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: _isLoading
                ? _buildShimmerLoader(context)
                : _apiErrorMessage != null
                ? _buildApiErrorState(isDark)
                : RefreshIndicator(
              onRefresh: () => _fetchStudents(refresh: true),
              color: ChanzoColors.primary,
              child: _students.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _students.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _students.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final student = _students[index];
                  return _buildStudentCard(student, isDark);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, bool isDark) {
    final String gender = student['gender']?.toString().toLowerCase() ?? '';
    final bool isMale = gender == 'male';
    final List parents = student['parents'] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 0 : 1,
      color: isDark ? Theme.of(context).cardColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isMale ? Colors.blue.withOpacity(0.1) : Colors.pink.withOpacity(0.1),
          foregroundColor: isMale ? Colors.blue : Colors.pink,
          child: Icon(isMale ? Icons.face : Icons.face_3),
        ),
        title: Text(
          student['student_name'] ?? 'Unknown Name',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            "Adm: ${student['admission_number'] ?? 'N/A'} • Class: ${student['class'] ?? 'N/A'}",
            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
          ),
        ),
        children: [
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.black12 : Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Parent/Guardian Contacts",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? ChanzoColors.secondary : ChanzoColors.primary),
                ),
                const SizedBox(height: 8),
                if (parents.isEmpty)
                  Text("No contacts available.", style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic))
                else
                  ...parents.map((parent) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_outline, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(parent['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(parent['phone_number'] ?? 'No Phone', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                          ),
                          if (parent['phone_number'] != null)
                            IconButton(
                              icon: const Icon(Icons.phone),
                              color: Colors.green,
                              onPressed: () => _callParent(parent['phone_number']),
                            )
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildApiErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: isDark ? Colors.red.shade400 : Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              "Access Denied",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              _apiErrorMessage ?? "You don't have permission to view this.",
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _fetchStudents(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChanzoColors.primary,
                foregroundColor: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No Students Found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? "We couldn't find anyone matching '$_searchQuery'."
                  : "There are no students assigned to this class.",
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoader(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final Color highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    final Color containerColor = isDark ? Theme.of(context).cardColor : Colors.white;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 80,
            decoration: BoxDecoration(color: containerColor, borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<dynamic> items, int? value, Function(int?) onChanged) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Add a "Clear/All" option at the top of the list
    List<DropdownMenuItem<int>> dropdownItems = [
      DropdownMenuItem<int>(value: null, child: Text(label, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))),
    ];

    dropdownItems.addAll(items.map((item) {
      return DropdownMenuItem<int>(
        value: item['id'],
        child: Text(item['name'].toString(), overflow: TextOverflow.ellipsis),
      );
    }));

    return DropdownButtonFormField<int>(
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        filled: true,
        fillColor: isDark ? Theme.of(context).cardColor : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
      ),
      value: value,
      dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
      items: dropdownItems,
      onChanged: onChanged,
    );
  }
}