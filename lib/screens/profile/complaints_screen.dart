import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../booking/raise_complaint_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});
  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List _complaints = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await context.read<ApiService>().get('/complaints/my');
      setState(() => _complaints = res['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  static const _statusColors = {
    'open':      (Color(0xFFFEE2E2), Color(0xFFDC2626)),
    'in_review': (Color(0xFFFEF3C7), Color(0xFFD97706)),
    'resolved':  (Color(0xFFDCFCE7), Color(0xFF15803D)),
    'closed':    (Color(0xFFF3F4F6), Color(0xFF6B7280)),
  };

  static const _typeIcons = {
    'service_quality': '🌿',
    'late_arrival':    '⏰',
    'no_show':         '❌',
    'rude_behavior':   '😡',
    'billing':         '💳',
    'damage':          '🏠',
    'other':           '📝',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Complaints')),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : RefreshIndicator(
            onRefresh: _load,
            color: AppTheme.primary,
            child: _complaints.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('✅', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text('No complaints — great!', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RaiseComplaintScreen())).then((_) => _load()),
                      icon: const Icon(Icons.add),
                      label: const Text('Raise a Complaint'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(200, 44)),
                    ),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _complaints.length,
                    itemBuilder: (_, i) {
                      final c = _complaints[i];
                      final status = c['status'] as String? ?? 'open';
                      final colors = _statusColors[status] ?? (const Color(0xFFF3F4F6), const Color(0xFF6B7280));
                      final icon = _typeIcons[c['type']] ?? '📝';
                      return GkmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              (c['type'] as String? ?? '').replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text('Complaint #${c['id']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: colors.$1, borderRadius: BorderRadius.circular(20)),
                            child: Text(status.replaceAll('_', ' '), style: TextStyle(color: colors.$2, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Text(c['description'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (c['resolution_notes'] != null && (c['resolution_notes'] as String).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('✅ ', style: TextStyle(fontSize: 12)),
                              Expanded(child: Text('Resolution: ${c['resolution_notes']}', style: const TextStyle(color: Color(0xFF15803D), fontSize: 12))),
                            ]),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Raised on ${DateTime.tryParse(c['created_at'] ?? '')?.toLocal().toString().split(' ')[0] ?? ''}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ]));
                    },
                  ),
          ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RaiseComplaintScreen())).then((_) => _load()),
      backgroundColor: const Color(0xFFDC2626),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('New Complaint', style: TextStyle(color: Colors.white)),
    ),
  );
}
