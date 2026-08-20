import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/restaurant_model.dart';
import '../../../services/mock_data_service.dart';
import '../../../widgets/admin/admin_scaffold.dart';
import '../../../widgets/admin/restaurant_table_map_live_view.dart';

class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  State<RestaurantDashboardScreen> createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  DateTime _date = DateTime.now();
  RestaurantShift _shift = RestaurantShift.cena;

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    final tables = data.restaurantTables;
    final todaysBookings = data.tableBookings
        .where((b) =>
            b.isOnDay(_date) &&
            b.shift == _shift &&
            b.status != TableBookingStatus.cancelled)
        .toList();
    final occupiedTables = todaysBookings.map((b) => b.tableId).toSet().length;
    final occupancy = tables.isEmpty ? 0.0 : occupiedTables / tables.length;
    final totalCovers = todaysBookings.fold<int>(0, (s, b) => s + b.partySize);
    final withAllergies =
        todaysBookings.where((b) => b.allergyNotes != null && b.allergyNotes!.isNotEmpty).length;
    final revenue = todaysBookings.fold<double>(0, (s, b) => s + b.totalPrice);

    return AdminScaffold(
      title: 'Dashboard Ristorante',
      selectedIndex: 30,
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          tooltip: 'Nuova prenotazione',
          onPressed: () => context.push('/admin/restaurant/bookings'),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Row(
            children: [
              _statCard('Occupazione Turno', '${(occupancy * 100).toStringAsFixed(0)}%',
                  Icons.table_restaurant, Colors.brown,
                  subtitle: '$occupiedTables / ${tables.length} tavoli'),
              const SizedBox(width: 24),
              _statCard('Prenotazioni', '${todaysBookings.length}', Icons.event_seat, Colors.teal,
                  subtitle: '$totalCovers coperti'),
              const SizedBox(width: 24),
              _statCard('Incasso Turno', '€${revenue.toStringAsFixed(0)}', Icons.euro, Colors.green,
                  subtitle: 'coperto €${data.restaurantCoverCharge.toStringAsFixed(0)}/persona'),
              const SizedBox(width: 24),
              _statCard('Allergie/Note', '$withAllergies', Icons.warning_amber, Colors.red,
                  subtitle: 'prenotazioni con note'),
            ],
          ),
          const SizedBox(height: 24),
          Container(
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
                      const Icon(Icons.map, color: Colors.brown),
                      const SizedBox(width: 8),
                      const Text('Mappa Sala',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                _buildDateShiftBar(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: RestaurantMapLegend(),
                ),
                SizedBox(
                  height: 460,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: RestaurantTableMapLiveView(date: _date, shift: _shift),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (data.restaurantZones.isNotEmpty) ...[
            _buildOccupancyByZone(data, tables, todaysBookings),
            const SizedBox(height: 24),
          ],
          Text('Prenotazioni del turno',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
            child: todaysBookings.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Nessuna prenotazione per questo turno', style: TextStyle(color: Colors.grey))),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todaysBookings.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final b = todaysBookings[index];
                      final hasBeach = data.userHasBeachBooking(b.userId);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.brown.shade50,
                          child: Text(b.customerName.isNotEmpty ? b.customerName[0].toUpperCase() : '?',
                              style: TextStyle(color: Colors.brown.shade700, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(b.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            'Tavolo ${data.restaurantTableLabel(b.tableId)} · ${b.partySize} persone'
                            '${hasBeach ? ' · ha anche prenotazione spiaggia' : ''}'),
                        trailing: b.allergyNotes != null && b.allergyNotes!.isNotEmpty
                            ? const Icon(Icons.warning_amber, color: Colors.red)
                            : null,
                        onTap: () => context.push('/admin/restaurant/bookings/${b.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateShiftBar() {
    final isToday = _isSameDay(_date, DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.brown.shade50,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _date = _date.subtract(const Duration(days: 1))),
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: Row(
              children: [
                Text(DateFormat('EEEE d MMMM', 'it_IT').format(_date),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (isToday)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Chip(label: Text('Oggi'), visualDensity: VisualDensity.compact),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _date = _date.add(const Duration(days: 1))),
          ),
          const Spacer(),
          SegmentedButton<RestaurantShift>(
            segments: const [
              ButtonSegment(value: RestaurantShift.pranzo, label: Text('Pranzo')),
              ButtonSegment(value: RestaurantShift.cena, label: Text('Cena')),
            ],
            selected: {_shift},
            onSelectionChanged: (s) => setState(() => _shift = s.first),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyByZone(
      MockDataService data, List<RestaurantTable> tables, List<TableBooking> todaysBookings) {
    final occupiedTableIds = todaysBookings.map((b) => b.tableId).toSet();
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
              Text('Occupazione per Zona (turno)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...data.restaurantZones.map((z) {
            final zoneTables = tables.where((t) => t.zoneId == z.id).toList();
            final occ = zoneTables.where((t) => occupiedTableIds.contains(t.id)).length;
            final total = zoneTables.length;
            final ratio = total == 0 ? 0.0 : occ / total;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(z.name, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                      valueColor: AlwaysStoppedAnimation(Color(z.colorValue)),
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

  Widget _statCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 24),
            Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ],
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
