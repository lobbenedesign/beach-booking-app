import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/mock_data_service.dart';
import '../../models/beach_model.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/admin/admin_scaffold.dart';
import '../../widgets/admin/beach_map_live_view.dart';
import 'admin_map_status_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  DateTime _rangeStart = DateTime.now();
  DateTime _rangeEnd = DateTime.now();
  bool _showPackages = true;

  bool get _isSingleDay => _isSameDay(_rangeStart, _rangeEnd);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);
    final bookings = dataService.bookings;
    final umbrellas = dataService.umbrellas;

    final occupiedToday = dataService.occupiedUmbrellasOn();
    final occupancy = dataService.occupancyRate();
    final arrivals = dataService.arrivalsOn();
    final departures = dataService.departuresOn();
    final revenueToday = dataService.revenueToday;
    final revenueMonth = dataService.revenueThisMonth;

    return AdminScaffold(
      title: 'Dashboard',
      selectedIndex: 0,
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          // Stat Cards Row
          Row(
            children: [
              _buildStatCard(
                context,
                'Occupazione Oggi',
                '${(occupancy * 100).toStringAsFixed(0)}%',
                Icons.beach_access,
                Colors.orange,
                subtitle: '$occupiedToday / ${umbrellas.length} ombrelloni',
              ),
              const SizedBox(width: 24),
              _buildStatCard(
                context,
                'Incasso Oggi',
                '€${revenueToday.toStringAsFixed(0)}',
                Icons.euro,
                Colors.green,
                subtitle: 'Mese: €${revenueMonth.toStringAsFixed(0)}',
              ),
              const SizedBox(width: 24),
              _buildStatCard(
                context,
                'Prenotazioni',
                '${bookings.length}',
                Icons.book_online,
                Colors.blue,
                subtitle: 'Totali registrate',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Arrivals / Departures today
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTodayList(
                  context,
                  dataService,
                  'Arrivi di Oggi',
                  Icons.login,
                  Colors.teal,
                  arrivals,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildTodayList(
                  context,
                  dataService,
                  'Partenze di Oggi',
                  Icons.logout,
                  Colors.deepOrange,
                  departures,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Live beach map: same layout as the editor, with bookings overlaid
          // for the selected day or date range.
          _buildLiveMapSection(context, dataService),
          const SizedBox(height: 24),

          // Occupancy by zone
          _buildOccupancyByZone(context, dataService),
          const SizedBox(height: 32),

          // Monitor Button
          Card(
            color: Colors.red.shade50,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.red.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.shield, color: Colors.red, size: 32),
              title: const Text('Monitoraggio Blocchi Mappa',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red)),
              subtitle: const Text('Gestisci sblocchi forzati in tempo reale'),
              trailing:
                  const Icon(Icons.arrow_forward_ios, color: Colors.red, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminMapStatusMonitorScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Prenotazioni Recenti',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 24),

          // Recent Bookings List
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: bookings.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: Text('Nessuna prenotazione',
                            style: TextStyle(color: Colors.grey))),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bookings.length > 5 ? 5 : bookings.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final booking = bookings[bookings.length - 1 - index];
                      final label = dataService.umbrellaLabel(booking.umbrellaId);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Text(
                            booking.customerName.isNotEmpty
                                ? booking.customerName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          booking.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Ombrellone: $label • ${DateFormat('dd/MM').format(booking.startDate)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: booking.isPaid
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: booking.isPaid
                                  ? Colors.green.shade200
                                  : Colors.orange.shade200,
                            ),
                          ),
                          child: Text(
                            booking.isPaid ? 'PAGATO' : 'DA PAGARE',
                            style: TextStyle(
                              color: booking.isPaid
                                  ? Colors.green.shade700
                                  : Colors.orange.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMapSection(BuildContext context, MockDataService data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Mappa Spiaggia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: _showPackages,
                      onChanged: (v) => setState(() => _showPackages = v),
                    ),
                    const Text('Pacchetti', style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => context.go('/admin/daily-map'),
                  icon: const Icon(Icons.open_in_full, size: 16),
                  label: const Text('Schermo intero'),
                ),
              ],
            ),
          ),
          _buildDateRangeBar(context),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: BeachMapLegend(),
          ),
          SizedBox(
            height: 480,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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

  Widget _buildDateRangeBar(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final label = _isSingleDay
        ? fmt.format(_rangeStart)
        : '${fmt.format(_rangeStart)} → ${fmt.format(_rangeEnd)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _rangeStart = _rangeStart.subtract(const Duration(days: 1));
              _rangeEnd = _rangeEnd.subtract(const Duration(days: 1));
            }),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _pickSingleDate(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    if (_isSameDay(_rangeStart, DateTime.now()) && _isSingleDay)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Chip(
                          label: Text('Oggi'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _rangeStart = _rangeStart.add(const Duration(days: 1));
              _rangeEnd = _rangeEnd.add(const Duration(days: 1));
            }),
          ),
          if (!_isSingleDay || !_isSameDay(_rangeStart, DateTime.now()))
            TextButton(
              onPressed: () => setState(() {
                _rangeStart = DateTime.now();
                _rangeEnd = DateTime.now();
              }),
              child: const Text('Oggi'),
            ),
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

  Widget _buildTodayList(BuildContext context, MockDataService data, String title,
      IconData icon, Color color, List<Booking> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${items.length}',
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Nessuno',
                  style: TextStyle(color: Colors.grey.shade500)),
            )
          else
            ...items.take(4).map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(b.customerName)),
                      Text(data.umbrellaLabel(b.umbrellaId),
                          style:
                              TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )),
          if (items.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('+${items.length - 4} altri',
                  style: TextStyle(color: color, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildOccupancyByZone(BuildContext context, MockDataService data) {
    final byZone = data.occupancyByZone();
    String zoneName(String id) {
      if (id == 'unassigned') return 'Senza zona';
      final z = data.zones.where((z) => z.id == id).firstOrNull;
      return z?.name ?? id[0].toUpperCase() + id.substring(1);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.grid_view, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Occupazione per Zona (oggi)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (byZone.isEmpty)
            const Text('Nessun ombrellone configurato',
                style: TextStyle(color: Colors.grey))
          else
            ...byZone.entries.map((e) {
              final occ = e.value.$1;
              final total = e.value.$2;
              final ratio = total == 0 ? 0.0 : occ / total;
              final color = ratio > 0.8
                  ? Colors.red
                  : (ratio > 0.5 ? Colors.orange : Colors.green);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(zoneName(e.key),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('$occ / $total (${(ratio * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color,
      {String? subtitle}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 24),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
