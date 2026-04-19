import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../theme.dart';

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
  void initState() {
    super.initState();
    _b = widget.booking;
    _reload();
  }

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
    } catch (e) {
      _snack(e.toString());
    }
    setState(() => _loading = false);
  }

  Future<String?> _showCancelDialog() async {
    String reason = '';
    return showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Cancel Booking'),
              content: TextField(
                  onChanged: (v) => reason = v, decoration: const InputDecoration(hintText: 'Reason (optional)')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, reason),
                    child: const Text('Cancel Booking', style: TextStyle(color: Colors.red))),
              ],
            ));
  }

  Future<void> _submitRating() async {
    setState(() => _loading = true);
    try {
      await context.read<ApiService>().rateBooking(_b['id'], _rating.toInt(),
          review: _reviewCtrl.text.isNotEmpty ? _reviewCtrl.text : null);
      _snack('Thank you for your feedback!');
      _reload();
    } catch (e) {
      _snack(e.toString());
    }
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_b['booking_number'] ?? 'Booking Detail'),
        actions: [
          if (canCancel)
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () {
                showModalBottomSheet(
                    context: context,
                    builder: (ctx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.calendar_month_rounded),
                                title: const Text("Reschedule"),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Navigator.pushNamed(context, '/reschedule',
                                          arguments: Map<String, dynamic>.from(_b))
                                      .then((r) {
                                    if (r == true) _reload();
                                  });
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                                title: const Text("Cancel Booking", style: TextStyle(color: Colors.red)),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _cancel();
                                },
                              ),
                            ],
                          ),
                        ));
              },
            )
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Status Header
            RoundedCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.grass_rounded, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_b['booking_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text(_b['booking_type']?.toString().toUpperCase() ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      StatusChip(label: status.toUpperCase(), color: _getStatusColor(status)),
                    ],
                  ),
                  const Divider(height: 32),
                  _DetailRow(icon: Icons.calendar_today_rounded, label: "Scheduled for", value: _b['scheduled_date'] ?? 'TBD'),
                  _DetailRow(icon: Icons.location_on_rounded, label: "Address", value: _b['service_address'] ?? '--'),
                  _DetailRow(icon: Icons.yard_rounded, label: "Plants", value: "${_b['plant_count'] ?? 1}"),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.w600)),
                      Text("₹${_b['total_amount'] ?? 0}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),

            const SizedBox(height: 16),

            // OTP Section (Premium Look)
            if (['assigned', 'en_route', 'arrived', 'in_progress'].contains(status) && _b['otp'] != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF0D9488)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Security OTP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Share this with your gardener", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: Text(_b['otp'].toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 4)),
                    ),
                  ],
                ),
              ).animate().scale(),

            const SizedBox(height: 16),

            // Gardener Section
            if (gardener != null)
              RoundedCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Gardener Assigned", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: Text((gardener['name'] as String? ?? 'G')[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(gardener['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(gardener['phone'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (['assigned', 'en_route', 'arrived', 'in_progress'].contains(status))
                          IconButton(
                            icon: const Icon(Icons.location_searching_rounded, color: AppTheme.primary),
                            onPressed: () => Navigator.pushNamed(context, '/track', arguments: _b['id'] as int),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Work Proof (If available)
            if (_b['before_image'] != null || _b['after_image'] != null)
              RoundedCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Work Highlights", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_b['before_image'] != null)
                          Expanded(
                            child: Column(
                              children: [
                                const Text("Before", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                const SizedBox(height: 4),
                                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_b['before_image'], height: 120, fit: BoxFit.cover)),
                              ],
                            ),
                          ),
                        if (_b['before_image'] != null && _b['after_image'] != null) const SizedBox(width: 12),
                        if (_b['after_image'] != null)
                          Expanded(
                            child: Column(
                              children: [
                                const Text("After", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                const SizedBox(height: 4),
                                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_b['after_image'], height: 120, fit: BoxFit.cover)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Rating Section
            if (canRate)
              RoundedCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text("How was the service?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      itemSize: 36,
                      itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Colors.amber),
                      onRatingUpdate: (r) => setState(() => _rating = r),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _reviewCtrl,
                      decoration: InputDecoration(
                        hintText: "Add a comment...",
                        fillColor: Colors.grey[50],
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    GradientButton(label: "Submit Feedback", onPressed: _loading ? () {} : _submitRating, isLoading: _loading),
                  ],
                ),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black45),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.black45, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
