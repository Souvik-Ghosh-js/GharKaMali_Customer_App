import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class ShopOrdersScreen extends StatefulWidget {
  const ShopOrdersScreen({super.key});
  @override
  State<ShopOrdersScreen> createState() => _ShopOrdersScreenState();
}

class _ShopOrdersScreenState extends State<ShopOrdersScreen> {
  List _orders = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().getMyOrders();
      setState(() => _orders = res['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop Orders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _orders.isEmpty
              ? const Center(child: Text('No shop orders found', style: TextStyle(color: AppTheme.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (_, i) {
                      final o = _orders[i];
                      return GkmCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text('#ORD-${o['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            GkmBadge(o['status'] ?? 'pending'),
                          ]),
                          const Divider(height: 24),
                          ...(o['items'] as List? ?? []).map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(children: [
                              Text('${item['quantity']}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(item['product']?['name'] ?? 'Product')),
                              Text('₹${item['price']}'),
                            ]),
                          )),
                          const Divider(height: 24),
                          Row(children: [
                            const Text('Total Amount', style: TextStyle(color: AppTheme.textSecondary)),
                            const Spacer(),
                            Text('₹${o['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ]),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}
