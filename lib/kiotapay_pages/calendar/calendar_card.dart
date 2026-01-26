import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/calendar_model.dart';

class CalendarCard extends StatelessWidget {
  final CalendarEvent event;

  const CalendarCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Show event details
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category badge and title
              Row(
                children: [
                  // Container(
                  //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  //   decoration: BoxDecoration(
                  //     color: event.categoryColor,
                  //     borderRadius: BorderRadius.circular(12),
                  //   ),
                  //   child: Text(
                  //     event.category.toUpperCase(),
                  //     style: TextStyle(
                  //       fontSize: 12,
                  //       fontWeight: FontWeight.bold,
                  //       color: event.categoryTextColor,
                  //     ),
                  //   ),
                  // ),
                  // const Spacer(),
                  Text(
                    _formatDateRange(event.eventDate, event.eventEndDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Event title
              Text(
                event.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Time and location
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${event.startTime} - ${event.endTime}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    event.location,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Description
              if (event.description.isNotEmpty)
                Text(
                  event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(String startDate, String endDate) {
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);

    if (isSameDay(start, end)) {
      return DateFormat('MMM d, y').format(start);
    } else if (start.year == end.year && start.month == end.month) {
      return '${DateFormat('MMM d').format(start)}-${DateFormat('d, y').format(end)}';
    } else if (start.year == end.year) {
      return '${DateFormat('MMM d').format(start)}-${DateFormat('MMM d, y').format(end)}';
    } else {
      return '${DateFormat('MMM d, y').format(start)}-${DateFormat('MMM d, y').format(end)}';
    }
  }
}
