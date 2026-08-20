import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/mock_data_service.dart';
import '../../models/beach_model.dart';
import '../../widgets/admin/create_booking_dialog.dart';
import '../../widgets/admin/admin_scaffold.dart';

class BookingsManagementScreen extends StatefulWidget {
  const BookingsManagementScreen({super.key});

  @override
  State<BookingsManagementScreen> createState() => _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends State<BookingsManagementScreen> {
  DateTime _selectedMonth = DateTime.now();
  String _filterStatus = 'all'; // all, paid, unpaid
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    debugPrint('[BookingsManagement] Initializing...');
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);
    final bookings = _getFilteredBookings(dataService);
    final umbrellas = dataService.umbrellas;



    return AdminScaffold(
      title: 'Calendario Planner',
      selectedIndex: 6,
      actions: [
        IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Nuova Prenotazione',
            onPressed: () => _showCreateBookingDialog(context, dataService),
        ),
        IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              debugPrint('[BookingsManagement] Refreshing...');
              setState(() {});
            },
        ),
      ],
      child: Column(
        children: [
          _buildStatsBar(dataService, bookings),
          _buildFiltersBar(),
          _buildMonthSelector(),
          Expanded(
            child: _buildGanttCalendar(umbrellas, bookings),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(MockDataService dataService, List<Booking> bookings) {
    final totalBookings = bookings.length;
    final paidBookings = bookings.where((b) => b.isPaid).length;
    final unpaidBookings = totalBookings - paidBookings;
    final totalRevenue = bookings.where((b) => b.isPaid).fold(0.0, (sum, b) => sum + b.totalPrice);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Totale', totalBookings.toString(), Icons.book, Colors.blue),
          _buildStatCard('Pagati', paidBookings.toString(), Icons.check_circle, Colors.green),
          _buildStatCard('Da incassare', unpaidBookings.toString(), Icons.warning, Colors.orange),
          _buildStatCard('Incasso', '€${totalRevenue.toStringAsFixed(0)}', Icons.euro, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cerca per nome cliente...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                debugPrint('[BookingsManagement] Search: $value');
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _filterStatus,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tutti')),
              DropdownMenuItem(value: 'paid', child: Text('Pagati')),
              DropdownMenuItem(value: 'unpaid', child: Text('Non Pagati')),
            ],
            onChanged: (value) {
              debugPrint('[BookingsManagement] Filter: $value');
              setState(() => _filterStatus = value!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy', 'it_IT').format(_selectedMonth),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGanttCalendar(List<MapElement> umbrellas, List<Booking> bookings) {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with days
              _buildCalendarHeader(daysInMonth),
              const SizedBox(height: 8),
              // Rows for each umbrella
              ...umbrellas.map((umbrella) => _buildUmbrellaRow(umbrella, bookings, daysInMonth)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarHeader(int daysInMonth) {
    return Row(
      children: [
        // Umbrella label column
        Container(
          width: 100,
          padding: const EdgeInsets.all(8),
          child: const Text('Ombrellone', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        // Day columns
        ...List.generate(daysInMonth, (index) {
          final day = index + 1;
          final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
          final isToday = DateTime.now().day == day &&
              DateTime.now().month == _selectedMonth.month &&
              DateTime.now().year == _selectedMonth.year;

          return Container(
            width: 40,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isToday ? Colors.blue.shade100 : null,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                children: [
                  Text(
                    DateFormat('E', 'it_IT').format(date).substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    day.toString(),
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? Colors.blue : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUmbrellaRow(MapElement umbrella, List<Booking> bookings, int daysInMonth) {
    final umbrellaBookings = bookings.where((b) => b.umbrellaId == umbrella.id).toList();

    return Row(
      children: [
        // Umbrella label
        Container(
          width: 100,
          height: 60,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              umbrella.label ?? '${umbrella.row}-${umbrella.number}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        // Calendar cells
        Stack(
          children: [
            // Background grid
            Row(
              children: List.generate(daysInMonth, (index) {
                return Container(
                  width: 40,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                );
              }),
            ),
            // Booking bars
            ...umbrellaBookings.map((booking) => _buildBookingBar(booking, daysInMonth)),
          ],
        ),
      ],
    );
  }

  Widget _buildBookingBar(Booking booking, int daysInMonth) {
    final startDay = booking.startDate.day;
    final endDay = booking.endDate.day;
    
    // Calculate position and width
    final startOffset = (startDay - 1) * 40.0;
    final width = ((endDay - startDay + 1) * 40.0).clamp(40.0, daysInMonth * 40.0);

    final color = booking.isPaid ? Colors.green : Colors.orange;

    return Positioned(
      left: startOffset,
      top: 5,
      child: GestureDetector(
        onTap: () {
          debugPrint('[BookingsManagement] Booking tapped: ${booking.id}');
          _showBookingDetails(booking, Provider.of<MockDataService>(context, listen: false));
        },
        child: Container(
          width: width,
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 2),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Customer Name
              Text(
                booking.customerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // 2. Package Name & Pax (Inferred)
              Consumer<MockDataService>(
                builder: (context, data, _) {
                  final pkg = data.packages.firstWhere((p) => p.id == booking.packageId, 
                      orElse: () => ServicePackage(id: '?', name: 'Standard', items: [], defaultBasePrice: 0));
                  return Text(
                    '${pkg.name} (2 pax)', // Hardcoded 2 pax for now or pkg description
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                }
              ),
              // 3. Date Range
              Text(
                 '${DateFormat('dd/MM').format(booking.startDate)} - ${DateFormat('dd/MM').format(booking.endDate)}',
                 style: const TextStyle(color: Colors.white70, fontSize: 9),
                 maxLines: 1,
                 overflow: TextOverflow.clip,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Booking> _getFilteredBookings(MockDataService dataService) {
    var bookings = dataService.bookings;

    // Filter by month
    bookings = bookings.where((b) {
      return b.startDate.year == _selectedMonth.year && b.startDate.month == _selectedMonth.month;
    }).toList();

    // Filter by payment status
    if (_filterStatus == 'paid') {
      bookings = bookings.where((b) => b.isPaid).toList();
    } else if (_filterStatus == 'unpaid') {
      bookings = bookings.where((b) => !b.isPaid).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      bookings = bookings.where((b) => b.customerName.toLowerCase().contains(_searchQuery)).toList();
    }

    return bookings;
  }

  void _showBookingDetails(Booking booking, MockDataService dataService) {
    context.push('/admin/bookings/${booking.id}');
  }

  void _showCreateBookingDialog(BuildContext context, MockDataService dataService) {
    showDialog(
      context: context,
      builder: (context) => CreateBookingDialog(dataService: dataService),
    );
  }
}
