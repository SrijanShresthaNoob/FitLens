// lib/screens/history/history_screen.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
// Add import at top
import '../../widgets/glass_nav_bar.dart';
import '../../models/user_profile.dart';
import '../../providers/nutrition_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  UserProfile? _profile;

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _navBarController;
  late AnimationController _listController;

  // Animations
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;
  late List<Animation<Offset>> _listSlideAnims;
  late List<Animation<double>> _listFadeAnims;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _setupAnimations();
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
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _navBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Generate staggered animations for up to 20 list items
    _listSlideAnims = List.generate(20, (i) {
      final start = (i * 0.08).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _listController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));
    });

    _listFadeAnims = List.generate(20, (i) {
      final start = (i * 0.08).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _listController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ));
    });
  }

  void _startAnimations() async {
    _fadeController.forward();
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _listController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _navBarController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _navBarController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('userProfile');
    if (raw != null) {
      setState(() => _profile = UserProfile.fromJson(jsonDecode(raw)));
    }
  }

  // Groups all entries by date label (Today, Yesterday, or date string)
  Map<String, List<dynamic>> _groupEntriesByDate(List<dynamic> entries) {
    final Map<String, List<dynamic>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final entry in entries) {
      final entryDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );

      String label;
      if (entryDate == today) {
        label = 'Today';
      } else if (entryDate == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat('EEEE, MMM d').format(entryDate);
      }

      grouped.putIfAbsent(label, () => []).add(entry);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      extendBody: true,
      body: Consumer<NutritionProvider>(
        builder: (context, nutrition, _) {
          final allEntries = nutrition.allEntries; // all-time entries
          final grouped = _groupEntriesByDate(allEntries);
          final dateKeys = grouped.keys.toList();

          return FadeTransition(
            opacity: _fadeAnim,
            child: allEntries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 120, 20, 110),
                    itemCount: dateKeys.length,
                    itemBuilder: (context, sectionIndex) {
                      final dateLabel = dateKeys[sectionIndex];
                      final entries = grouped[dateLabel]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Section Header
                          _buildDateHeader(dateLabel, sectionIndex),
                          const SizedBox(height: 12),

                          // Food entries for this date
                          ...List.generate(entries.length, (entryIndex) {
                            final globalIndex = sectionIndex * 3 + entryIndex;
                            final safeIndex = globalIndex.clamp(
                                0, _listSlideAnims.length - 1);
                            final entry = entries[entryIndex];

                            return SlideTransition(
                              position: _listSlideAnims[safeIndex],
                              child: FadeTransition(
                                opacity: _listFadeAnims[safeIndex],
                                child: _buildHistoryCard(entry),
                              ),
                            );
                          }),

                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
          );
        },
      ),
      bottomNavigationBar: const GlassNavBar(currentTab: NavTab.history),
    );
  }

  // ─── Frosted Glass AppBar ─────────────────────────────────────────────────

  PreferredSizeWidget _buildGlassAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(90),
      child: SlideTransition(
        position: _slideAnim,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
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
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(
                                    alpha: _pulseAnim.value * 0.5,
                                  ),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFF0D3D2E),
                          child: Text(
                            _profile?.name.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
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

  // ─── Date Section Header ──────────────────────────────────────────────────

  Widget _buildDateHeader(String label, int index) {
    final safeIndex = index.clamp(0, _listFadeAnims.length - 1);
    return FadeTransition(
      opacity: _listFadeAnims[safeIndex],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── History Card ─────────────────────────────────────────────────────────

  Widget _buildHistoryCard(entry) {
    final timeStr = DateFormat('hh:mm a').format(entry.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji Container
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
              ),
            ),
            child: Center(
              child: Text(
                entry.emoji ?? '🍽️',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Name + Macros
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Time row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Macro dots row
                Row(
                  children: [
                    _macroDot(
                      const Color(0xFF10B981),
                      '${entry.protein.toInt()}g P',
                    ),
                    const SizedBox(width: 10),
                    _macroDot(
                      const Color(0xFF8B5CF6),
                      '${entry.carbs.toInt()}g C',
                    ),
                    const SizedBox(width: 10),
                    _macroDot(
                      const Color(0xFFF59E0B),
                      '${entry.fat.toInt()}g F',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Calories
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.calories.toInt()}',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
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
    );
  }

  Widget _macroDot(Color color, String label) => Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  // ─── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, val, child) =>
                Transform.scale(scale: val, child: child),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF111118),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text('📋', style: TextStyle(fontSize: 38)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No history yet',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning food to build\nyour history!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── Liquid Glass Nav Bar ─────────────────────────────────────────────────
}
