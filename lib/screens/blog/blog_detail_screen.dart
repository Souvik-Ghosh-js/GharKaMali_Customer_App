import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../utils/app_theme.dart';

class BlogDetailScreen extends StatelessWidget {
  final Map blog;
  const BlogDetailScreen({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(blog['featured_image'] ?? '', fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(color: AppTheme.background)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(blog['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, height: 1.3)),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  const Text('GKM Team', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(width: 16),
                  const Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(blog['created_at']?.toString().split(' ')[0] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ]),
                const Divider(height: 40),
                
                // Content (Support HTML)
                HtmlWidget(
                  blog['content'] ?? '',
                  textStyle: const TextStyle(height: 1.6, fontSize: 15),
                ),
                
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
