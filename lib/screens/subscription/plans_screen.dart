import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});
  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  List _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().getPlans();
      setState(() => _plans = res['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Choose a Plan')),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryStart))
            : ListView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                children: [
                  const Text('Our Plans',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1)),
                  const SizedBox(height: 4),
                  const Text('Professional garden care, simplified for you',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 32),
                  ..._plans
                      .map((p) => _PlanCard(plan: p))
                      .toList()
                      .animate(interval: 100.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 80),
                ],
              ),
      );
}

class _PlanCard extends StatelessWidget {
  final Map plan;
  const _PlanCard({required this.plan});
  @override
  Widget build(BuildContext context) {
    final isPopular = plan['plan_type'] == 'subscription' && plan['visits_per_month'] == 12;
    final features = (plan['features'] as List?) ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(children: [
        RoundedCard(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (isPopular) const SizedBox(height: 8),
            Text(plan['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(plan['description'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹${plan['price']}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryStart)),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(plan['plan_type'] == 'subscription' ? '/month' : '/visit',
                    style: const TextStyle(color: Colors.grey)),
              ),
            ]),
            if (plan['plan_type'] == 'subscription') ...[
              const SizedBox(height: 8),
              Row(children: [
                _Chip('${plan['visits_per_month']} visits'),
                const SizedBox(width: 8),
                _Chip('${plan['max_plants']} plants max'),
              ]),
            ],
            if (features.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      const Icon(Icons.check_circle, color: AppTheme.primaryStart, size: 18),
                      const SizedBox(width: 8),
                      Text(f.toString(), style: const TextStyle(fontSize: 14)),
                    ]),
                  )),
            ],
            const SizedBox(height: 16),
            GradientButton(
              label: plan['plan_type'] == 'subscription' ? 'Subscribe Now' : 'Book Now',
              onPressed: () {
                if (plan['plan_type'] == 'subscription') {
                   Navigator.pushNamed(context, '/benefits-carousel', arguments: plan);
                } else {
                   Navigator.pushNamed(context, '/bookings/create');
                }
              },
            ),
          ]),
        ),
        if (isPopular)
          Positioned(
            top: 0,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: const BoxDecoration(
                  color: AppTheme.primaryStart, borderRadius: BorderRadius.vertical(bottom: Radius.circular(8))),
              child: const Text('POPULAR',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: AppTheme.primaryStart.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: const TextStyle(color: AppTheme.primaryStart, fontSize: 12, fontWeight: FontWeight.w500)),
      );
}
