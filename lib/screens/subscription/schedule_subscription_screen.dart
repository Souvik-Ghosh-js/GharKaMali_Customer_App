import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ScheduleSubscriptionScreen extends StatefulWidget {
  final Map<String, dynamic> subscription;
  const ScheduleSubscriptionScreen(
      {super.key, required this.subscription});

  @override
  State<ScheduleSubscriptionScreen> createState() =>
      _ScheduleSubscriptionScreenState();
}

class _ScheduleSubscriptionScreenState
    extends State<ScheduleSubscriptionScreen> {
  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _selectedDays = {};
  bool _loading = false;

  late DateTime _minDate;
  late DateTime _maxDate;
  late int _totalVisits;
  late int _scheduledVisits;
  late int _remaining;

  @override
  void initState() {
    super.initState();
    final s = widget.subscription;
    _minDate = DateTime.parse(s['start_date']);
    _maxDate = DateTime.parse(s['end_date']);

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (_minDate.isBefore(tomorrow)) {
      _minDate =
          DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    }

    _focusedDay = _minDate;
    _totalVisits = s['visits_total'] ?? 0;
    _scheduledVisits = s['scheduled_visits_count'] ?? 0;
    _remaining = _totalVisits - _scheduledVisits;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (selectedDay.isBefore(_minDate) ||
        selectedDay.isAfter(_maxDate)) return;

    setState(() {
      final day = DateTime(
          selectedDay.year, selectedDay.month, selectedDay.day);
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        if (_selectedDays.length >= _remaining) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('You can only select up to $_remaining dates')));
          return;
        }
        _selectedDays.add(day);
      }
      _focusedDay = focusedDay;
    });
  }

  Future<void> _submit() async {
    if (_selectedDays.isEmpty) return;

    setState(() => _loading = true);
    try {
      // FIX: Use 'yyyy-MM-dd' (lowercase y and d) not 'YYYY-MM-DD'
      final dates = _selectedDays
          .map((d) => DateFormat('yyyy-MM-dd').format(d))
          .toList();
      await context
          .read<ApiService>()
          .selectSubscriptionDates(widget.subscription['id'], dates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Visits scheduled successfully!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Visits')),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Select $_remaining Dates',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 4),
            Text(
              'For your ${widget.subscription['plan']?['name'] ?? 'Subscription'} plan',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _Stat('Total', '$_totalVisits'),
              _Stat('Scheduled', '$_scheduledVisits'),
              _Stat('Remaining', '$_remaining'),
            ]),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: TableCalendar(
                  firstDay: _minDate,
                  lastDay: _maxDate,
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => _selectedDays
                      .contains(DateTime(day.year, day.month, day.day)),
                  onDaySelected: _onDaySelected,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                        color: AppTheme.primary, shape: BoxShape.circle),
                    todayDecoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle),
                    todayTextStyle: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold),
                    outsideDaysVisible: false,
                    weekendTextStyle:
                        const TextStyle(color: Colors.red),
                  ),
                  enabledDayPredicate: (day) =>
                      !day.isBefore(_minDate) && !day.isAfter(_maxDate),
                ),
              ),  // end TableCalendar container
              const SizedBox(height: 20),
              if (_selectedDays.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Selected Dates',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedDays
                      .map((d) => Chip(
                            label: Text(DateFormat('dd MMM').format(d)),
                            onDeleted: () =>
                                setState(() => _selectedDays.remove(d)),
                            deleteIcon:
                                const Icon(Icons.close, size: 14),
                            backgroundColor:
                                AppTheme.primary.withOpacity(0.1),
                            side: BorderSide.none,
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ]),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _selectedDays.isEmpty || _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    'Confirm ${_selectedDays.length} Visit${_selectedDays.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
      ]);
}
