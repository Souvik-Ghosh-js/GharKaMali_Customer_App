import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class RaiseComplaintScreen extends StatefulWidget {
  final Map<String, dynamic>? booking;
  const RaiseComplaintScreen({super.key, this.booking});
  @override
  State<RaiseComplaintScreen> createState() => _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends State<RaiseComplaintScreen> {
  String _type     = 'service_quality';
  String _priority = 'medium';
  final _descCtrl  = TextEditingController();
  bool _loading    = false;

  static const _types = [
    ('service_quality', 'Service Quality', '🌿'),
    ('late_arrival',    'Late Arrival',    '⏰'),
    ('no_show',         'No Show',         '❌'),
    ('rude_behavior',   'Rude Behavior',   '😡'),
    ('billing',         'Billing Issue',   '💳'),
    ('damage',          'Property Damage', '🏠'),
    ('other',           'Other',           '📝'),
  ];

  static const _priorities = [
    ('low',    'Low',    Color(0xFF6B7280)),
    ('medium', 'Medium', Color(0xFFD97706)),
    ('high',   'High',   Color(0xFFDC2626)),
  ];

  Future<void> _submit() async {
    if (_descCtrl.text.trim().length < 20) {
      _snack('Please describe the issue in at least 20 characters'); return;
    }
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      await api.post('/complaints', {
        'type':        _type,
        'description': _descCtrl.text.trim(),
        'priority':    _priority,
        if (widget.booking != null) 'booking_id': widget.booking!['id'],
      });
      _snack('Complaint raised! Our team will respond within 24 hours. ✓');
      if (mounted) Navigator.pop(context, true);
    } catch (e) { _snack(e.toString()); }
    setState(() => _loading = false);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Raise a Complaint')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Booking ref
        if (widget.booking != null)
          GkmCard(child: Row(children: [
            Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.grass, color: AppTheme.primary, size: 18)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.booking!['booking_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13)),
              Text(widget.booking!['scheduled_date'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ]),
          ])),

        if (widget.booking != null) const SizedBox(height: 20),

        // Type
        const Text('What went wrong?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 3.2,
          children: _types.map((t) {
            final sel = _type == t.$1;
            return GestureDetector(
              onTap: () => setState(() => _type = t.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? AppTheme.primary : AppTheme.border, width: sel ? 2 : 1),
                ),
                child: Row(children: [
                  Text(t.$3, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(t.$2, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: sel ? AppTheme.primary : AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis)),
                ]),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Priority
        const Text('Urgency Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(children: _priorities.map((p) {
          final sel = _priority == p.$1;
          return Expanded(child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _priority = p.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? p.$3.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? p.$3 : AppTheme.border, width: sel ? 2 : 1),
                ),
                child: Center(child: Text(p.$2,
                  style: TextStyle(fontWeight: FontWeight.w600, color: sel ? p.$3 : AppTheme.textSecondary, fontSize: 13))),
              ),
            ),
          ));
        }).toList()),

        const SizedBox(height: 24),

        // Description
        const Text('Describe the Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _descCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Please describe what happened in detail. The more information you provide, the faster we can resolve it.',
          ),
        ),

        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, color: AppTheme.primary, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Our team reviews complaints within 24 hours. You\'ll receive a WhatsApp update once resolved.',
              style: TextStyle(color: AppTheme.primary, fontSize: 12),
            )),
          ]),
        ),

        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
          child: _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Submit Complaint'),
        ),
        const SizedBox(height: 40),
      ]),
    ),
  );
}
