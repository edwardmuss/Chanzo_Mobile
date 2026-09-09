import 'package:flutter/material.dart';

import 'transport_api.dart';

/// Every term this child has ridden, and what each one cost.
///
/// Kept as history rather than as "their bus": a child who rode two-way in
/// Term 1, was dropped in Term 2 and came back on another route in Term 3 has
/// three true answers, and a single current value would erase two of them
/// along with what each was charged. A dropped term keeps its row so the gap is
/// visible rather than silently missing.
class TransportHistoryScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const TransportHistoryScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<TransportHistoryScreen> createState() => _TransportHistoryScreenState();
}

class _TransportHistoryScreenState extends State<TransportHistoryScreen> {
  Map<String, dynamic>? _data;
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
      final data = await TransportApi.childHistory(widget.studentId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = TransportApi.errorText(e, 'Could not load the history.');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final terms = List<Map<String, dynamic>>.from(_data?['terms'] ?? []);
    final recent = List<Map<String, dynamic>>.from(_data?['recent'] ?? []);

    return Scaffold(
      appBar: AppBar(title: Text('${widget.studentName} — bus')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _empty(Icons.wifi_off, _error!)
                : terms.isEmpty
                    ? _empty(Icons.history, 'This child has never been on a school bus.')
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          _totalCard(),
                          const SizedBox(height: 8),
                          const _Heading('Every term on the bus'),
                          ...terms.map(_termCard),
                          if (recent.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const _Heading('Recent journeys'),
                            ...recent.map(_eventTile),
                          ],
                        ],
                      ),
      ),
    );
  }

  Widget _empty(IconData icon, String text) => ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 100),
          Icon(icon, size: 56, color: Colors.grey),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        ],
      );

  Widget _totalCard() {
    final total = (_data?['total_charged'] as num?)?.toDouble() ?? 0;

    return Card(
      elevation: 0,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Charged for terms actually ridden',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(
              total.toStringAsFixed(2),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'A term that was dropped had its charge reversed, so it is not counted here.',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _termCard(Map<String, dynamic> t) {
    final dropped = t['status'] != 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${t['term']}  ·  ${t['session'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  ((t['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: dropped ? TextDecoration.lineThrough : null,
                    color: dropped ? Colors.grey : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _line(Icons.route_outlined, [t['zone'], t['stop']]),
            _line(Icons.directions_bus_outlined, [t['bus'], t['driver'], t['attendant']]),
            _line(Icons.swap_horiz, [t['direction']]),
            if (dropped)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Dropped this term — charge reversed'
                  '${t['dropped_reason'] != null ? ' · ${t['dropped_reason']}' : ''}',
                  style: const TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, List<dynamic> parts) {
    final text = parts.where((p) => p != null && '$p'.isNotEmpty).join(' · ');
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _eventTile(Map<String, dynamic> e) {
    final icon = switch (e['type']) {
      'absent' => (Icons.cancel_outlined, Colors.red),
      'alighted' => (Icons.place_outlined, Colors.blue),
      _ => (Icons.check_circle_outline, Colors.green),
    };

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon.$1, color: icon.$2, size: 20),
      title: Text(e['label'] ?? '', style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        [e['at'], e['bus']].where((v) => v != null).join(' · '),
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: .6,
            color: Colors.grey,
          ),
        ),
      );
}
