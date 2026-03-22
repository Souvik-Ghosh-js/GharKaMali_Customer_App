import 'raise_complaint_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingDetailScreen({super.key, required this.booking});
  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late Map _b;
  bool _loading = false;
  double _rating = 5;
  final _reviewCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _b = widget.booking; _reload(); }

  Future<void> _reload() async {
    try {
      final res = await context.read<ApiService>().getBookingDetail(_b['id']);
      setState(() => _b = res['data']);
    } catch (_) {}
  }

  Future<void> _cancel() async {
    final reason = await _showCancelDialog();
    if (reason == null) return;
    setState(() => _loading = true);
    try {
      await context.read<ApiService>().cancelBooking(_b['id'], reason: reason);
      _snack('Booking cancelled');
      _reload();
    } catch (e) { _snack(e.toString()); }
    setState(() => _loading = false);
  }

  Future<String?> _showCancelDialog() async {
    String reason = '';
    return showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Cancel Booking'),
      content: TextField(onChanged: (v) => reason = v, decoration: const InputDecoration(hintText: 'Reason (optional)')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep')),
        TextButton(onPressed: () => Navigator.pop(ctx, reason), child: const Text('Cancel Booking', style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  Future<void> _submitRating() async {
    setState(() => _loading = true);
    try {
      await context.read<ApiService>().rateBooking(_b['id'], _rating.toInt(), review: _reviewCtrl.text.isNotEmpty ? _reviewCtrl.text : null);
      _snack('Thank you for your feedback!');
      _reload();
    } catch (e) { _snack(e.toString()); }
    setState(() => _loading = false);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final status = _b['status'] as String? ?? '';
    final canCancel = ['pending', 'assigned'].contains(status);
    final canRate = status == 'completed' && _b['rating'] == null;
    final gardener = _b['gardener'] as Map?;

    return Scaffold(
      appBar: AppBar(
        title: Text(_b['booking_number'] ?? 'Booking'),
        actions: [
          if (canCancel) ...[
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/reschedule', arguments: Map<String, dynamic>.from(_b)).then((r) { if (r == true) _reload(); }),
              child: const Text('Reschedule', style: TextStyle(color: AppTheme.primary)),
            ),
            TextButton(onPressed: _cancel, child: const Text('Cancel', style: TextStyle(color: Colors.red))),
          ],
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Status card
            GkmCard(child: Column(children: [
              Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.grass, color: AppTheme.primary, size: 26)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_b['booking_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  Text(_b['booking_type'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ])),
                GkmBadge(status),
              ]),
              const Divider(height: 28),
              _Row(Icons.calendar_today, 'Date', _b['scheduled_date'] ?? ''),
              _Row(Icons.location_on, 'Address', _b['service_address'] ?? ''),
              _Row(Icons.yard, 'Plants', '${_b['plant_count'] ?? 1}${(_b['extra_plants'] ?? 0) > 0 ? ' + ${_b['extra_plants']} extra' : ''}'),
              _Row(Icons.currency_rupee, 'Amount', '₹${_b['total_amount'] ?? 0}', bold: true),
            ])),

            const SizedBox(height: 16),

            // Pay now button for pending payments
            if (_b['payment_status'] == 'pending' && _b['status'] != 'cancelled') GkmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Payment Pending', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.warning)),
              const SizedBox(height: 6),
              Text('Amount due: ₹\${_b['total_amount'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/payment', arguments: {
                  'type': 'booking', 'booking_id': _b['id'],
                  'amount': double.tryParse(_b['total_amount']?.toString() ?? '0'),
                  'label': 'Booking \${_b['booking_number']}',
                }).then((_) => _reload()),
                icon: const Icon(Icons.payment),
                label: const Text('Pay Now via PayU'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
              ),
            ])),

            const SizedBox(height: 16),

            // Gardener card
            if (gardener != null) GkmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your Gardener', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              Row(children: [
                CircleAvatar(
                  radius: 28, backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text((gardener['name'] as String? ?? 'G')[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(gardener['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(gardener['phone'] ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
                  if (gardener['gardenerProfile']?['rating'] != null) Row(children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    Text(' ${gardener['gardenerProfile']['rating']}', style: const TextStyle(fontSize: 13)),
                  ]),
                ])),
                if (['assigned', 'en_route', 'arrived', 'in_progress'].contains(status))
                  Column(children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/track', arguments: _b['id'] as int),
                      child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.location_on, color: Colors.white)),
                    ),
                    const SizedBox(height: 4),
                    const Text('Track', style: TextStyle(fontSize: 10, color: AppTheme.primary)),
                  ]),
              ]),
            ])),

            const SizedBox(height: 16),

            // Work proof images
            if (_b['before_image'] != null || _b['after_image'] != null) GkmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Work Proof', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                if (_b['before_image'] != null) Expanded(child: Column(children: [
                  const Text('Before', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(_b['before_image'], height: 120, fit: BoxFit.cover)),
                ])),
                if (_b['before_image'] != null && _b['after_image'] != null) const SizedBox(width: 12),
                if (_b['after_image'] != null) Expanded(child: Column(children: [
                  const Text('After', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(_b['after_image'], height: 120, fit: BoxFit.cover)),
                ])),
              ]),
            ])),

            if (_b['before_image'] != null || _b['after_image'] != null) const SizedBox(height: 16),

            // Rating card
            if (canRate) GkmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Rate Your Experience', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Center(child: RatingBar.builder(
                initialRating: _rating, minRating: 1, itemSize: 40,
                itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (r) => setState(() => _rating = r),
              )),
              const SizedBox(height: 14),
              TextField(controller: _reviewCtrl, decoration: const InputDecoration(hintText: 'Write a review (optional)'), maxLines: 2),
              const SizedBox(height: 14),
              ElevatedButton(onPressed: _loading ? null : _submitRating, child: const Text('Submit Rating')),
            ])),

            // Add-on services button (for pending/assigned bookings)
          if (['pending','assigned'].contains(status)) GkmCard(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add-addons', arguments: {
                'booking_id': _b['id'],
                'booking_number': _b['booking_number'],
              }).then((r) { if (r == true) _reload(); }),
              icon: const Icon(Icons.add_circle_outline, size: 18, color: AppTheme.primary),
              label: const Text('Add Extra Services', style: TextStyle(color: AppTheme.primary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primary),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Raise complaint button (for completed bookings)
          if (_b['status'] == 'completed' || _b['status'] == 'failed') GkmCard(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/raise-complaint', arguments: Map<String, dynamic>.from(_b)),
              icon: const Icon(Icons.warning_amber_outlined, size: 18, color: Color(0xFFDC2626)),
              label: const Text('Raise a Complaint', style: TextStyle(color: Color(0xFFDC2626))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDC2626)),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),

          const SizedBox(height: 8),

          if (_b['rating'] != null) GkmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your Rating', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: List.generate(_b['rating'] as int, (_) => const Icon(Icons.star, color: Colors.amber, size: 20))),
              if (_b['review'] != null) ...[const SizedBox(height: 8), Text(_b['review'], style: const TextStyle(color: AppTheme.textSecondary))],
            ])),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon; final String label, value; final bool bold;
  const _Row(this.icon, this.label, this.value, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, size: 16, color: AppTheme.textSecondary),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      const Spacer(),
      Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, fontSize: bold ? 16 : 14))),
    ]),
  );
}
