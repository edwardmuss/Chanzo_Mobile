import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'transport_api.dart';

/// The boarding list, for a phone at a roadside.
///
/// ---------------------------------------------------------------------------
/// THIS SCREEN IS HELD IN ONE HAND
/// ---------------------------------------------------------------------------
/// Forty children are waiting, the bus is blocking a lane, and the person
/// holding this has one thumb free. So: one tap per child, targets big enough
/// to hit while standing, no confirmation dialogs, and the state of the whole
/// list readable at arm's length without reading a word.
///
/// The words on the buttons come from the server. The same three marks mean
/// opposite places on the two legs — in the morning getting off is arriving at
/// school, in the afternoon it is being dropped at the child's own stop — and
/// the phone is the wrong place to decide which.
///
/// Tracking runs while this screen is open. That is deliberate: the position is
/// only useful during a journey, and a background service that keeps reporting
/// after the bus is parked would drain a battery and follow a driver home.
class CrewBoardingScreen extends StatefulWidget {
  final int runId;

  const CrewBoardingScreen({super.key, required this.runId});

  @override
  State<CrewBoardingScreen> createState() => _CrewBoardingScreenState();
}

class _CrewBoardingScreenState extends State<CrewBoardingScreen> {
  Map<String, dynamic>? _run;
  bool _loading = true;
  String? _error;

  final Set<int> _picked = {};
  StreamSubscription<Position>? _positions;
  Position? _lastFix;
  DateTime? _lastSent;
  String _trackingNote = 'Tracking off';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _positions?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------------ data

  Future<void> _load() async {
    try {
      final run = await TransportApi.run(widget.runId);
      if (!mounted) return;

      setState(() {
        _run = run;
        _error = null;
        _loading = false;
      });

      if (run['is_open'] == true) _startTracking();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = TransportApi.errorText(e, 'Could not load the boarding list.');
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _riders =>
      List<Map<String, dynamic>>.from(_run?['riders'] ?? []);

  Map<String, dynamic> get _labels =>
      Map<String, dynamic>.from(_run?['labels'] ?? {});

  bool get _isOpen => _run?['is_open'] == true;

  // -------------------------------------------------------------- tracking

  Future<void> _startTracking() async {
    if (_positions != null) return;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _trackingNote = 'Location refused — the bus will not appear on the map');
      return;
    }

    setState(() => _trackingNote = 'Tracking…');

    _positions = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      ),
    ).listen((pos) {
      _lastFix = pos;

      // Every thirty seconds at most. A bus does not need reporting more often
      // than that, and a phone that posts on every fix spends a driver's data
      // and battery for no extra truth.
      final now = DateTime.now();
      if (_lastSent != null && now.difference(_lastSent!).inSeconds < 30) return;
      _lastSent = now;

      TransportApi.position(
        runId: widget.runId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        speedKph: pos.speed * 3.6,
        heading: pos.heading,
        accuracyM: pos.accuracy,
      ).then((ok) {
        if (!mounted) return;
        setState(() => _trackingNote =
            ok ? 'Sending · ${TimeOfDay.now().format(context)}' : 'No signal — it will retry');
      });
    }, onError: (_) {
      if (!mounted) return;
      // A lost fix on a Kenyan road is normal and the next one is close.
      setState(() => _trackingNote = 'Weak signal');
    });
  }

  // --------------------------------------------------------------- marking

  Future<void> _mark(int studentId, String type) async {
    try {
      await TransportApi.mark(
        runId: widget.runId,
        studentId: studentId,
        eventType: type,
        latitude: _lastFix?.latitude,
        longitude: _lastFix?.longitude,
      );

      // Optimistic: the row changing colour is the confirmation. A toast per
      // child would be forty toasts in two minutes.
      setState(() {
        for (final r in _riders) {
          if (r['student_id'] == studentId) {
            r['state'] = type;
            r['at'] = TimeOfDay.now().format(context);
          }
        }
      });
    } catch (e) {
      _say(TransportApi.errorText(e, 'That did not save. Try again.'));
    }
  }

  Future<void> _bulk(String type, List<int> ids, String title, String body) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Mark them')),
        ],
      ),
    );

    if (go != true) return;

    try {
      final message = await TransportApi.markBulk(
        runId: widget.runId,
        eventType: type,
        studentIds: ids,
        latitude: _lastFix?.latitude,
        longitude: _lastFix?.longitude,
      );

      _picked.clear();
      _say(message);
      await _load();
    } catch (e) {
      _say(TransportApi.errorText(e, 'Could not save that.'));
    }
  }

  void _arrived() {
    final aboard = _riders
        .where((r) => r['state'] == 'boarded')
        .map<int>((r) => r['student_id'] as int)
        .toList();

    if (aboard.isEmpty) {
      _say('Nobody is aboard yet — only a child who got on can get off.');
      return;
    }

    _bulk(
      'alighted',
      aboard,
      '${_labels['bulk'] ?? 'Arrived'}?',
      '${aboard.length} child(ren) are aboard and will be marked.\n\n'
      'Anyone marked absent is skipped and stays absent. '
      'If parent alerts are on, this sends ${aboard.length} message(s).',
    );
  }

  Future<void> _close() async {
    final unmarked = _riders.where((r) => (r['state'] ?? '') == '').length;

    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Close this run?'),
        content: Text(unmarked > 0
            ? '$unmarked child(ren) have not been marked.\n\n'
                'Closing records them as absent and, if alerts are on, tells their parents. '
                'Mark them first if they were on board.'
            : 'Everybody has been accounted for.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Close run')),
        ],
      ),
    );

    if (go != true) return;

    try {
      final message = await TransportApi.completeRun(widget.runId);
      _positions?.cancel();
      _positions = null;
      _say(message);
      await _load();
    } catch (e) {
      _say(TransportApi.errorText(e, 'Could not close the run.'));
    }
  }

  void _say(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ------------------------------------------------------------------- ui

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Boarding')),
        body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(_error!))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_run?['leg_label']} · ${_run?['bus'] ?? 'Bus'}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(_trackingNote, style: const TextStyle(fontSize: 11)),
          ),
        ),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          _tally(),
          if (_isOpen) _bulkBar(),
          Expanded(child: _list()),
        ],
      ),
      bottomNavigationBar: _isOpen
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: _close,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Close run'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: Colors.green.shade700,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _tally() {
    int count(String s) => _riders.where((r) => r['state'] == s).length;

    final unmarked = _riders.where((r) => (r['state'] ?? '') == '').length;

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stat('${_riders.length}', 'Expected', Colors.blueGrey),
          _stat('${count('boarded')}', _labels['boarded'] ?? 'Boarded', Colors.green),
          _stat('${count('alighted')}', _labels['alighted'] ?? 'Off', Colors.blue),
          _stat('${count('absent')}', _labels['absent'] ?? 'Absent', Colors.red),
          _stat('$unmarked', 'Not marked', Colors.orange),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color colour) => Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colour)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      );

  Widget _bulkBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: _arrived,
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: Text(_labels['bulk'] ?? 'Arrived'),
            ),
          ),
          if (_picked.isNotEmpty) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _bulk(
                'boarded',
                _picked.toList(),
                'Mark ${_picked.length} boarded?',
                'If parent alerts are on, this sends ${_picked.length} message(s).',
              ),
              child: Text('Board ${_picked.length}'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _list() {
    if (_riders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No children are assigned to this trip for the term.\n\n'
            'The office assigns riders under Transport → Assignments.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    String? lastStop;
    final tiles = <Widget>[];

    for (final r in _riders) {
      if (r['stop'] != lastStop) {
        lastStop = r['stop'];
        tiles.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(
            [r['stop_seq'], r['stop']].where((v) => v != null).join('. ').toUpperCase(),
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: .6, color: Colors.grey),
          ),
        ));
      }

      tiles.add(_riderTile(r));
    }

    return ListView(children: tiles);
  }

  Widget _riderTile(Map<String, dynamic> r) {
    final state = (r['state'] ?? '') as String;
    final id = r['student_id'] as int;

    final tint = switch (state) {
      'boarded' => Colors.green.shade50,
      'alighted' => Colors.blue.shade50,
      'absent' => Colors.red.shade50,
      _ => null,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: tint,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          // Absent children are never swept into a selection. They are the
          // reason anybody reads this list.
          if (_isOpen && state != 'absent')
            Checkbox(
              value: _picked.contains(id),
              onChanged: (v) => setState(() => v == true ? _picked.add(id) : _picked.remove(id)),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text(
                  [
                    r['admission_no'],
                    r['class'],
                    if (state.isNotEmpty) '${_labels[state] ?? state} ${r['at'] ?? ''}'.trim(),
                  ].where((v) => v != null && '$v'.isNotEmpty).join(' · '),
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          if (_isOpen) ...[
            _tap(Icons.check, Colors.green, () => _mark(id, 'boarded'), _labels['boarded']),
            _tap(Icons.logout, Colors.blue, () => _mark(id, 'alighted'), _labels['alighted']),
            _tap(Icons.close, Colors.red, () => _mark(id, 'absent'), _labels['absent']),
          ],
        ],
      ),
    );
  }

  Widget _tap(IconData icon, Color colour, VoidCallback onTap, String? tip) => IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: colour),
        tooltip: tip,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: EdgeInsets.zero,
      );
}
