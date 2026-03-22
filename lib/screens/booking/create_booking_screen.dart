import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key});
  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  int _step = 0;
  List _zones = [];
  List _plans = [];
  Map? _selectedZone;
  String _bookingType = 'ondemand';
  Map? _selectedPlan;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  int _plants = 1;
  final _addressCtrl = TextEditingController();
  double? _lat, _lng;
  bool _loading = false;
  bool _detectingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = context.read<ApiService>();
    final [z, p] = await Future.wait([api.getZones(), api.getPlans()]);
    setState(() { _zones = z['data'] ?? []; _plans = p['data'] ?? []; });
  }

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      bool ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) { _snack('Location services disabled'); return; }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) { _snack('Location permission denied'); return; }
      final pos = await Geolocator.getCurrentPosition();
      setState(() { _lat = pos.latitude; _lng = pos.longitude; });
      _snack('Location detected!');
    } catch (e) { _snack('Could not get location: $e'); }
    setState(() => _detectingLocation = false);
  }

  Future<void> _submit() async {
    if (_addressCtrl.text.isEmpty) { _snack('Enter service address'); return; }
    if (_lat == null) { _snack('Please detect location'); return; }
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      if (_bookingType == 'subscription' && _selectedPlan != null) {
        await api.subscribe({
          'plan_id': _selectedPlan!['id'],
          'zone_id': _selectedZone?['id'],
          'service_address': _addressCtrl.text,
          'service_latitude': _lat,
          'service_longitude': _lng,
          'plant_count': _plants,
        });
        _snack('Subscription activated! 🎉');
      } else {
        await api.createBooking({
          'zone_id': _selectedZone!['id'],
          'scheduled_date': '${_date.year}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')}',
          'service_address': _addressCtrl.text,
          'service_latitude': _lat,
          'service_longitude': _lng,
          'plant_count': _plants,
        });
        _snack('Booking confirmed! 🌿');
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) { _snack(e.toString()); }
    setState(() => _loading = false);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Book a Service')),
    body: Column(children: [
      // Stepper header
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: List.generate(3, (i) => Expanded(child: Row(children: [
          _StepDot(i, _step),
          if (i < 2) Expanded(child: Container(height: 2, color: i < _step ? AppTheme.primary : AppTheme.border)),
        ])))),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: [_stepZone(), _stepDetails(), _stepConfirm()][_step],
      )),
      _BottomBar(
        step: _step, totalSteps: 3, loading: _loading,
        onBack: _step > 0 ? () => setState(() => _step--) : null,
        onNext: () {
          if (_step == 0 && _selectedZone == null && _bookingType == 'ondemand') { _snack('Select a zone'); return; }
          if (_step < 2) setState(() => _step++);
          else _submit();
        },
        nextLabel: _step == 2 ? 'Confirm Booking' : 'Continue',
      ),
    ]),
  );

  Widget _stepZone() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Service Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    Row(children: [
      _TypeCard('On-Demand', Icons.flash_on, 'ondemand', _bookingType, (v) => setState(() => _bookingType = v)),
      const SizedBox(width: 12),
      _TypeCard('Subscription', Icons.repeat, 'subscription', _bookingType, (v) => setState(() => _bookingType = v)),
    ]),
    const SizedBox(height: 24),
    if (_bookingType == 'ondemand') ...[
      const Text('Select Zone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      ..._zones.map((z) => GkmCard(
        padding: const EdgeInsets.all(14),
        onTap: () => setState(() => _selectedZone = z),
        child: Row(children: [
          Radio(value: z, groupValue: _selectedZone, onChanged: (v) => setState(() => _selectedZone = v as Map), activeColor: AppTheme.primary),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(z['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${z['city']}, ${z['state']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ])),
          Text('₹${z['base_price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ]),
      )),
    ] else ...[
      const Text('Select Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      ..._plans.where((p) => p['plan_type'] == 'subscription').map((p) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: GkmCard(
          padding: const EdgeInsets.all(14),
          onTap: () => setState(() => _selectedPlan = p),
          child: Row(children: [
            Radio(value: p, groupValue: _selectedPlan, onChanged: (v) => setState(() => _selectedPlan = v as Map), activeColor: AppTheme.primary),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${p['visits_per_month']} visits · Max ${p['max_plants']} plants', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹${p['price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
              const Text('/month', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ]),
          ]),
        ),
      )),
    ],
  ]);

  Widget _stepDetails() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Service Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 20),
    if (_bookingType == 'ondemand') ...[
      const Text('Preferred Date', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      GkmCard(
        onTap: () async {
          final d = await showDatePicker(context: context, initialDate: _date,
            firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
          if (d != null) setState(() => _date = d);
        },
        child: Row(children: [
          const Icon(Icons.calendar_today, color: AppTheme.primary),
          const SizedBox(width: 12),
          Text('${_date.day}/${_date.month}/${_date.year}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ]),
      ),
      const SizedBox(height: 20),
    ],
    const Text('Number of Plants', style: TextStyle(fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    Row(children: [
      IconButton(onPressed: _plants > 1 ? () => setState(() => _plants--) : null,
        icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary)),
      Text('$_plants', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      IconButton(onPressed: () => setState(() => _plants++),
        icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary)),
      const Spacer(),
      Text('${_plants} plant${_plants > 1 ? 's' : ''}', style: const TextStyle(color: AppTheme.textSecondary)),
    ]),
    const SizedBox(height: 20),
    const Text('Service Address', style: TextStyle(fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    TextField(
      controller: _addressCtrl, maxLines: 3,
      decoration: const InputDecoration(hintText: 'Enter full address where service is needed'),
    ),
    const SizedBox(height: 12),
    SizedBox(
      width: double.infinity, height: 44,
      child: OutlinedButton.icon(
        onPressed: _detectingLocation ? null : _detectLocation,
        icon: _detectingLocation ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location, size: 18),
        label: Text(_lat != null ? '✓ Location detected' : 'Detect My Location'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _lat != null ? AppTheme.success : AppTheme.primary,
          side: BorderSide(color: _lat != null ? AppTheme.success : AppTheme.primary),
          minimumSize: Size.zero,
        ),
      ),
    ),
  ]);

  Widget _stepConfirm() {
    double total = 0;
    if (_bookingType == 'ondemand' && _selectedZone != null) {
      total = double.tryParse(_selectedZone!['base_price'].toString()) ?? 0;
    } else if (_selectedPlan != null) {
      total = double.tryParse(_selectedPlan!['price'].toString()) ?? 0;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Confirm Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      GkmCard(child: Column(children: [
        _ConfirmRow('Type', _bookingType == 'subscription' ? 'Subscription' : 'On-Demand'),
        if (_selectedZone != null) _ConfirmRow('Zone', '${_selectedZone!['name']}, ${_selectedZone!['city']}'),
        if (_selectedPlan != null) _ConfirmRow('Plan', _selectedPlan!['name'] ?? ''),
        if (_bookingType == 'ondemand') _ConfirmRow('Date', '${_date.day}/${_date.month}/${_date.year}'),
        _ConfirmRow('Plants', '$_plants'),
        _ConfirmRow('Address', _addressCtrl.text.isEmpty ? '–' : _addressCtrl.text),
        const Divider(),
        _ConfirmRow('Total', '₹${total.toStringAsFixed(0)}', bold: true),
      ])),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primary.withOpacity(0.2))),
        child: const Row(children: [
          Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text('A gardener will be assigned and you\'ll get WhatsApp confirmation.', style: TextStyle(color: AppTheme.primary, fontSize: 13))),
        ]),
      ),
    ]);
  }
}

class _ConfirmRow extends StatelessWidget {
  final String k, v; final bool bold;
  const _ConfirmRow(this.k, this.v, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Text(k, style: const TextStyle(color: AppTheme.textSecondary)),
      const Spacer(),
      Text(v, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, fontSize: bold ? 16 : 14)),
    ]),
  );
}

class _StepDot extends StatelessWidget {
  final int index, current;
  const _StepDot(this.index, this.current);
  @override
  Widget build(BuildContext context) => Container(
    width: 28, height: 28,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: index <= current ? AppTheme.primary : AppTheme.border,
    ),
    child: Center(
      child: index < current
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : Text('${index + 1}', style: TextStyle(color: index == current ? Colors.white : AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
    ),
  );
}

class _TypeCard extends StatelessWidget {
  final String label, value, group; final IconData icon; final ValueChanged<String> onChanged;
  const _TypeCard(this.label, this.icon, this.value, this.group, this.onChanged);
  @override
  Widget build(BuildContext context) {
    final sel = value == group;
    return Expanded(child: GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sel ? AppTheme.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? AppTheme.primary : AppTheme.border, width: sel ? 2 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: sel ? AppTheme.primary : AppTheme.textSecondary, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: sel ? AppTheme.primary : AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        ]),
      ),
    ));
  }
}

class _BottomBar extends StatelessWidget {
  final int step, totalSteps; final bool loading;
  final VoidCallback? onBack; final VoidCallback onNext; final String nextLabel;
  const _BottomBar({required this.step, required this.totalSteps, required this.loading, required this.onBack, required this.onNext, required this.nextLabel});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, -4))]),
    child: Row(children: [
      if (onBack != null) ...[
        OutlinedButton(onPressed: onBack, child: const Text('Back'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(80, 52), foregroundColor: AppTheme.textPrimary, side: const BorderSide(color: AppTheme.border))),
        const SizedBox(width: 12),
      ],
      Expanded(child: ElevatedButton(
        onPressed: loading ? null : onNext,
        child: loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(nextLabel),
      )),
    ]),
  );
}
