import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});
  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen> {
  List _subs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().getMySubscriptions();
      setState(() => _subs = res['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _cancel(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Cancel Subscription?'),
      content: const Text('Are you sure you want to cancel this subscription?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (ok != true) return;
    try {
      await context.read<ApiService>().cancelSubscription(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription cancelled')));
      _load();
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Subscriptions')),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : _subs.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🌱', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text('No subscriptions yet', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/plans'),
                  child: const Text('Browse Plans'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
                ),
              ]))
            : RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _subs.length,
                  itemBuilder: (_, i) {
                    final s = _subs[i];
                    final plan = s['plan'] ?? {};
                    final isActive = s['status'] == 'active';
                    return GkmCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(plan['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          GkmBadge(s['status'] ?? ''),
                        ]),
                        const SizedBox(height: 12),
                        _Row('Visits Used', '${s['visits_used']} / ${s['visits_total']}'),
                        _Row('Period', '${s['start_date']} → ${s['end_date']}'),
                        _Row('Amount Paid', '₹${s['amount_paid']}'),
                        _Row('Auto Renew', s['auto_renew'] == true ? '✓ Yes' : '✗ No'),
                        if (s['visits_total'] != null) ...[
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: (s['visits_used'] as int) / (s['visits_total'] as int),
                            backgroundColor: AppTheme.border,
                            valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 4),
                          Text('${s['visits_total'] - s['visits_used']} visits remaining', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                        if (isActive) ...[
                          const SizedBox(height: 14),
                          OutlinedButton(
                            onPressed: () => _cancel(s['id']),
                            child: const Text('Cancel Subscription'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), minimumSize: const Size(double.infinity, 42)),
                          ),
                        ],
                      ]),
                    );
                  },
                ),
              ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, '/plans'),
      backgroundColor: AppTheme.primary,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('New Plan', style: TextStyle(color: Colors.white)),
    ),
  );
}

class _Row extends StatelessWidget {
  final String k, v;
  const _Row(this.k, this.v);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Text(k, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      const Spacer(),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
    ]),
  );
}
