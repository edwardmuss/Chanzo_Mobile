import 'package:flutter/material.dart';

class CalendarEvent {
  final int id;
  final String title;
  final String category;
  final String eventDate;
  final String eventEndDate;
  final String startTime;
  final String endTime;
  final String location;
  final String description;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.eventDate,
    required this.eventEndDate,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.description,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      eventDate: json['event_date'],
      eventEndDate: json['event_end_date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      location: json['location'],
      description: json['description'],
    );
  }

  // Get color based on category
  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'holiday':
        return Colors.red.shade100;
      case 'exam':
        return Colors.blue.shade100;
      case 'meeting':
        return Colors.green.shade100;
      case 'event':
        return Colors.orange.shade100;
      case 'important':
        return Colors.purple.shade100;
      case 'deadline':
        return Colors.deepOrange.shade100;
      case 'lecture':
        return Colors.teal.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  // Get text color based on category
  Color get categoryTextColor {
    switch (category.toLowerCase()) {
      case 'holiday':
        return Colors.red.shade800;
      case 'exam':
        return Colors.blue.shade800;
      case 'meeting':
        return Colors.green.shade800;
      case 'event':
        return Colors.orange.shade800;
      case 'important':
        return Colors.purple.shade800;
      case 'deadline':
        return Colors.deepOrange.shade800;
      case 'lecture':
        return Colors.teal.shade800;
      default:
        return Colors.grey.shade800;
    }
  }
}