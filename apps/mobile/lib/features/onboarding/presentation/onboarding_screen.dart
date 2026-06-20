import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
class _C {
  static const bg             = Color(0xFF0B1326);
  static const glassCard      = Color(0x08FFFFFF);
  static const glassCardBorder= Color(0x0DFFFFFF);
  static const primaryCont    = Color(0xFFDDB7FF);
  static const deepPurple     = Color(0xFF842BD2);
  static const btnPurple      = Color(0xFF7C3AED);
  static const onSurfaceVar   = Color(0xFFCDC3D0);
  static const onSurfaceMuted = Color(0xFFCFC2D6);
  static const outline        = Color(0xFF968E99);
  static const outlineVar     = Color(0xFF4B444F);
  static const tertiary       = Color(0xFF6FFBBE);
  static const surfaceVar     = Color(0xFF353436);
}

// ── Slide model ───────────────────────────────────────────────────────────────
class _SlideData {
  final String chip, headlineWhite, headlineAccent, body;
  final List<_FeatureItem> features;
  final bool italicHeadline;
  const _SlideData({
    required this.chip, required this.headlineWhite,
    required this.headlineAccent, required this.body,
    this.features = const [], this.italicHeadline = false,
  });
}

class _FeatureItem {
  final IconData icon;
  final Color iconColor;
  final String label, title;
  const _FeatureItem({required this.icon, required this.iconColor,
    required this.label, required this.title});
}

const _slides = [
  _SlideData(
    chip: 'PHASE ONE',
    headlineWhite: 'TRANSFORM\n', headlineAccent: 'YOUR BODY',
    body: 'Access world-class programming tailored to your biology. Every rep, every meal, and every recovery session is engineered for your peak performance.',
  ),
  _SlideData(
    chip: 'NUTRITION & WELLNESS',
    headlineWhite: 'Elevate Your\n', headlineAccent: 'Wellness',
    body: 'Master your body beyond the weights. Our precision nutrition coaching and recovery tracking synchronize with your lifestyle for peak human performance.',
    italicHeadline: true,
    features: [
      _FeatureItem(icon: Icons.restaurant_outlined, iconColor: _C.primaryCont, label: 'MACRO FOCUS',  title: 'Smart Fuel'),
      _FeatureItem(icon: Icons.analytics_outlined,  iconColor: _C.tertiary,    label: 'BIO-FEEDBACK', title: 'Live Data'),
    ],
  ),
  _SlideData(
    chip: 'ELITE PERFORMANCE',
    headlineWhite: 'Train Like\n', headlineAccent: 'An Elite',
    body: 'Join thousands of athletes who\'ve unlocked their peak. AI-powered coaching, real-time recovery scores, and a community that pushes you further.',
    italicHeadline: true,
    features: [
      _FeatureItem(icon: Icons.bolt_outlined,   iconColor: _C.primaryCont, label: 'AI COACH',  title: 'Smart Plan'),
      _FeatureItem(icon: Icons.groups_outlined, iconColor: _C.tertiary,    label: 'COMMUNITY', title: 'The Circle'),
    ],
  ),
];

const _totalPages = 3;

// ── Screen ────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _current = 0;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _current = index);
    _fadeCtrl.forward(from: 0);
    _slideCtrl.forward(from: 0);
  }

  void _next() {
    if (_current < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent));

    return Scaffold(
      backgroundColor: _C.bg,
      body: PageView.builder(
        controller: _pageController,
        itemCount: _totalPages,
        onPageChanged: _onPageChanged,
        itemBuilder: (ctx, index) {
          final slide  = _slides[index];
          final isLast = index == _totalPages - 1;
          return _ContentSlide(
            slide: slide,
            current: _current,
            total: _totalPages,
            isLast: isLast,
            onNext: _next,
            fadeAnim: _fadeAnim,
            slideAnim: _slideAnim,
          );
        },
      ),
    );
  }
}

// ── Page dots ─────────────────────────────────────────────────────────────────
class _Dots extends StatelessWidget {
  final int current, total;
  const _Dots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(total, (i) {
      final active = i == current;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: active ? 24 : 6, height: 6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          gradient: active
            ? const LinearGradient(colors: [_C.deepPurple, _C.primaryCont])
            : null,
          color: active ? null : _C.outlineVar.withValues(alpha: 0.4),
          boxShadow: active
            ? [BoxShadow(color: _C.primaryCont.withValues(alpha: 0.4), blurRadius: 8)]
            : null,
        ),
      );
    }));
}

// ── Content Slide (pages 1-3) ─────────────────────────────────────────────────
class _ContentSlide extends StatelessWidget {
  final _SlideData slide;
  final int current, total;
  final bool isLast;
  final VoidCallback onNext;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  const _ContentSlide({
    required this.slide, required this.current, required this.total,
    required this.isLast, required this.onNext,
    required this.fadeAnim, required this.slideAnim,
  });

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final top    = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background smoke
        Image.asset('assets/images/background.png', fit: BoxFit.cover,
          color: Colors.black.withValues(alpha: 0.35), colorBlendMode: BlendMode.darken),
        // Athlete image (visible on first content slide)
        AnimatedOpacity(
          opacity: current == 1 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: Image.asset('assets/images/dumbell.png',
            fit: BoxFit.cover, alignment: Alignment.centerRight,
            errorBuilder: (_, __, ___) => const SizedBox.shrink())),
        // Bottom gradient
        Positioned(
          bottom: 0, left: 0, right: 0,
          height: size.height * 0.55,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xCC0E0E0F), Color(0xFF0E0E0F)],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // Top gradient
        Positioned(
          top: 0, left: 0, right: 0,
          height: size.height * 0.2,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0E0E0F), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // Logo
        Positioned(
          top: top + 16, left: 20, right: 20,
          child: Center(
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              child: Image.asset('assets/images/12circle-logo.png',
                height: 40, fit: BoxFit.contain),
            ),
          ),
        ),
        // Animated slide content
        Positioned(
          bottom: bottom + 16, left: 20, right: 20,
          child: FadeTransition(
            opacity: fadeAnim,
            child: SlideTransition(
              position: slideAnim,
              child: _SlideContent(
                slide: slide, current: current, total: total,
                isLast: isLast, onNext: onNext),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Slide content ─────────────────────────────────────────────────────────────
class _SlideContent extends StatelessWidget {
  final _SlideData slide;
  final int current, total;
  final bool isLast;
  final VoidCallback onNext;
  const _SlideContent({required this.slide, required this.current,
    required this.total, required this.isLast, required this.onNext});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      // Chip
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: _C.surfaceVar.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _C.outlineVar.withValues(alpha: 0.2))),
        child: Text(slide.chip,
          style: const TextStyle(color: _C.primaryCont, fontSize: 9,
            fontWeight: FontWeight.w600, letterSpacing: 2))),
      const SizedBox(height: 12),
      // Headline
      RichText(text: TextSpan(children: [
        TextSpan(text: slide.headlineWhite,
          style: TextStyle(
            color: Colors.white,
            fontSize: slide.italicHeadline ? 32 : 44,
            fontWeight: FontWeight.w800,
            fontStyle: slide.italicHeadline ? FontStyle.italic : FontStyle.normal,
            height: 1.05, letterSpacing: slide.italicHeadline ? -0.5 : -1)),
        TextSpan(text: slide.headlineAccent,
          style: TextStyle(
            color: _C.primaryCont,
            fontSize: slide.italicHeadline ? 32 : 44,
            fontWeight: FontWeight.w800,
            fontStyle: slide.italicHeadline ? FontStyle.italic : FontStyle.normal,
            height: 1.05, letterSpacing: slide.italicHeadline ? -0.5 : -1)),
      ])),
      const SizedBox(height: 16),
      // Body
      Text(slide.body,
        style: const TextStyle(color: _C.onSurfaceVar, fontSize: 16,
          fontWeight: FontWeight.w400, height: 1.6)),
      // Feature cards
      if (slide.features.isNotEmpty) ...[
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _FeatureCard(item: slide.features[0])),
          const SizedBox(width: 12),
          Expanded(child: Transform.translate(
            offset: const Offset(0, 14),
            child: _FeatureCard(item: slide.features[1]))),
        ]),
        const SizedBox(height: 32),
      ] else
        const SizedBox(height: 24),
      // Dots
      _Dots(current: current, total: total),
      const SizedBox(height: 20),
      // Next / Get Started button
      GestureDetector(
        onTap: onNext,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: _C.btnPurple,
            boxShadow: const [
              BoxShadow(color: Color(0x667C3AED), blurRadius: 24,
                offset: Offset(0, 10))]),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(isLast ? 'GET STARTED' : 'NEXT',
              style: TextStyle(
                color: Colors.white,
                fontSize: isLast ? 14 : 16,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                letterSpacing: isLast ? 3 : 2)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ]))),
      const SizedBox(height: 20),
      // Sign in link (first content slide)
      if (current == 0)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('ALREADY AN ELITE MEMBER? ',
            style: TextStyle(color: _C.outline, fontSize: 11,
              fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          GestureDetector(
            onTap: () => context.go('/login'),
            child: const Text('SIGN IN',
              style: TextStyle(color: _C.primaryCont, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.2))),
        ]),
    ]);
}

// ── Feature card ──────────────────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final _FeatureItem item;
  const _FeatureCard({required this.item});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _C.glassCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.glassCardBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(item.icon, color: item.iconColor, size: 18),
        const SizedBox(width: 8),
        Text(item.label, style: const TextStyle(
          color: _C.onSurfaceMuted, fontSize: 9,
          fontWeight: FontWeight.w600, letterSpacing: 1.5)),
      ]),
      const SizedBox(height: 8),
      Text(item.title, style: const TextStyle(
        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
    ]));
}
