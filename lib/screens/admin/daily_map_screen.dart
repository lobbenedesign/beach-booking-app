import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/admin/admin_scaffold.dart';
import '../../widgets/admin/beach_map_live_view.dart';

/// Fullscreen, distraction-free version of the live beach map embedded in
/// the operator Dashboard — same widget, same day/range selection, just
/// without the stat cards and arrivals/departures lists around it. Reached
/// from the Dashboard's "Schermo intero" button, not from the main sidebar,
/// so the two screens don't duplicate the same navigation entry.
class DailyMapScreen extends StatefulWidget {
  const DailyMapScreen({super.key});

  @override
  State<DailyMapScreen> createState() => _DailyMapScreenState();
}

class _DailyMapScreenState extends State<DailyMapScreen> {
  DateTime _rangeStart = DateTime.now();
  DateTime _rangeEnd = DateTime.now();
  bool _showPackages = true;

  bool get _isSingleDay => _isSameDay(_rangeStart, _rangeEnd);

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Mappa Giornaliera',
      selectedIndex: 8,
      child: Column(
        children: [
          _buildDateBar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(child: BeachMapLegend()),
                Switch(
                  value: _showPackages,
                  onChanged: (v) => setState(() => _showPackages = v),
                ),
                const Text('Pacchetti', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BeachMapLiveView(
                  rangeStart: _rangeStart,
                  rangeEnd: _rangeEnd,
                  showPackages: _showPackages),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBar() {
    final fmt = DateFormat('dd/MM/yyyy');
    final label = _isSingleDay
        ? DateFormat('EEEE d MMMM yyyy', 'it_IT').format(_rangeStart)
        : '${fmt.format(_rangeStart)} → ${fmt.format(_rangeEnd)}';
    final isToday = _isSameDay(_rangeStart, DateTime.now()) && _isSingleDay;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _rangeStart = _rangeStart.subtract(const Duration(days: 1));
              _rangeEnd = _rangeEnd.subtract(const Duration(days: 1));
            }),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _pickSingleDate(context),
            child: Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (isToday)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Chip(
                label: Text('Oggi'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _rangeStart = _rangeStart.add(const Duration(days: 1));
              _rangeEnd = _rangeEnd.add(const Duration(days: 1));
            }),
          ),
          if (!isToday)
            TextButton(
              onPressed: () => setState(() {
                _rangeStart = DateTime.now();
                _rangeEnd = DateTime.now();
              }),
              child: const Text('Oggi'),
            ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _pickRange(context),
            icon: const Icon(Icons.date_range, size: 16),
            label: const Text('Intervallo'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSingleDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeStart,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _rangeStart = picked;
        _rangeEnd = picked;
      });
    }
  }

  Future<void> _pickRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _rangeStart, end: _rangeEnd),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _rangeStart = picked.start;
        _rangeEnd = picked.end;
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
