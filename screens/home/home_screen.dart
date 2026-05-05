// lib/screens/home/home_screen.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/user_profile.dart';
import '../../providers/nutrition_provider.dart';
import '../../widgets/macro_ring.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/glass_nav_bar.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  UserProfile? _profile;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _cardController;
  late AnimationController _blobController;

  // Animations
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late List<Animation<Offset>> _cardSlideAnims;
  late List<Animation<double>> _cardFadeAnims;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProfile();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _cardSlideAnims = List.generate(6, (i) {
      final start = (i * 0.12).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _cardController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));
    });
    _cardFadeAnims = List.generate(6, (i) {
      final start = (i * 0.12).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _cardController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ));
    });

    // Blob slow drift
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  void _startAnimations() async {
    _fadeController.forward();
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _cardController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _cardController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('userProfile');
    if (raw != null) {
      setState(() => _profile = UserProfile.fromJson(jsonDecode(raw)));
    }
  }

  Widget _animCard({required int index, required Widget child}) {
    final safe = index.clamp(0, _cardSlideAnims.length - 1);
    return SlideTransition(
      position: _cardSlideAnims[safe],
      child: FadeTransition(
        opacity: _cardFadeAnims[safe],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      extendBody: true,
      body: Stack(
        children: [
          // Animated blue blob background
          _buildBlobBackground(),

          Consumer<NutritionProvider>(
            builder: (context, nutrition, _) {
              return FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ring
                      _animCard(
                        index: 0,
                        child: Center(
                          child: MacroRing(
                            calories: nutrition.totalCalories,
                            calorieTarget: _profile?.dailyCalories ?? 2000,
                            protein: nutrition.totalProtein,
                            proteinTarget: _profile?.proteinTarget ?? 150,
                            carbs: nutrition.totalCarbs,
                            carbsTarget: _profile?.carbsTarget ?? 200,
                            fat: nutrition.totalFat,
                            fatTarget: _profile?.fatTarget ?? 65,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Legend
                      _animCard(
                        index: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _legendDot(const Color(0xFF10B981), 'Calories'),
                            const SizedBox(width: 16),
                            _legendDot(const Color(0xFF8B5CF6), 'Protein'),
                            const SizedBox(width: 16),
                            _legendDot(const Color(0xFFF59E0B), 'Carbs'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Macro cards
                      _animCard(
                        index: 1,
                        child: Row(
                          children: [
                            _macroCard(
                              'Protein',
                              nutrition.totalProtein.toInt(),
                              (_profile?.proteinTarget ?? 150),
                              const Color(0xFF8B5CF6),
                              Icons.fitness_center_rounded,
                            ),
                            const SizedBox(width: 10),
                            _macroCard(
                              'Carbs',
                              nutrition.totalCarbs.toInt(),
                              (_profile?.carbsTarget ?? 200),
                              const Color(0xFFF59E0B),
                              Icons.grain_rounded,
                            ),
                            const SizedBox(width: 10),
                            _macroCard(
                              'Fat',
                              nutrition.totalFat.toInt(),
                              (_profile?.fatTarget ?? 65),
                              const Color(0xFF3B82F6),
                              Icons.water_drop_rounded,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Ad banner
                      _animCard(
                        index: 2,
                        child: const AdBannerWidget(),
                      ),

                      const SizedBox(height: 24),

                      // Today's logs header
                      _animCard(
                        index: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today's Food",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${nutrition.todayEntries.length} items',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Food list
                      nutrition.todayEntries.isEmpty
                          ? _animCard(index: 4, child: _emptyState())
                          : Column(
                              children: List.generate(
                                nutrition.todayEntries.length,
                                (i) {
                                  final entry = nutrition.todayEntries[i];
                                  return _animCard(
                                    index: (i + 4).clamp(0, 5),
                                    child: Dismissible(
                                      key: Key(entry.key.toString()),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding:
                                            const EdgeInsets.only(right: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.red
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Icon(Icons.delete_rounded,
                                            color: Colors.red),
                                      ),
                                      onDismissed: (_) =>
                                          nutrition.removeEntry(entry),
                                      child: _foodCard(entry),
                                    ),
                                  );
                                },
                              ),
                            ),

                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const GlassNavBar(currentTab: NavTab.home),
    );
  }

  // ─── Animated Blob Background ──────────────────────────────────────────────

  Widget _buildBlobBackground() {
    return AnimatedBuilder(
      animation: _blobController,
      builder: (context, _) {
        final t = _blobController.value;
        final size = MediaQuery.of(context).size;

        // Blob 1 — drifts top-left to center
        final b1x = size.width * (0.1 + 0.25 * t);
        final b1y = size.height * (0.1 + 0.15 * t);

        // Blob 2 — drifts bottom-right
        final b2x = size.width * (0.6 - 0.2 * t);
        final b2y = size.height * (0.5 + 0.2 * t);

        return Stack(
          children: [
            // Blob 1 — deep blue
            Positioned(
              left: b1x - 150,
              top: b1y - 150,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1E3A8A).withValues(alpha: 0.35),
                      const Color(0xFF1E40AF).withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: const SizedBox(),
                ),
              ),
            ),

            // Blob 2 — indigo/violet blue
            Positioned(
              left: b2x - 140,
              top: b2y - 140,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF3730A3).withValues(alpha: 0.3),
                      const Color(0xFF4338CA).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: const SizedBox(),
                ),
              ),
            ),

            // Blob 3 — subtle cyan accent, top right
            Positioned(
              right: size.width * (0.05 + 0.1 * (1 - t)) - 100,
              top: size.height * (0.3 - 0.1 * t),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0EA5E9).withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: const SizedBox(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: SlideTransition(
        position: _slideAnim,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('EEEE, MMM d').format(DateTime.now()),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'FitLens',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      // Avatar — no glow, matte
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, animation, __) =>
                                const ProfileScreen(),
                            transitionsBuilder: (_, animation, __, child) {
                              return FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOut,
                                ),
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.94, end: 1.0)
                                      .animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: child,
                                ),
                              );
                            },
                          ),
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.15),
                            border: Border.all(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _profile?.name.substring(0, 1).toUpperCase() ??
                                  'U',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Legend Dot ────────────────────────────────────────────────────────────

  Widget _legendDot(Color color, String label) => Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      );

  // ─── Macro Card ────────────────────────────────────────────────────────────

  Widget _macroCard(
    String label,
    int value,
    double target,
    Color color,
    IconData icon,
  ) {
    final progress = (value / target).clamp(0.0, 1.0);
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(height: 8),
                Text(
                  '${value}g',
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '/ ${target.toInt()}g',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar — matte, no glow
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (_, val, __) => LinearProgressIndicator(
                      value: val,
                      minHeight: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Food Card ─────────────────────────────────────────────────────────────

  Widget _foodCard(entry) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  // Emoji box
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        entry.emoji ?? '🍽️',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _macroPill('P: ${entry.protein.toInt()}g',
                                const Color(0xFF8B5CF6)),
                            const SizedBox(width: 6),
                            _macroPill('C: ${entry.carbs.toInt()}g',
                                const Color(0xFFF59E0B)),
                            const SizedBox(width: 6),
                            _macroPill('F: ${entry.fat.toInt()}g',
                                const Color(0xFF3B82F6)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${entry.calories.toInt()}',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'kcal',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _macroPill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  // ─── Empty State ───────────────────────────────────────────────────────────

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Center(
                  child: Text('🍽️', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No food logged today',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap + to scan your first meal',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      );
}
