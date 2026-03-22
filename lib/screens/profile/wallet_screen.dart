import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../payment/payment_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List _transactions = [];
  bool _loading = true;
  final _amountCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await context.read<ApiService>().getMyPayments();
      setState(() => _transactions = res['data']['payments'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _topup() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount < 100) {
      _snack('Minimum top-up is ₹100'); return;
    }
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => PaymentScreen(type: 'wallet_topup', amount: amount, label: 'Wallet Top-up ₹${amount.toStringAsFixed(0)}'),
    ));
    if (result != null) {
      _amountCtrl.clear();
      await context.read<AuthProvider>().refreshProfile();
      _load();
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final balance = double.tryParse(user?['wallet_balance']?.toString() ?? '0') ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Balance card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(children: [
                const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text('₹${balance.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 40)),
                const SizedBox(height: 4),
                const Text('Available to use on bookings', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 24),

            // Top-up card
            GkmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Add Money', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('Top up your wallet using PayU', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 14),

              // Quick amounts
              Wrap(spacing: 10, children: [100, 200, 500, 1000].map((amt) => GestureDetector(
                onTap: () => setState(() => _amountCtrl.text = amt.toString()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _amountCtrl.text == amt.toString() ? AppTheme.primary.withOpacity(0.1) : AppTheme.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _amountCtrl.text == amt.toString() ? AppTheme.primary : AppTheme.border),
                  ),
                  child: Text('₹$amt', style: TextStyle(
                    color: _amountCtrl.text == amt.toString() ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600, fontSize: 13,
                  )),
                ),
              )).toList()),
              const SizedBox(height: 14),

              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Enter amount (min ₹100)',
                  prefixText: '₹ ',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _topup,
                icon: const Icon(Icons.add),
                label: const Text('Add Money via PayU'),
              ),
            ])),
            const SizedBox(height: 24),

            // Transaction history
            const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            else if (_transactions.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No transactions yet', style: TextStyle(color: AppTheme.textSecondary)),
              ))
            else
              ..._transactions.map((t) => _TxnTile(txn: t)),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  final Map txn;
  const _TxnTile({required this.txn});

  static const _icons = {
    'booking': Icons.grass,
    'subscription': Icons.subscriptions,
    'wallet_topup': Icons.add_circle,
    'refund': Icons.replay,
  };
  static const _colors = {
    'success': AppTheme.success,
    'failed': AppTheme.error,
    'pending': AppTheme.warning,
    'refunded': AppTheme.primary,
  };

  @override
  Widget build(BuildContext context) {
    final status = txn['status'] as String? ?? 'pending';
    final type = txn['type'] as String? ?? 'booking';
    final isCredit = type == 'wallet_topup' || type == 'refund';
    final color = _colors[status] ?? AppTheme.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GkmCard(child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(_icons[type] ?? Icons.payment, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_typeLabel(type), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(txn['transaction_id'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontFamily: 'monospace')),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '${isCredit ? '+' : '-'}₹${txn['amount']}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isCredit ? AppTheme.success : AppTheme.textPrimary),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ]),
      ])),
    );
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'booking': return 'Booking Payment';
      case 'subscription': return 'Subscription';
      case 'wallet_topup': return 'Wallet Top-up';
      case 'refund': return 'Refund';
      default: return 'Payment';
    }
  }
}
