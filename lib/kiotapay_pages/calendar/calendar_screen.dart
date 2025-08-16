import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/calendar_model.dart';
import 'calendar_card.dart';
import 'calendar_controller.dart';
import 'shimmer_calendar.dart';

class CalendarScreen extends StatelessWidget {
  CalendarScreen({super.key});

  final CalendarController controller = Get.put(CalendarController());
  final Rx<DateTime> selectedDay = DateTime.now().obs;
  final Rx<DateTime> focusedDay = DateTime.now().obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Calendar'),
        actions: [
          IconButton(
            icon: Obx(() => Icon(
                controller.isGridView.value ? Icons.view_list : Icons.calendar_month)),
            onPressed: controller.toggleView,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.events.isEmpty) {
          return const ShimmerCalendar();
        }

        return Column(
          children: [
            // Search and Filter Section
            _buildSearchFilterSection(context),

            // Calendar/List View
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await controller.onRefresh();
                  // Force rebuild the view after refresh
                  controller.isGridView.refresh();
                },
                child: controller.isGridView.value
                    ? _buildCalendarView()
                    : _buildListView(),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSearchFilterSection(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: controller.searchController, // Add this controller to your controller
            decoration: InputDecoration(
              hintText: 'Search events...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.searchController.clear();
                  controller.updateSearch('', submit: true);
                },
              ),
            ),
            onChanged: (value) {
              controller.updateSearch(value);
            },
            onSubmitted: (value) {
              controller.updateSearch(value, submit: true);
            },
            textInputAction: TextInputAction.search,
          ),
        ),
        SizedBox(
          height: 50,
          child: Obx(() {
            final categories = controller.events
                .map((e) => e.category.toLowerCase())
                .toSet()
                .toList();

            if (categories.isEmpty) return const SizedBox();

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = controller.selectedCategories.contains(category);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category.capitalizeFirst!),
                    selected: isSelected,
                    onSelected: (_) => controller.toggleCategory(category),
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade800,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCalendarView() {
    return Obx(() {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: TableCalendar(
              focusedDay: focusedDay.value,
              firstDay: DateTime.utc(2000),
              lastDay: DateTime.utc(2100),
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarFormat: controller.calendarFormat.value,
              onFormatChanged: (format) {
                controller.calendarFormat.value = format;
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(Get.context!).primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(Get.context!).primaryColor,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(Get.context!).primaryColor,
                  shape: BoxShape.circle,
                ),
                markersAlignment: Alignment.bottomCenter,
                markersAutoAligned: false,
                canMarkersOverflow: true,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                headerPadding: const EdgeInsets.only(bottom: 12),
                leftChevronMargin: EdgeInsets.zero,
                rightChevronMargin: EdgeInsets.zero,
              ),

              daysOfWeekStyle: DaysOfWeekStyle(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                weekdayStyle: TextStyle(
                  fontSize: 14, // Slightly larger font
                  fontWeight: FontWeight.w500, // Medium weight
                  color: Theme.of(Get.context!).textTheme.bodyLarge!.color,
                ),
                weekendStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade400,
                ),
              ),
              eventLoader: (day) {
                final date = DateTime(day.year, day.month, day.day);
                return controller.eventsByDay[date] ?? [];
              },
              onDaySelected: (selected, focused) {
                selectedDay.value = selected;
                focusedDay.value = focused;
              },
              selectedDayPredicate: (day) => isSameDay(selectedDay.value, day),
              calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: events.map((event) {
                        Color color;

                        switch ((event as CalendarEvent).category.toLowerCase()) {
                          case 'holiday':
                            color = Colors.green;
                            break;
                          case 'exam':
                            color = Colors.red;
                            break;
                          case 'meeting':
                            color = Colors.blue;
                            break;
                          default:
                            color = Colors.grey;
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    );
                  },
              ),
            ),
          ),
          // SliverToBoxAdapter(
          //   child: Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //     child: Text(
          //       DateFormat('EEEE, MMMM d, y').format(selectedDay.value),
          //       style: Theme.of(Get.context!).textTheme.titleLarge,
          //     ),
          //   ),
          // ),
          // SliverPadding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16),
          //   sliver: Obx(() {
          //     final date = DateTime(
          //       selectedDay.value.year,
          //       selectedDay.value.month,
          //       selectedDay.value.day,
          //     );
          //     final events = controller.eventsByDay[date] ?? [];
          //
          //     if (events.isEmpty) {
          //       return SliverToBoxAdapter(
          //         child: Padding(
          //           padding: const EdgeInsets.all(16),
          //           child: Text(
          //             'No events to show',
          //             style: Theme.of(Get.context!).textTheme.bodyLarge,
          //           ),
          //         ),
          //       );
          //     }
          //
          //     return SliverList(
          //       delegate: SliverChildBuilderDelegate(
          //             (context, index) => CalendarCard(event: events[index]),
          //         childCount: events.length,
          //       ),
          //     );
          //   }),
          // ),
        ],
      );
    });
  }

  Widget _buildListView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scroll) {
        if (scroll.metrics.pixels == scroll.metrics.maxScrollExtent &&
            !controller.isLoading.value &&
            controller.hasMore.value) {
          controller.nextPage();
        }
        return false;
      },
      child: Obx(() {
        if (controller.isLoading.value && controller.currentPage.value == 1) {
          return const Center(child: CircularProgressIndicator());
        }

        final filtered = controller.filteredEvents;
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No events found",
                  style: Theme.of(Get.context!).textTheme.titleMedium,
                ),
                if (controller.searchQuery.isNotEmpty ||
                    controller.selectedCategories.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      controller.searchQuery.value = '';
                      controller.selectedCategories.clear();
                      controller.fetchCalendar(refresh: true);
                    },
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: filtered.length + (controller.hasMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= filtered.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return CalendarCard(event: filtered[index]);
          },
        );
      }),
    );
  }
}
