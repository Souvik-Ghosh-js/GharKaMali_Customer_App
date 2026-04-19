import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/app_theme.dart';

class BenefitsCarouselScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  const BenefitsCarouselScreen({super.key, required this.plan});

  @override
  State<BenefitsCarouselScreen> createState() => _BenefitsCarouselScreenState();
}

class _BenefitsCarouselScreenState extends State<BenefitsCarouselScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;

  List<_Slide> get _slides {
    final visits = widget.plan['visits_per_month'] ?? '?';
    final plants = widget.plan['max_plants'] ?? '?';
    final price = widget.plan['price'] ?? '?';
    final name = widget.plan['name'] ?? 'Plan';
    return [
      _Slide(
        icon: Icons.local_florist,
        color: const Color(0xFF10B981),
        title: 'Welcome to $name',
        subtitle: 'Professional garden care delivered right to your doorstep.',
      ),
      _Slide(
        icon: Icons.calendar_month,
        color: const Color(0xFF3B82F6),
        title: '$visits Expert Visits / Month',
        subtitle: 'Certified gardeners visit on your chosen dates — no last-minute surprises.',
      ),
      _Slide(
        icon: Icons.eco,
        color: const Color(0xFF8B5CF6),
        title: 'Up to $plants Plants Covered',
        subtitle: 'Every plant in your home or garden gets professional attention.',
      ),
      _Slide(
        icon: Icons.currency_rupee,
        color: const Color(0xFFF59E0B),
        title: 'Only ₹$price / Month',
        subtitle: 'Save up to 30% vs per-visit pricing. Cancel anytime.',
      ),
      _Slide(
        icon: Icons.verified,
        color: const Color(0xFFEF4444),
        title: '100% Satisfaction Guaranteed',
        subtitle: 'Not happy? We re-visit for free or give you a full refund.',
      ),
    ];
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _proceed();
    }
  }

  void _proceed() {
    Navigator.pushReplacementNamed(
      context,
      '/schedule-subscription',
      arguments: widget.plan,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    return Scaffold(
      backgroundColor: slide.color.withOpacity(0.06),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _proceed,
            child: const Text('Skip', style: TextStyle(color: Colors.black54)),
          ),
        ],
      ),
      body: Column(children: [
        // Page indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: List.generate(_slides.length, (i) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= _page ? slide.color : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )),
          ),
        ),

        // Carousel pages
        Expanded(
          child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _slides.length,
            itemBuilder: (_, i) {
              final s = _slides[i];
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: s.color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(s.icon, color: s.color, size: 70),
                    ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
                    const SizedBox(height: 40),
                    Text(
                      s.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 16),
                    Text(
                      s.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black.withOpacity(0.55),
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: Column(children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: slide.color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _page == _slides.length - 1 ? 'Schedule My Visits →' : 'Next',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_page + 1} of ${_slides.length}',
              style: const TextStyle(color: Colors.black38, fontSize: 13),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Slide {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  const _Slide({required this.icon, required this.color, required this.title, required this.subtitle});
}
