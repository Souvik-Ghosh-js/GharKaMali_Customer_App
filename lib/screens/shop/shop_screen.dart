import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import 'product_detail_screen.dart';
import 'shop_orders_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List _products = [];
  List _categories = [];
  int? _selectedCategory;
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final api = context.read<ApiService>();
    try {
      final [c, p] = await Future.wait([
        api.getShopCategories(),
        api.getShopProducts(categoryId: _selectedCategory, search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null),
      ]);
      setState(() {
        _categories = c['data'] ?? [];
        _products = p['data'] ?? [];
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GKM Shop 🪴'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopOrdersScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search seeds, pots, soil...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _load(); }) : null,
                ),
                onSubmitted: (_) => _load(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip(null, 'All'),
                    ..._categories.map((c) => _filterChip(c['id'], c['name'])),
                  ],
                ),
              ),
            ]),
          ),

          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _products.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.search_off, size: 64, color: AppTheme.border),
                    const SizedBox(height: 12),
                    const Text('No products found', style: TextStyle(color: AppTheme.textSecondary)),
                  ]))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.7,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (_, i) => _ProductCard(product: _products[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(int? id, String label) {
    final sel = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: sel,
        onSelected: (s) { if (s) setState(() { _selectedCategory = id; _loading = true; _load(); }); },
        selectedColor: AppTheme.primary,
        labelStyle: TextStyle(color: sel ? Colors.white : AppTheme.textPrimary, fontWeight: sel ? FontWeight.bold : FontWeight.normal, fontSize: 13),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map product;
  const _ProductCard({required this.product});
  @override
  Widget build(BuildContext context) => GkmCard(
    padding: EdgeInsets.zero,
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        child: Image.network(product['image_url'] ?? '', fit: BoxFit.cover, width: double.infinity,
          errorBuilder: (_,__,___) => Container(color: AppTheme.background, child: const Icon(Icons.image_outlined, color: AppTheme.border))),
      )),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(product['category']?['name'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          Row(children: [
            Text('₹${product['price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
            const Spacer(),
            if (product['stock_quantity'] != null && (product['stock_quantity'] as int) < 10)
              Text('Only ${product['stock_quantity']} left', style: const TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
          ]),
        ]),
      ),
    ]),
  );
}
