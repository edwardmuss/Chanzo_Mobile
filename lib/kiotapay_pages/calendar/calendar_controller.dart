import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kiotapay/globalclass/kiotapay_constants.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/calendar_model.dart';
import '../../utils/dio_helper.dart';

class CalendarController extends GetxController {
  var isLoading = true.obs;
  var isGridView = false.obs;
  var currentPage = 1.obs;
  var events = <CalendarEvent>[].obs;
  var hasMore = true.obs;
  var selectedCategories = <String>[].obs;

  final int perPage = 20;
  var searchQuery = ''.obs;
  final calendarFormat = CalendarFormat.month.obs;
  final showFormatButtons = true.obs; // Control visibility of format buttons

  void mapEventsByDay(List<CalendarEvent> events) {
    eventsByDay.clear();

    for (final event in events) {
      final start = DateTime.parse(event.eventDate);
      final end = DateTime.parse(event.eventEndDate);

      for (DateTime date = start;
      !date.isAfter(end);
      date = date.add(const Duration(days: 1))) {
        eventsByDay.putIfAbsent(date, () => []).add(event);
      }
    }
  }

  List<CalendarEvent> get filteredEvents {
    var filtered = events;

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((event) {
        return event.title.toLowerCase().contains(query) ||
            event.description.toLowerCase().contains(query) ||
            event.location.toLowerCase().contains(query) ||
            event.category.toLowerCase().contains(query);
      }).toList().obs;
    }

    // Apply category filter
    if (selectedCategories.isNotEmpty) {
      filtered = filtered.where((event) =>
          selectedCategories.contains(event.category.toLowerCase())
      ).toList().obs;
    }

    return filtered;
  }

  final searchController = TextEditingController();

// Update the updateSearch method
  void updateSearch(String query, {bool submit = false}) {
    searchQuery.value = query;

    if (submit) {
      // Cancel any pending debounce calls
      // debounce?.cancel();
      fetchCalendar(refresh: true);
    }
  }

// Add this to dispose the controller when no longer needed
  @override
  void onClose() {
    searchController.dispose();
    // debounce?.cancel();
    super.onClose();
  }

  void toggleCategory(String category) {
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
    update();
  }

  void nextPage() {
    if (hasMore.value && !isLoading.value) {
      currentPage++;
      fetchCalendar(); // Don't refresh, just load next page
    }
  }

  void toggleView() {
    isGridView.value = !isGridView.value;
  }

  Future<void> onRefresh() async {
    searchQuery.value = ''; // clear search on refresh
    selectedCategories.clear(); // clear filters on refresh
    await fetchCalendar(refresh: true);
  }

  @override
  void onInit() {
    fetchCalendar();
    super.onInit();
  }

  final eventsByDay = <DateTime, List<CalendarEvent>>{}.obs;

  Future<void> fetchCalendar({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      hasMore.value = true;
      events.clear();
      eventsByDay.clear();
    }

    isLoading(true);
    try {
      final response = await DioHelper().get(
        KiotaPayConstants.getCalendar,
        queryParameters: {
          'page': currentPage.value,
          if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
          if (selectedCategories.isNotEmpty)
            'categories': selectedCategories.join(','),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        final newEvents = data.map((e) => CalendarEvent.fromJson(e)).toList();

        if (newEvents.length < perPage) hasMore.value = false;

        if (refresh) {
          events.value = newEvents;
        } else {
          events.addAll(newEvents);
        }

        // Clear and rebuild eventsByDay when refreshing
        if (refresh) {
          eventsByDay.clear();
        }

        for (var event in newEvents) {
          final start = DateTime.parse(event.eventDate).toLocal();
          final end = DateTime.parse(event.eventEndDate).toLocal();
          for (int i = 0; i <= end.difference(start).inDays; i++) {
            final day = DateTime(start.year, start.month, start.day + i);
            final normalized = DateTime(day.year, day.month, day.day);
            eventsByDay.update(
              normalized,
                  (existing) => existing..add(event),
              ifAbsent: () => [event],
            );
          }
        }
      }
    } catch (e) {
      print('Error fetching events: $e');
    } finally {
      isLoading(false);
    }
  }
}
