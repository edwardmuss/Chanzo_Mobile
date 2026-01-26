import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kiotapay/globalclass/chanzo_color.dart';
import 'package:shimmer/shimmer.dart';

import '../../globalclass/global_methods.dart';
import '../../globalclass/kiotapay_constants.dart';
import '../../utils/dio_helper.dart';
import '../../widgets/error.dart';

class TimetableScreen extends StatefulWidget {
  final int classId;
  final int? streamId;

  const TimetableScreen({
    super.key,
    required this.classId,
    this.streamId,
  });

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> timetableFuture;
  late TabController _tabController;

  final timeFormatter = DateFormat.jm(); // Formats to h:mm a

  @override
  void initState() {
    super.initState();
    timetableFuture = fetchTimetable(widget.classId, widget.streamId!);
  }

  Future<Map<String, dynamic>> fetchTimetable(int classId, int streamId) async {
    try {
      // Use DioHelper to send GET request
      final response = await DioHelper().get(
        KiotaPayConstants.getStudentTimetable,
        queryParameters: {
          'class_id': classId,
          'stream_id': streamId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return data;
      } else {
        throw Exception("Failed to fetch timetable: ${response.statusCode}");
      }
    } on DioError catch (e) {
      debugPrint("❌ DioError: ${e.message}");
      throw Exception("Failed to fetch timetable: ${e.response?.data['message'] ?? e.message}");
    } catch (e) {
      debugPrint("❌ Error: $e");
      throw Exception("Something went wrong while fetching timetable");
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      timetableFuture = fetchTimetable(widget.classId, widget.streamId!);
    });
    await timetableFuture; // ensure data is refreshed
  }

  bool isCurrentTimeWithinSlot(String from, String to) {
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;

    final fromParts = from.split(':').map(int.parse).toList();
    final toParts = to.split(':').map(int.parse).toList();

    final slotStartInMinutes = fromParts[0] * 60 + fromParts[1];
    final slotEndInMinutes = toParts[0] * 60 + toParts[1];

    return currentTimeInMinutes >= slotStartInMinutes &&
        currentTimeInMinutes < slotEndInMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${authController.selectedStudent['class']?['name']} "
              "(${authController.selectedStudent['stream']?['name']}) Timetable",
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: timetableFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoader();
          } else if (snapshot.hasError) {
            return Center(
              child: ErrorWidgetUniversal(
                title: "Oops! failed to load timetable.",
                description: "We couldn't load the timetable.\nPlease check your connection and try again.",
                onRetry: () {
                  _refreshData(); // FIX: Call the method
                },
              ),
            );
          }

          final data = snapshot.data!;
          final timetable = Map<String, dynamic>.from(data);

          if (timetable.isEmpty) {
            return Center(
              child: ErrorWidgetUniversal(
                title: "No timetable available.",
                description: "We couldn't load the timetable.\nPlease check your connection and try again.",
                onRetry: () {
                  _refreshData(); // FIX: Call the method
                },
              ),
            );
          }

          final days = timetable.keys.toList()
            ..sort((a, b) {
              const order = {
                "Monday": 1,
                "Tuesday": 2,
                "Wednesday": 3,
                "Thursday": 4,
                "Friday": 5,
                "Saturday": 6,
                "Sunday": 7,
              };
              return order[a]!.compareTo(order[b]!);
            });

          // Determine current day index
          final today = DateTime.now();
          // final currentDayName = DateFormat('EEEE').format(today);
          // final currentDayIndex = today.weekday % 7;

          final currentDayName = DateFormat('EEEE').format(today); // "Thursday"
          final currentDayIndex = days.indexOf(currentDayName); // find exact index

          _tabController = TabController(
            length: days.length,
            vsync: this,
            initialIndex: currentDayIndex >= 0 ? currentDayIndex : 0,
          );

          return Column(
            children: [
              // TabBar
              _buildTabBar(days, currentDayIndex, currentDayName, today),
              const SizedBox(height: 8),

              // Pull to refresh wrapper
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  child: TabBarView(
                    controller: _tabController,
                    children: days.map((day) {
                      final daySchedule = timetable[day] as Map<String, dynamic>;
                      final daySlotKeys = daySchedule.keys.toList()
                        ..sort((a, b) => DateFormat.Hms()
                            .parse(a.split('-')[0])
                            .compareTo(DateFormat.Hms().parse(b.split('-')[0])));

                      return ListView.builder(
                        itemCount: daySlotKeys.length,
                        itemBuilder: (context, index) {
                          final slotKey = daySlotKeys[index];
                          final slotTimes = slotKey.split('-');
                          final fromTime = slotTimes[0];
                          final toTime = slotTimes[1];
                          final entries = daySchedule[slotKey] as List<dynamic>;
                          final isActive = isCurrentTimeWithinSlot(fromTime, toTime);

                          return _buildRowSlotWidget(fromTime, toTime, entries, isActive);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabBar(List<String> days, int currentDayIndex, String currentDayName, DateTime today) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: ChanzoColors.secondary.withOpacity(0.2),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: const EdgeInsets.symmetric(horizontal: 1),
        dividerColor: ChanzoColors.primary,
        onTap: (index) {
          HapticFeedback.lightImpact();
        },
        tabs: days.map((day) {
          final index = days.indexOf(day);
          final date = today.add(Duration(days: index - currentDayIndex));
          final isToday = day == currentDayName;
          final isSelected = _tabController.index == index;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: isToday
                  ? ChanzoColors.secondary
                  : isSelected
                  ? ChanzoColors.secondary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: ChanzoColors.secondary, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.substring(0, 3),
                  style: TextStyle(
                    color: isToday
                        ? Colors.white
                        : isSelected
                        ? ChanzoColors.secondary
                        : Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isToday
                        ? Colors.white.withOpacity(0.2)
                        : Colors.transparent,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isToday
                          ? Colors.white
                          : isSelected
                          ? ChanzoColors.secondary
                          : Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRowSlotWidget(String from, String to, List<dynamic> entries, bool isActive) {
    final formattedFrom = timeFormatter.format(DateFormat.Hms().parse(from));
    final formattedTo = timeFormatter.format(DateFormat.Hms().parse(to));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedFrom,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTo,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isActive ? ChanzoColors.primary : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entries.map((entry) {
                  final isBreak = entry['break_name'] != null && entry['break_name'] != "";
                  final subject = isBreak
                      ? entry['break_name']
                      : entry['subject_name'] ?? "Unknown Subject";
                  final teacher = entry['teacher_name'];
                  final room = entry['room_number'] ?? "";

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        if (!isBreak && teacher != null && teacher != "")
                          Row(
                            children: [
                              Icon(Icons.person, size: 14, color: isActive ? Colors.white70 : Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                teacher,
                                style: TextStyle(
                                  color: isActive ? Colors.white70 : Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        if (room.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.room, size: 14, color: isActive ? Colors.white70 : Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                room,
                                style: TextStyle(
                                  color: isActive ? Colors.white70 : Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      itemCount: 7, // Show 7 shimmer slots
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
