// lib/widgets/glass_nav_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/home/home_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/scan/scan_screen.dart';

enum NavTab { home, scan, history }

class GlassNavBar extends StatefulWidget {
  final NavTab currentTab;
  const GlassNavBar({super.key, required this.currentTab});

  @override
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar>
    with TickerProviderStateMixin {
  late AnimationController _pillController;
  late Animation<double> _pillPositionAnim;
  late AnimationController _stretchController;
  late Animation<double> _stretchAnim;
  late List<AnimationController> _iconControllers;
  late List<Animation<double>> _iconScaleAnims;

  double _pillFrom = 0.0;
  double _pillTo = 0.0;

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home', tab: NavTab.home),
    _NavItem(icon: Icons.add_rounded, label: 'Scan', tab: NavTab.scan),
    _NavItem(
        icon: Icons.history_rounded, label: 'History', tab: NavTab.history),
  ];

  @override
  void initState() {
    super.initState();

    final index = _items.indexWhere((i) => i.tab == widget.currentTab);
    _pillFrom = index.toDouble();
    _pillTo = index.toDouble();

    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pillPositionAnim = Tween<double>(begin: _pillFrom, end: _pillTo).animate(
      CurvedAnimation(
        parent: _pillController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _stretchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _stretchAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.5, end: 0.9)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25,
      ),
    ]).animate(_stretchController);

    _iconControllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 180),
      ),
    );
    _iconScaleAnims = _iconControllers.map((c) {
      return Tween<double>(begin: 1.0, end: 0.75).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    _pillController.dispose();
    _stretchController.dispose();
    for (final c in _iconControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _onTap(int index) async {
    final tapped = _items[index].tab;
    if (tapped == widget.currentTab) return;

    HapticFeedback.lightImpact();

    _iconControllers[index].forward().then((_) {
      _iconControllers[index].reverse();
    });

    _pillFrom = _pillTo;
    _pillTo = index.toDouble();

    _pillPositionAnim = Tween<double>(begin: _pillFrom, end: _pillTo).animate(
      CurvedAnimation(
        parent: _pillController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _pillController.reset();
    _stretchController.reset();
    _pillController.forward();
    _stretchController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _navigate(tapped, index);
  }

  void _navigate(NavTab tab, int targetIndex) {
    final currentIndex = _items.indexWhere((i) => i.tab == widget.currentTab);
    final goRight = targetIndex > currentIndex;

    Widget screen;
    switch (tab) {
      case NavTab.home:
        screen = const HomeScreen();
        break;
      case NavTab.scan:
        screen = const ScanScreen();
        break;
      case NavTab.history:
        screen = const HistoryScreen();
        break;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
              ),
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(goRight ? 0.05 : -0.05, 0),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // ✅ The outer container is now the glass layer
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                // Semi-transparent dark to let the Fit Lens background peek through
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.55),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 0.6,
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Liquid pill ──────────────────────────────────────
                  AnimatedBuilder(
                    animation:
                        Listenable.merge([_pillPositionAnim, _stretchAnim]),
                    builder: (context, _) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final totalW = constraints.maxWidth;
                          final itemW = totalW / 3;
                          const pillH = 54.0;
                          const pillBaseW = 54.0;

                          final stretchedW = pillBaseW * _stretchAnim.value;
                          final centerX =
                              (_pillPositionAnim.value * itemW) + (itemW / 2);
                          final direction = (_pillTo - _pillFrom).sign;
                          final stretchOffset =
                              (stretchedW - pillBaseW) / 2 * direction;
                          final left =
                              centerX - (stretchedW / 2) + stretchOffset;
                          const top = (72.0 - pillH) / 2;

                          return Positioned(
                            left: left,
                            top: top,
                            child: _LiquidPill(
                              width: stretchedW,
                              height: pillH,
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // ── Icons ────────────────────────────────────────────
                  Row(
                    children: List.generate(
                      _items.length,
                      (i) => _buildNavItem(i),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _items[index];
    final isActive = item.tab == widget.currentTab;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _iconScaleAnims[index],
          builder: (context, child) => Transform.scale(
            scale: _iconScaleAnims[index].value,
            child: child,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.35),
                size: isActive ? 25 : 22,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: isActive
                    ? Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          item.label,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Liquid Pill Widget ───────────────────────────────────────────────────────

class _LiquidPill extends StatelessWidget {
  final double width;
  final double height;

  // Bringing in your primary color!
  static const Color _primary = Color(0xFF10B981);

  const _LiquidPill({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        // ✅ The pill is now a glowing liquid bubble using your theme color
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primary.withValues(alpha: 0.8),
            _primary.withValues(alpha: 0.4),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Stack(
        children: [
          // Top shine streak to keep that 3D glass-liquid feel
          Positioned(
            top: 4,
            left: 10,
            right: 10,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav Item Model ───────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  final NavTab tab;
  const _NavItem({required this.icon, required this.label, required this.tab});
}
