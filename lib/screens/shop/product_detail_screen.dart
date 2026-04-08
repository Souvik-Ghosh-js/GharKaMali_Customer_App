import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../payment/payment_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map product;
  const ProductDetailScreen({super.key, required this.product});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  bool _loading = false;
  late Map _p;

  @override
  void initState() { super.initState(); _p = widget.product; }

  Future<void> _buyNow() async {
    final amount = (double.tryParse(_p['price'].toString()) ?? 0) * _qty;
    setState(() => _loading = true);
    try {
      // For now, Shop uses a simple "Create Order" which needs to be aligned with Payment
      // Website pattern: Checkout -> Order Created -> Payment Redirect
      final res = await context.read<ApiService>().createShopOrder({
        'items': [{'product_id': _p['id'], 'quantity': _qty}],
        'shipping_address': 'Default Address', // Should use profile address
      });
      
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(
          type: 'order',
          orderId: res['data']['id'],
          amount: amount,
          label: 'Order #${res['data']['order_number'] ?? res['data']['id']}',
        )));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(_p['image_url'] ?? '', fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(color: AppTheme.background, child: const Icon(Icons.image, size: 64))),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                    Text(_p['category']?['name'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  ])),
                  Text('₹${_p['price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: AppTheme.primary)),
                ]),
                const Divider(height: 40),
                const Text('Product Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(_p['description'] ?? 'No description available.', style: const TextStyle(color: AppTheme.textSecondary, height: 1.6)),
                const SizedBox(height: 24),
                
                // Quantity
                Row(children: [
                   const Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
                   const Spacer(),
                   IconButton(onPressed: _qty > 1 ? () => setState(() => _qty--) : null, icon: const Icon(Icons.remove_circle_outline)),
                   Text('$_qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                   IconButton(onPressed: () => setState(() => _qty++), icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary)),
                ]),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,-5))]),
        child: Row(children: [
          Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Total Price', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            Text('₹${(double.tryParse(_p['price'].toString()) ?? 0) * _qty}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ])),
          ElevatedButton(
            onPressed: _loading ? null : _buyNow,
            style: ElevatedButton.styleFrom(minimumSize: const Size(160, 50)),
            child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Buy Now'),
          ),
        ]),
      ),
    );
  }
}
