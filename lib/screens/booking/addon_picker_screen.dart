import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class AddonPickerScreen extends StatefulWidget {
  final int bookingId;
  final String bookingNumber;
  const AddonPickerScreen({super.key, required this.bookingId, required this.bookingNumber});
  @override
  State<AddonPickerScreen> createState() => _AddonPickerScreenState();
}

class _AddonPickerScreenState extends State<AddonPickerScreen> {
  List _addons = [];
  Map<int, int> _selected = {}; // addon_id → quantity
  bool _loading = true, _saving = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().get('/addons');
      setState(() => _addons = res['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  double get _total => _addons.fold(0.0, (sum, a) {
    final qty = _selected[a['id'] as int] ?? 0;
    return sum + (double.tryParse(a['price'].toString()) ?? 0) * qty;
  });

  Future<void> _addToBooking() async {
    if (_selected.isEmpty) { _snack('Select at least one service'); return; }
    setState(() => _saving = true);
    try {
      final items = _selected.entries
          .map((e) => {'addon_id': e.key, 'quantity': e.value})
          .toList();
      final res = await context.read<ApiService>().post(
        '/bookings/${widget.bookingId}/addons', {'addon_ids': items});
      _snack(res['message'] ?? 'Add-ons added successfully!');
      if (mounted) Navigator.pop(context, true);
    } catch (e) { _snack(e.toString()); }
    setState(() => _saving = false);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // Group addons by category
  Map<String, List> get _grouped {
    final Map<String, List> g = {};
    for (final a in _addons) {
      final cat = a['category'] as String? ?? 'other';
      g.putIfAbsent(cat, () => []).add(a);
    }
    return g;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Add Services — ${widget.bookingNumber}')),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : Column(children: [
            Expanded(child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Enhance your visit with extra services', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                ..._grouped.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 8),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textSecondary, letterSpacing: 1.2),
                      ),
                    ),
                    ...entry.value.map((a) {
                      final id  = a['id'] as int;
                      final qty = _selected[id] ?? 0;
                      return GkmCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          Text(a['icon'] ?? '🌿', style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(a['description'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(children: [
                              Text('₹${a['price']}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 8),
                              if (a['duration_mins'] != null)
                                Text('· ~${a['duration_mins']} min', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            ]),
                          ])),
                          const SizedBox(width: 8),
                          // Qty stepper
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            if (qty > 0) ...[
                              GestureDetector(
                                onTap: () => setState(() { if (qty > 1) _selected[id] = qty - 1; else _selected.remove(id); }),
                                child: Container(width: 28, height: 28, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.remove, size: 16)),
                              ),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            ],
                            GestureDetector(
                              onTap: () => setState(() => _selected[id] = qty + 1),
                              child: Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(color: qty > 0 ? AppTheme.primary : AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.add, size: 16, color: qty > 0 ? Colors.white : AppTheme.primary),
                              ),
                            ),
                          ]),
                        ]),
                      );
                    }),
                  ],
                )),
                const SizedBox(height: 80),
              ],
            )),
            // Bottom bar
            if (_selected.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, -4))],
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${_selected.values.fold(0, (s, v) => s + v)} service(s) selected',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    Text('+ ₹${_total.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary)),
                  ])),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saving ? null : _addToBooking,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(140, 52)),
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Add to Booking'),
                  ),
                ]),
              ),
          ]),
  );
}
