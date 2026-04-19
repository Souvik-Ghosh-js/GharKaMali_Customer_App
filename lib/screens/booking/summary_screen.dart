import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../theme.dart';

class BookingSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const BookingSummaryScreen({
    super.key,
    required this.bookingData,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  bool _isLoading = false;

  Future<void> _processBooking() async {
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    final d = widget.bookingData;

    try {
      if (d['type'] == 'subscription') {
        await api.subscribe({
          'plan_id': d['plan']['id'],
          'geofence_id': d['area']?['id'],
          'service_address': d['address'],
          'service_latitude': d['lat'],
          'service_longitude': d['lng'],
          'plant_count': d['plants'],
        });
      } else {
        // Format date for API (YYYY-MM-DD)
        final rawDate = d['date'].split('/');
        final formattedDate = "${rawDate[2]}-${rawDate[1].padLeft(2, '0')}-${rawDate[0].padLeft(2, '0')}";

        await api.createBooking({
          'geofence_id': d['area']?['id'],
          'scheduled_date': formattedDate,
          'service_address': d['address'],
          'service_latitude': d['lat'],
          'service_longitude': d['lng'],
          'plant_count': d['plants'],
        });
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Success! 🌿"),
            content: const Text("Your request has been received. A gardener will be assigned shortly."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // close dialog
                  Navigator.popUntil(context, ModalRoute.withName('/home')); // go to home
                },
                child: const Text("Awesome"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.bookingData;
    final type = d['type'] == 'subscription' ? 'Subscription' : 'One-time Booking';
    final areaName = d['area']?['name'] ?? d['plan']?['name'] ?? 'Care Plan';
    final date = d['date'] ?? 'TBD';
    final plants = d['plants'] ?? 0;
    final address = d['address'] ?? 'Not selected';
    final total = d['total'] ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Booking Summary")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Review Your Service",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            RoundedCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _SummaryRow(label: "Plan Type", value: type),
                  _SummaryRow(label: "Service", value: areaName),
                  if (d['type'] != 'subscription') _SummaryRow(label: "Scheduled Date", value: date),
                  _SummaryRow(label: "Number of Plants", value: plants.toString()),
                  const Divider(height: 32),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Service Address", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(address, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  const Divider(height: 32),
                  _SummaryRow(
                    label: "Total Amount",
                    value: "₹$total",
                    isBold: true,
                    valueColor: AppTheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Our gardener will bring all necessary tools. Please ensure water access is available.",
                      style: TextStyle(fontSize: 13, color: AppTheme.primary),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: GradientButton(
          label: _isLoading ? "Processing..." : "Confirm & Pay",
          onPressed: _isLoading ? () {} : _processBooking,
          isLoading: _isLoading,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({required this.label, required this.value, this.isBold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 18 : 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
