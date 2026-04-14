import 'package:flutter/material.dart';
import 'package:chanzo/globalclass/chanzo_color.dart';

class ClassStreamSelector extends StatefulWidget {
  final List<dynamic> classes;
  final int? initialClassId;
  final int? initialStreamId;
  final void Function(int? classId, int? streamId) onChanged;

  const ClassStreamSelector({
    super.key,
    required this.classes,
    required this.onChanged,
    this.initialClassId,
    this.initialStreamId,
  });

  @override
  State<ClassStreamSelector> createState() => _ClassStreamSelectorState();
}

class _ClassStreamSelectorState extends State<ClassStreamSelector> {
  int? _selectedClassId;
  int? _selectedStreamId;
  List<dynamic> _currentStreams = [];

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId;
    _selectedStreamId = widget.initialStreamId;

    // If an initial class is provided, load its streams immediately
    if (_selectedClassId != null && widget.classes.isNotEmpty) {
      _loadStreamsForClass(_selectedClassId!);
    }
  }

  void _loadStreamsForClass(int classId) {
    try {
      final selectedClass = widget.classes.firstWhere(
            (c) => c['id'] == classId,
        orElse: () => null,
      );

      if (selectedClass != null && selectedClass['streams'] != null) {
        _currentStreams = List<dynamic>.from(selectedClass['streams']);
      } else {
        _currentStreams = [];
      }
    } catch (e) {
      _currentStreams = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- CLASS DROPDOWN ---
        Text(
          "Select Class",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: _selectedClassId,
          hint: const Text('Choose a class'),
          decoration: _dropdownDecoration(),
          items: widget.classes.map((c) {
            return DropdownMenuItem<int>(
              value: c['id'] as int,
              child: Text(c['name']?.toString() ?? 'Unknown'),
            );
          }).toList(),
          onChanged: (newClassId) {
            if (newClassId == null) return;

            setState(() {
              _selectedClassId = newClassId;
              _selectedStreamId = null; // Reset stream when class changes
              _loadStreamsForClass(newClassId);
            });

            // Notify parent
            widget.onChanged(_selectedClassId, _selectedStreamId);
          },
        ),

        const SizedBox(height: 16),

        // --- STREAM DROPDOWN ---
        Text(
          "Select Stream",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: _selectedStreamId,
          hint: Text(_selectedClassId == null
              ? 'Select a class first'
              : (_currentStreams.isEmpty ? 'No streams available' : 'Choose a stream')),
          decoration: _dropdownDecoration(),
          // Disable the dropdown if no streams are available
          items: _currentStreams.isEmpty ? null : _currentStreams.map((s) {
            return DropdownMenuItem<int>(
              value: s['id'] as int,
              child: Text(s['name']?.toString() ?? 'Unknown'),
            );
          }).toList(),
          onChanged: _currentStreams.isEmpty ? null : (newStreamId) {
            setState(() {
              _selectedStreamId = newStreamId;
            });

            // Notify parent
            widget.onChanged(_selectedClassId, _selectedStreamId);
          },
        ),
      ],
    );
  }

  // Shared styling to keep UI consistent with your app
  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ChanzoColors.primary, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}