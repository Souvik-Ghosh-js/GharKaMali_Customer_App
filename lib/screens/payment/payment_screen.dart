import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

/// PayU payment screen.
/// After initiatePayment, opens the PayU URL in device browser via url_launcher.
class PaymentScreen extends StatefulWidget {
  final String type;
  final int? bookingId;
  final int? subscriptionId;
  final int? orderId;
  final double? amount;
  final String? label;

  const PaymentScreen({
    super.key,
    required this.type,
    this.bookingId,
    this.subscriptionId,
    this.orderId,
    this.amount,
    this.label,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;
  bool _initiated = false;
  Map? _payuData;
  String _selectedMethod = 'upi';

  final _methods = const [
    {'id': 'upi', 'label': 'UPI / GPay / PhonePe', 'icon': Icons.payment},
    {'id': 'card', 'label': 'Credit / Debit Card', 'icon': Icons.credit_card},
    {'id': 'netbanking', 'label': 'Net Banking', 'icon': Icons.account_balance},
    {'id': 'wallet', 'label': 'Mobile Wallet', 'icon': Icons.account_balance_wallet},
  ];

  Future<void> _initiatePayment() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final res = await api.initiatePayment(
        type: widget.type,
        bookingId: widget.bookingId,
        subscriptionId: widget.subscriptionId,
        orderId: widget.orderId,
        amount: widget.amount,
      );
      setState(() {
        _payuData = res['data'];
        _initiated = true;
      });

      // FIX: immediately open PayU URL in browser after initiating
      final payuUrl = _payuData?['payu_url'] as String?;
      if (payuUrl != null && payuUrl.isNotEmpty) {
        final uri = Uri.parse(payuUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      _snack(e.toString());
    }
    setState(() => _loading = false);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final amount = widget.amount ?? 0.0;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Order summary
          GkmCard(child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.receipt_long, color: AppTheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.label ?? _typeLabel(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Text('Powered by PayU',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ])),
            Text('₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: AppTheme.primary)),
          ])),
          const SizedBox(height: 24),

          if (!_initiated) ...[
            const Text('Select Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ..._methods.map((m) => GestureDetector(
                  onTap: () =>
                      setState(() => _selectedMethod = m['id'] as String),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _selectedMethod == m['id']
                              ? AppTheme.primary
                              : AppTheme.border,
                          width: _selectedMethod == m['id'] ? 2 : 1),
                    ),
                    child: Row(children: [
                      Icon(m['icon'] as IconData,
                          color: _selectedMethod == m['id']
                              ? AppTheme.primary
                              : AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Text(m['label'] as String,
                          style:
                              const TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      if (_selectedMethod == m['id'])
                        const Icon(Icons.check_circle,
                            color: AppTheme.primary, size: 20),
                    ]),
                  ),
                )),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.success.withOpacity(0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.lock, color: AppTheme.success, size: 18),
                SizedBox(width: 8),
                Expanded(
                    child: Text(
                  '256-bit SSL encrypted · Secured by PayU · RBI compliant',
                  style: TextStyle(color: AppTheme.success, fontSize: 12),
                )),
              ]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _initiatePayment,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Pay ₹${amount.toStringAsFixed(0)}'),
            ),
          ] else ...[
            GkmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.open_in_browser, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Opening PayU…',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
              const SizedBox(height: 12),
              const Text(
                'PayU payment page has been opened in your browser. '
                'Complete the payment there and return here.',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.5),
              ),
              const SizedBox(height: 14),
              if (_payuData != null) ...[
                _InfoRow('Transaction ID',
                    _payuData!['params']?['txnid'] ?? ''),
                _InfoRow('Amount',
                    '₹${_payuData!['params']?['amount'] ?? amount}'),
              ],
              const SizedBox(height: 14),
              // Re-open if user missed it
              OutlinedButton.icon(
                onPressed: () async {
                  final payuUrl = _payuData?['payu_url'] as String?;
                  if (payuUrl != null) {
                    final uri = Uri.parse(payuUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  }
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Re-open Payment Page'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  minimumSize: const Size(double.infinity, 46),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, 'pending'),
                icon: const Icon(Icons.check),
                label: const Text('Done — I\'ve completed payment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.success,
                  side: const BorderSide(color: AppTheme.success),
                  minimumSize: const Size(double.infinity, 46),
                ),
              ),
            ])),
          ],
        ]),
      ),
    );
  }

  String _typeLabel() {
    switch (widget.type) {
      case 'booking': return 'Booking Payment';
      case 'subscription': return 'Subscription Payment';
      case 'order': return 'Shop Order';
      case 'wallet_topup': return 'Wallet Top-up';
      default: return 'Payment';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String k, v;
  const _InfoRow(this.k, this.v);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Text('$k: ',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          Expanded(
              child: Text(v,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13),
                  overflow: TextOverflow.ellipsis)),
        ]),
      );
}
