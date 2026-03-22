import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class RescheduleScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const RescheduleScreen({super.key, required this.booking});
  @override
  State<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends State<RescheduleScreen> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _time = '09:00';
  bool _loading = false;

  final _timeSlots = ['07:00', '08:00', '09:00', '10:00', '11:00', '14:00', '15:00', '16:00', '17:00'];

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      await api.rescheduleBooking(
        widget.booking['id'],
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
        newTime: '$_time:00',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking rescheduled successfully! ✓'), backgroundColor: AppTheme.success));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reschedule Booking')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Current booking info
        GkmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Current Schedule', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Text(widget.booking['booking_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
          Text('Scheduled: ${widget.booking['scheduled_date']}', style: const TextStyle(color: AppTheme.textSecondary)),
        ])),
        const SizedBox(height: 24),

        // Date picker
        const Text('New Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        GkmCard(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime.now().add(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              builder: (ctx, child) => Theme(
                data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
                child: child!,
              ),
            );
            if (d != null) setState(() => _date = d);
          },
          child: Row(children: [
            const Icon(Icons.calendar_today, color: AppTheme.primary),
            const SizedBox(width: 12),
            Text('${_date.day}/${_date.month}/${_date.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ]),
        ),
        const SizedBox(height: 24),

        // Time picker
        const Text('Preferred Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: _timeSlots.map((slot) {
            final sel = slot == _time;
            return GestureDetector(
              onTap: () => setState(() => _time = slot),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? AppTheme.primary : AppTheme.border),
                ),
                child: Text(
                  _formatTime(slot),
                  style: TextStyle(
                    color: sel ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600, fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        // Info note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, color: AppTheme.warning, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Rescheduling is subject to gardener availability. You\'ll receive WhatsApp confirmation.',
              style: TextStyle(color: AppTheme.warning, fontSize: 12),
            )),
          ]),
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Reschedule to ${_date.day}/${_date.month} at ${_formatTime(_time)}'),
        ),
      ]),
    ),
  );

  String _formatTime(String t) {
    final parts = t.split(':');
    final h = int.parse(parts[0]);
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$h12:00 $ampm';
  }
}
