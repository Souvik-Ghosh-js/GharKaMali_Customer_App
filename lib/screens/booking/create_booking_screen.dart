import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../services/api_service.dart';
import '../../services/location_provider.dart';
import '../../utils/app_theme.dart';
import '../../theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key});
  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  int _currentStep = 0;
  String _bookingType = 'ondemand';
  Map? _selectedArea;
  Map? _selectedPlan;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _plantCount = 1;
  final _addressController = TextEditingController();
  LatLng? _selectedLatLng;
  bool _isLoading = false;

  List _areas = [];
  List _plans = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = context.read<ApiService>();
    try {
      final results = await Future.wait([
        api.getGeofences(),
        api.getPlans(),
      ]);
      setState(() {
        _areas = results[0]['data'] ?? [];
        _plans = results[1]['data'] ?? [];
      });
    } catch (_) {}
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_bookingType == 'ondemand' && _selectedArea == null) {
        _showError("Please select a service area");
        return;
      }
      if (_bookingType == 'subscription' && _selectedPlan == null) {
        _showError("Please select a plan");
        return;
      }
    }
    if (_currentStep == 1 && _selectedLatLng == null) {
      _showError("Please select a location on the map");
      return;
    }
    if (_currentStep == 2 && _addressController.text.trim().isEmpty) {
      _showError("Please enter your address");
      return;
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _finalizeBooking();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _finalizeBooking() async {
    setState(() => _isLoading = true);
    // Prepare data for summary/payment
    final bookingData = {
      'type': _bookingType,
      'area': _selectedArea,
      'plan': _selectedPlan,
      'date': "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
      'plants': _plantCount,
      'address': _addressController.text,
      'lat': _selectedLatLng?.latitude,
      'lng': _selectedLatLng?.longitude,
      'total': _calculateTotal(),
    };

    // In a real app, we'd navigate to summary screen here
    Navigator.pushNamed(context, '/booking-summary', arguments: bookingData);
    setState(() => _isLoading = false);
  }

  double _calculateTotal() {
    if (_bookingType == 'ondemand') {
      return double.tryParse(_selectedArea?['base_price'].toString() ?? '0') ?? 0;
    } else {
      return double.tryParse(_selectedPlan?['price'].toString() ?? '0') ?? 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book a Service")),
      body: Column(
        children: [
          _buildStepperHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildServiceSelection(),
                  _buildLocationStep(),
                  _buildDetailsStep(),
                  _buildFinalReviewStep(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Back"),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              flex: 2,
              child: GradientButton(
                label: _currentStep == 3 ? "Review Summary" : "Continue",
                onPressed: _nextStep,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primary : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: index < _currentStep
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            "${index + 1}",
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                if (index < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < _currentStep ? AppTheme.primary : Colors.grey[200],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildServiceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Choose Service Type", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(
          children: [
            _TypeCard(
              label: "One-Time",
              icon: Icons.flash_on_rounded,
              isSelected: _bookingType == 'ondemand',
              onTap: () => setState(() => _bookingType = 'ondemand'),
            ),
            const SizedBox(width: 16),
            _TypeCard(
              label: "Subscription",
              icon: Icons.calendar_month_rounded,
              isSelected: _bookingType == 'subscription',
              onTap: () => setState(() => _bookingType = 'subscription'),
            ),
          ],
        ),
        const SizedBox(height: 30),
        if (_bookingType == 'ondemand') ...[
          const Text("Select Service Area", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._areas.map((a) => _AreaCard(
                area: a,
                isSelected: _selectedArea?['id'] == a['id'],
                onTap: () => setState(() => _selectedArea = a),
              )),
        ] else ...[
          const Text("Select Subscription Plan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._plans.where((p) => p['plan_type'] == 'subscription').map((p) => _PlanSelectionCard(
                plan: p,
                isSelected: _selectedPlan?['id'] == p['id'],
                onTap: () => setState(() => _selectedPlan = p),
              )),
        ],
      ],
    ).animate().fadeIn();
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Where should we come?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        RoundedCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.map_rounded, color: AppTheme.primary),
            title: Text(_selectedLatLng == null ? "Select on Map" : "Location Selected"),
            subtitle: Text(_selectedLatLng == null ? "Pin your exact address" : "Coords: ${_selectedLatLng!.latitude.toStringAsFixed(4)}, ${_selectedLatLng!.longitude.toStringAsFixed(4)}"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // Navigate to map screen and wait for result
              Navigator.pushNamed(context, '/location-map').then((result) {
                if (result != null && result is Map) {
                  setState(() {
                    _selectedLatLng = result['latlng'];
                    _addressController.text = result['address'] ?? "";
                  });
                }
              });
            },
          ),
        ),
        const SizedBox(height: 20),
        const Text("Manual Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextField(
          controller: _addressController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Enter house no, building name, landmark...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Service Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        if (_bookingType == 'ondemand') ...[
          const Text("Select Date", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          RoundedCard(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: AppTheme.primary),
                const SizedBox(width: 12),
                Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        const Text("Plant Count", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            _CountBtn(icon: Icons.remove, onTap: () => setState(() => _plantCount = _plantCount > 1 ? _plantCount - 1 : 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text("$_plantCount", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            _CountBtn(icon: Icons.add, onTap: () => setState(() => _plantCount++)),
          ],
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildFinalReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Great! You're almost there.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text("Everything looks good. Tap Continue to see your total.", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),
        const Icon(Icons.task_alt_rounded, size: 100, color: AppTheme.primary).animate().scale(),
      ],
    ).animate().fadeIn();
  }
}

class _TypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey[200]!, width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.primary : Colors.grey, size: 32),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppTheme.primary : Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  final Map area;
  final bool isSelected;
  final VoidCallback onTap;

  const _AreaCard({required this.area, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Row(
        children: [
          Radio(value: true, groupValue: isSelected, onChanged: (_) => onTap(), activeColor: AppTheme.primary),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(area['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("${area['city']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
          Text("₹${area['base_price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ],
      ),
    );
  }
}

class _PlanSelectionCard extends StatelessWidget {
  final Map plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanSelectionCard({required this.plan, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Row(
        children: [
          Radio(value: true, groupValue: isSelected, onChanged: (_) => onTap(), activeColor: AppTheme.primary),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(plan['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("${plan['visits_per_month']} visits/mo", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
          Text("₹${plan['price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ],
      ),
    );
  }
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CountBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primary),
      ),
    );
  }
}
