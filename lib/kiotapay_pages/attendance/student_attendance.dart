import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../globalclass/chanzo_color.dart';
import '../../globalclass/global_methods.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../widgets/error.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final int studentId;

  const StudentAttendanceScreen({super.key, required this.studentId});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  late Future<List<dynamic>> attendanceFuture;

  DateTime fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime toDate = DateTime.now();

  final dateFormatter = DateFormat('yyyy-MM-dd');

  String selectedStatus = "all"; // 👈 For badge filtering

  @override
  void initState() {
    super.initState();
    attendanceFuture = fetchAttendance();
  }

  Future<List<dynamic>> fetchAttendance() async {
    final token = await storage.read(key: 'token');

    final from = dateFormatter.format(fromDate);
    final to = dateFormatter.format(toDate);

    final response = await http.get(
      Uri.parse(
          '${KiotaPayConstants.getStudentAttendance}/${widget.studentId}/$from/$to'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception("Failed to fetch attendance");
    }
  }

  Map<String, int> calculateStatusCounts(List<dynamic> attendanceList) {
    final counts = <String, int>{};
    for (var record in attendanceList) {
      final status = (record['status'] as String).toLowerCase();
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, List<dynamic>> groupByWeek(List<dynamic> attendanceList) {
    Map<String, List<dynamic>> grouped = {};

    for (var record in attendanceList) {
      final date = DateTime.parse(record['date']).toLocal();
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final weekKey =
          "${DateFormat('MMM dd').format(weekStart)} - ${DateFormat('MMM dd').format(weekEnd)}";

      grouped.putIfAbsent(weekKey, () => []).add(record);
    }

    return grouped;
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.amber;
      case 'half day':
        return Colors.orange;
      case 'holiday':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      case 'half day':
        return Icons.timelapse;
      case 'holiday':
        return Icons.celebration;
      default:
        return Icons.info;
    }
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      itemCount: 9,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: fromDate, end: toDate),
    );

    if (picked != null) {
      setState(() {
        fromDate = picked.start;
        toDate = picked.end;
        attendanceFuture = fetchAttendance();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${authController.selectedStudentFirstName}\'s Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _pickDateRange,
            tooltip: "Filter by Date Range",
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: attendanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoader();
          } else if (snapshot.hasError) {
            return Center(
              child: ErrorWidgetUniversal(
                title: "Oops! Something went wrong",
                description: "We couldn't load the attendance.\nPlease check your connection and try again.",
                // imageAsset: 'assets/images/error.png', // Optional custom image
                onRetry: () {
                  setState(() {
                    attendanceFuture = fetchAttendance();
                  });
                },
              ),
            );
          }

          final attendanceList = snapshot.data!;
          if (attendanceList.isEmpty) {
            return const Center(child: Text("No attendance records found."));
          }

          final statusCounts = calculateStatusCounts(attendanceList);
          final groupedAttendance = groupByWeek(attendanceList);

          // Filtered list
          final filteredList = selectedStatus == "all"
              ? attendanceList
              : attendanceList
                  .where((item) =>
                      (item['status'] as String).toLowerCase() ==
                      selectedStatus.toLowerCase())
                  .toList();

          final groupedFilteredAttendance = groupByWeek(filteredList);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                attendanceFuture = fetchAttendance();
              });
            },
            child: ListView(
              children: [
                // Status summary badges (scrollable row)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      // "All" badge
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text(
                            "All",
                            style: TextStyle(color: Colors.white),
                          ),
                          selected: selectedStatus == "all",
                          selectedColor: ChanzoColors.primary,
                          onSelected: (_) {
                            setState(() => selectedStatus = "all");
                          },
                          backgroundColor: Colors.grey,
                        ),
                      ),
                      ...statusCounts.entries.map((entry) {
                        final status = entry.key;
                        final count = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: CircleAvatar(
                              backgroundColor: getStatusColor(status),
                              child: Icon(
                                getStatusIcon(status),
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            label: Text(
                              "${status[0].toUpperCase()}${status.substring(1)}: $count",
                              style: const TextStyle(color: Colors.white),
                            ),
                            selected: selectedStatus.toLowerCase() ==
                                status.toLowerCase(),
                            selectedColor: getStatusColor(status),
                            backgroundColor:
                                getStatusColor(status).withOpacity(0.6),
                            onSelected: (_) {
                              setState(() => selectedStatus = status);
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                // Attendance grouped by week
                ...groupedFilteredAttendance.entries.map((entry) {
                  final week = entry.key;
                  final records = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          "Week of $week",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: ChanzoColors.primary,
                          ),
                        ),
                      ),
                      ...records.map((attendance) {
                        final date =
                            DateTime.parse(attendance['date']).toLocal();
                        final status = attendance['status'];
                        final remarks = attendance['remarks'] ?? "";
                        final isToday =
                            DateUtils.isSameDay(date, DateTime.now());

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isToday
                                  ? ChanzoColors.primary.withOpacity(0.1)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    getStatusColor(status).withOpacity(0.2),
                                child: Icon(
                                  getStatusIcon(status),
                                  color: getStatusColor(status),
                                ),
                              ),
                              title: Text(
                                DateFormat('EEE, dd MMM yyyy').format(date),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isToday
                                      ? ChanzoColors.primary
                                      : Colors.black87,
                                ),
                              ),
                              subtitle: remarks.isNotEmpty
                                  ? Text("Remarks: $remarks")
                                  : null,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: getStatusColor(status),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
