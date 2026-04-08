import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import 'blog_detail_screen.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});
  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  List _blogs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().getBlogs();
      setState(() => _blogs = res['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plant Care Blogs 📖')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _blogs.isEmpty
              ? const Center(child: Text('No articles yet', style: TextStyle(color: AppTheme.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _blogs.length,
                    itemBuilder: (_, i) {
                      final b = _blogs[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: GkmCard(
                          padding: EdgeInsets.zero,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlogDetailScreen(blog: b))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: Image.network(b['featured_image'] ?? '', height: 160, width: double.infinity, fit: BoxFit.cover,
                                errorBuilder: (_,__,___) => Container(height: 160, color: AppTheme.background, child: const Icon(Icons.image_outlined, size: 48, color: AppTheme.border))),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(b['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, height: 1.3)),
                                const SizedBox(height: 8),
                                Text(b['excerpt'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 12),
                                Row(children: [
                                  const Icon(Icons.calendar_today, size: 12, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(b['created_at']?.toString().split(' ')[0] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                  const Spacer(),
                                  const Text('Read More →', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                ]),
                              ]),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
