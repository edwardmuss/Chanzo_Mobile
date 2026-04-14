import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanzo/globalclass/kiotapay_constants.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../globalclass/chanzo_color.dart';
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

      // --- Handle 2xx Success ---
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        final data = responseData['data'] as List;
        final newEvents = data.map((e) => CalendarEvent.fromJson(e)).toList();

        if (newEvents.length < perPage) hasMore.value = false;

        if (refresh) {
          events.value = newEvents;
          eventsByDay.clear();
        } else {
          events.addAll(newEvents);
        }

        // Map events safely to the Calendar
        for (var event in newEvents) {
          try {
            final startDateStr = event.eventDate;
            final endDateStr = (event.eventEndDate == null || event.eventEndDate.toString().isEmpty)
                ? startDateStr
                : event.eventEndDate;

            final start = DateTime.parse(startDateStr.toString());
            final end = DateTime.parse(endDateStr.toString());

            for (int i = 0; i <= end.difference(start).inDays; i++) {
              final normalized = DateTime.utc(start.year, start.month, start.day + i);

              eventsByDay.update(
                normalized,
                    (existing) {
                  if (!existing.any((e) => e.id == event.id)) {
                    existing.add(event);
                  }
                  return existing;
                },
                ifAbsent: () => [event],
              );
            }
          } catch (e) {
            print('Error parsing dates for event ${event.id}: $e');
          }
        }
      }

      // --- Catch Dio Non-2xx Errors (403, 400, 404, 500) ---
    } on DioException catch (e) {
      hasMore.value = false; // Stop pagination on error
      String errorMessage = 'A network error occurred.';

      // Check if the server sent a response body
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response?.data;

        // Extract your custom message from the JSON
        if (errorData is Map && errorData['message'] != null) {
          errorMessage = errorData['message'];
        }
      }

      Get.snackbar(
        'Notice',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ChanzoColors.secondary,
        colorText: Colors.white,
      );
      print('Dio API Error: ${e.response?.statusCode} - $errorMessage');

      // --- Catch general Dart errors (e.g., parsing/JSON errors) ---
    } catch (e) {
      hasMore.value = false;
      print('General Error fetching events: $e');
      Get.snackbar(
        'Error',
        'An unexpected error occurred processing the calendar.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }
}
