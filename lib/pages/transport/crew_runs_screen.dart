import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'crew_boarding_screen.dart';
import 'transport_api.dart';

/// A driver's or attendant's day: two legs per trip they crew.
///
/// A leg with no run yet is shown too, as the row the Start button sits on.
/// Leaving it out would mean crew could only ever open journeys somebody in the
/// office had already begun — which is the opposite of the point.
///
/// Nobody is granted a "driver role" to see this. The office already records
/// who drives what on the trip itself; asking that, rather than a second list
/// of roles, means a swapped driver is right immediately instead of right once
/// somebody remembers to tick a box. See CrewService on the server.
class CrewRunsScreen extends StatefulWidget {
  const CrewRunsScreen({super.key});

  @override
  State<CrewRunsScreen> createState() => _CrewRunsScreenState();
}

class _CrewRunsScreenState extends State<CrewRunsScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final rows = await TransportApi.myRuns();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = TransportApi.errorText(e, 'Could not load today\'s runs.');
        _loading = false;
      });
    }
  }

  Future<void> _start(Map<String, dynamic> row) async {
    if (row['has_bus'] != true) {
      _say('This trip has no bus. The office sets one on the trip — the run has to '
          'record which vehicle actually carried the children.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Start the ${row['leg_label'].toString().toLowerCase()} run?'),
        content: Text(
          '${row['route']} · ${row['bus']}\n\n'
          'Starting opens the boarding list and begins tracking. '
          'Pressing Start twice gives you the same run, not a second one.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Start')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final run = await TransportApi.startRun(
        tripId: row['trip_id'],
        leg: row['leg'],
      );

      if (!mounted) return;
      await Get.to(() => CrewBoardingScreen(runId: run['run_id']));
      _load();
    } catch (e) {
      _say(TransportApi.errorText(e, 'Could not start the run.'));
    }
  }

  void _say(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My runs'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(32),
                    children: [
                      const SizedBox(height: 90),
                      const Icon(Icons.directions_bus_outlined, size: 56, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: _rows.map(_card).toList(),
                  ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> row) {
    final open = row['is_open'] == true;
    final done = row['status'] == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: open
              ? Colors.green.shade100
              : done
                  ? Colors.grey.shade200
                  : Colors.blue.shade50,
          child: Icon(
            row['leg'] == 'am' ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
            color: open ? Colors.green.shade800 : Colors.blueGrey,
          ),
        ),
        title: Text('${row['leg_label']} · ${row['route']}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text([
              row['bus'] ?? 'No bus set',
              if (row['my_role'] != null) 'you are the ${row['my_role']}',
              if (row['stops'] != null) '${row['stops']} stop(s)',
            ].join(' · '), style: const TextStyle(fontSize: 12)),
            if (open && row['started_at'] != null)
              Text('Running since ${row['started_at']}',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
            if (done) const Text('Finished', style: TextStyle(fontSize: 12)),
            if (row['has_bus'] != true)
              const Text('This trip has no bus — the office must set one',
                  style: TextStyle(fontSize: 11, color: Colors.orange)),
          ],
        ),
        trailing: open || done
            ? FilledButton.tonal(
                onPressed: () async {
                  await Get.to(() => CrewBoardingScreen(runId: row['run_id']));
                  _load();
                },
                child: Text(open ? 'Open' : 'View'),
              )
            : FilledButton(
                onPressed: () => _start(row),
                child: const Text('Start'),
              ),
      ),
    );
  }
}
