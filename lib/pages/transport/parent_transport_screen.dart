import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../globalclass/chanzo_color.dart';
import 'transport_api.dart';
import 'transport_history_screen.dart';

/// Where my child's bus is, right now.
///
/// One card per child who is on a bus this term. Everything on it comes from
/// the server already worded — the phone renders a sentence, it does not
/// compose one, so the app and the web page can never tell a parent two
/// different things about the same child.
///
/// There is no map here on purpose. A tile layer is a dependency, a download on
/// a slow connection, and a thing to keep working; the sentence and the two
/// distances answer the question, and "Show on map" hands the coordinate to the
/// maps app the phone already has.
class ParentTransportScreen extends StatefulWidget {
  const ParentTransportScreen({super.key});

  @override
  State<ParentTransportScreen> createState() => _ParentTransportScreenState();
}

class _ParentTransportScreenState extends State<ParentTransportScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();

    // Twenty seconds, and only while this screen is on top: a bus reports
    // every thirty, so polling faster would spend a parent's data to show them
    // the same coordinate twice.
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _loading = true);

    try {
      final rows = await TransportApi.myChildren();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = TransportApi.errorText(e, 'Could not reach the school right now.');
        _loading = false;
      });
    }
  }

  Future<void> _openMap(Map<String, dynamic> row) async {
    final pos = row['position'];
    if (pos == null) return;

    final uri = Uri.parse('geo:${pos['lat']},${pos['lng']}?q=${pos['lat']},${pos['lng']}(School bus)');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=${pos['lat']},${pos['lng']}'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School bus'),
        actions: [
          IconButton(onPressed: () => _load(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _message(Icons.wifi_off, _error!);
    }

    if (_rows.isEmpty) {
      return _message(
        Icons.directions_bus_outlined,
        'No child on your account is on a school bus this term.\n\n'
        'Ask the school office if you think this is wrong.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          color: Colors.blue.shade50,
          elevation: 0,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Times are estimates from where the bus last reported, not a promise. '
              'Distance is measured to your child\'s bus stop — not to your house — '
              'because that is where the bus actually calls.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._rows.map(_card),
      ],
    );
  }

  Widget _message(IconData icon, String text) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 56, color: Colors.grey),
        const SizedBox(height: 16),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _card(Map<String, dynamic> row) {
    final position = row['position'];
    final stale = position != null && position['stale'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row['name'] ?? 'Student',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      Text(
                        [row['class'], row['stop']].where((v) => v != null).join(' · '),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (row['bus'] != null)
                  Chip(
                    label: Text(row['bus'], style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              // The headline, not the ETA. A child who has already arrived has
              // nothing left to count down to, and "Not known yet" over "arrived
              // at school at 12:05" is a sentence that reads as a fault.
              row['headline'] ?? row['eta_phrase'] ?? 'Not known yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _stateColour(row['state']),
              ),
            ),
            const SizedBox(height: 4),
            Text(row['state_note'] ?? '', style: const TextStyle(fontSize: 13)),

            const SizedBox(height: 12),
            _termPanel(Map<String, dynamic>.from(row['term'] ?? {})),

            const SizedBox(height: 12),
            Row(
              children: [
                _stat('To the stop', _km(row['to_stop'])),
                _stat('To school', _km(row['to_school'])),
                _stat('Last heard', position?['at'] ?? '—'),
              ],
            ),

            if (stale)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No update for a few minutes — this is where the bus last reported.',
                  style: TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ),

            const Divider(height: 24),
            Row(
              children: [
                if (position != null)
                  TextButton.icon(
                    onPressed: () => _openMap(row),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Show on map'),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Get.to(() => TransportHistoryScreen(
                        studentId: row['student_id'],
                        studentName: row['name'] ?? 'Student',
                      )),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('History'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Which bus, which stop, what are we paying — asked far more often than
  /// "where is it right now", and it should not need a second screen.
  Widget _termPanel(Map<String, dynamic> t) {
    if (t.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(children: [
            _cell('Route', t['route']),
            _cell('Stop', t['stop'] ?? 'Not set'),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _cell('Bus', t['bus']),
            _cell('Driver', t['driver'] ?? 'Not recorded'),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _cell('Trip type', t['direction']),
            _cell('Charged this term',
                ((t['amount'] as num?) ?? 0).toStringAsFixed(2)),
          ]),
        ],
      ),
    );
  }

  Widget _cell(String label, dynamic value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text('${value ?? '—'}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _km(dynamic eta) {
    if (eta == null) return '—';
    final v = eta['road_km'];
    return v == null ? '—' : '${(v as num).toStringAsFixed(1)} km';
  }

  Color _stateColour(String? state) {
    switch (state) {
      case 'absent':
        return Colors.red.shade700;
      case 'alighted':
        return Colors.blue.shade700;
      case 'boarded':
        return Colors.green.shade700;
      default:
        return ChanzoColors.primary;
    }
  }
}
