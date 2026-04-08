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
    final ok = await _confirm('Cancel Subscription?', 'Are you sure you want to cancel this subscription?');
    if (ok != true) return;
    try {
      await context.read<ApiService>().cancelSubscription(id);
      _snack('Subscription cancelled');
      _load();
    } catch (e) { _snack(e.toString()); }
  }

  Future<void> _pause(int id) async {
    final ok = await _confirm('Pause Subscription?', 'Your visits will pause. You can resume anytime.');
    if (ok != true) return;
    try {
      await context.read<ApiService>().pauseSubscription(id);
      _snack('Subscription paused');
      _load();
    } catch (e) { _snack(e.toString()); }
  }

  Future<void> _resume(int id) async {
    try {
      await context.read<ApiService>().resumeSubscription(id);
      _snack('Subscription resumed');
      _load();
    } catch (e) { _snack(e.toString()); }
  }

  Future<bool?> _confirm(String title, String content) async {
    return showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title), content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm', style: TextStyle(color: AppTheme.primary))),
      ],
    ));
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

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
                        if (s['payment_status'] == 'pending') ...[
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/payment', arguments: {
                              'type': 'subscription', 'subscription_id': s['id'],
                              'amount': double.tryParse((s['amount_paid'] ?? plan['price'] ?? 0).toString()),
                              'label': 'Subscription ${plan['name']}',
                            }).then((_) => _load()),
                            icon: const Icon(Icons.payment, size: 18),
                            label: const Text('Complete Payment'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning, minimumSize: const Size(double.infinity, 44)),
                          ),
                        ],
                        if (isActive && s['payment_status'] != 'pending') ...[
                          const SizedBox(height: 14),
                          Row(children: [
                            if ((s['scheduled_visits_count'] ?? 0) < (plan['visits_per_month'] ?? 0))
                              Expanded(child: ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, '/schedule-subscription', arguments: s).then((r) { if (r == true) _load(); }),
                                child: const Text('Schedule'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: EdgeInsets.zero),
                              )),
                            if ((s['scheduled_visits_count'] ?? 0) < (plan['visits_per_month'] ?? 0)) const SizedBox(width: 8),
                            Expanded(child: OutlinedButton(
                              onPressed: () => _pause(s['id']),
                              child: const Text('Pause'),
                              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textSecondary),
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: OutlinedButton(
                              onPressed: () => _cancel(s['id']),
                              child: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                            )),
                          ]),
                        ],
                        if (s['status'] == 'paused') ...[
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: () => _resume(s['id']),
                            child: const Text('Resume Subscription'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, minimumSize: const Size(double.infinity, 44)),
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
