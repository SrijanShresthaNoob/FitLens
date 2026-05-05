// lib/screens/onboarding/onboarding_screen.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import '../../utils/calorie_calculator.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  // Form values
  final _nameController = TextEditingController();
  String _gender = 'male';
  String _activityLevel = 'moderate';
  String _goal = 'maintain';

  // Slider values
  double _age = 25;
  double _height = 170;
  double _weight = 70;

  static const Color _primary = Color(0xFF10B981);
  static const Color _bg = Color(0xFF0A0A0F);

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;
  late AnimationController _pulseController;
  late AnimationController _contentController;

  // Animations
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _buttonScaleAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _contentFadeAnim;
  late Animation<Offset> _contentSlideAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _buttonScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeOutBack,
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentFadeAnim = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );
    _contentSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimations() async {
    _fadeController.forward();
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _contentController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _buttonController.forward();
  }

  void _animatePageContent() {
    _contentController.reset();
    _contentController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _buttonController.dispose();
    _pulseController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      _animatePageContent();
    } else {
      _saveAndContinue();
    }
  }

  void _prevPage() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      _animatePageContent();
    }
  }

  Future<void> _saveAndContinue() async {
    HapticFeedback.mediumImpact();

    final w = _weight;
    final h = _height;
    final a = _age.toInt();

    final bmr = CalorieCalculator.calculateBMR(
      weightKg: w,
      heightCm: h,
      age: a,
      gender: _gender,
    );
    final tdee = CalorieCalculator.calculateTDEE(bmr, _activityLevel);
    final cal = CalorieCalculator.adjustForGoal(tdee, _goal);
    final macros = CalorieCalculator.calculateMacros(cal, _goal);

    final profile = UserProfile(
      name: _nameController.text.isEmpty ? 'User' : _nameController.text,
      weightKg: w,
      heightCm: h,
      age: a,
      gender: _gender,
      activityLevel: _activityLevel,
      goal: _goal,
      dailyCalories: cal,
      proteinTarget: macros['protein']!,
      carbsTarget: macros['carbs']!,
      fatTarget: macros['fat']!,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userProfile', jsonEncode(profile.toJson()));
    await prefs.setBool('onboardingDone', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Subtle background glow
            _buildBackgroundGlow(),

            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  _buildTopBar(),

                  // Page content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) {
                        setState(() => _currentPage = i);
                      },
                      children: [
                        _buildNamePage(),
                        _buildBodyPage(),
                        _buildActivityPage(),
                        _buildGoalPage(),
                      ],
                    ),
                  ),

                  // Bottom button
                  _buildBottomButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Background Glow ──────────────────────────────────────────────────────

  Widget _buildBackgroundGlow() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        return Stack(
          children: [
            // Top right glow
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _primary.withValues(alpha: _pulseAnim.value * 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom left glow
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _primary.withValues(alpha: _pulseAnim.value * 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Top Bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return SlideTransition(
      position: _slideAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            // Back button glass
            if (_currentPage > 0)
              GestureDetector(
                onTap: _prevPage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 44),

            // Step indicators
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (i) {
                  final isActive = i == _currentPage;
                  final isPast = i < _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 28 : 18,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isActive
                          ? _primary
                          : isPast
                              ? _primary.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.15),
                    ),
                  );
                }),
              ),
            ),

            // Skip on last page
            if (_currentPage == _totalPages - 1)
              GestureDetector(
                onTap: _saveAndContinue,
                child: Text(
                  'Skip',
                  style: GoogleFonts.poppins(
                    color: _primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Button ────────────────────────────────────────────────────────

  Widget _buildBottomButton() {
    final isLast = _currentPage == _totalPages - 1;
    return ScaleTransition(
      scale: _buttonScaleAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: GestureDetector(
          onTap: _nextPage,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _primary,
                      Color(0xFF059669),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(
                        alpha: _pulseAnim.value * 0.4,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLast ? 'Get Started' : 'Continue Setup',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Page 1: Name ─────────────────────────────────────────────────────────

  Widget _buildNamePage() {
    return SlideTransition(
      position: _contentSlideAnim,
      child: FadeTransition(
        opacity: _contentFadeAnim,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Glass card containing everything
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.07),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Initialize Profile',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'To optimize your biometric models,\nwhat is your preferred name?',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Preferred Name',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildGlassTextField(
                          controller: _nameController,
                          hint: 'e.g. Alex',
                          keyboardType: TextInputType.name,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Page 2: Body Metrics ─────────────────────────────────────────────────

  Widget _buildBodyPage() {
    return SlideTransition(
      position: _contentSlideAnim,
      child: FadeTransition(
        opacity: _contentFadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Metrics',
                style: GoogleFonts.poppins(
                  color: _primary,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Calibrate your baseline for optimal precision.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Gender selector
              _buildGlassMetricCard(
                label: 'GENDER',
                icon: Icons.person_outline_rounded,
                child: Row(
                  children: [
                    _buildGenderOption('male', 'Male', Icons.male_rounded),
                    const SizedBox(width: 12),
                    _buildGenderOption(
                        'female', 'Female', Icons.female_rounded),
                    const SizedBox(width: 12),
                    _buildGenderOption('other', 'Other', Icons.person_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Age stepper
              _buildGlassMetricCard(
                label: 'AGE',
                icon: Icons.cake_outlined,
                child: Row(
                  children: [
                    // Minus
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (_age > 10) setState(() => _age--);
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.remove_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${_age.toInt()}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: ' yrs',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Plus
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (_age < 100) setState(() => _age++);
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Height slider
              _buildGlassMetricCard(
                label: 'HEIGHT',
                icon: Icons.height_rounded,
                trailing: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${_height.toInt()}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' cm',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    _buildGlassSlider(
                      value: _height,
                      min: 140,
                      max: 220,
                      onChanged: (v) => setState(() => _height = v),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('140',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 11)),
                          Text('220',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Weight slider
              _buildGlassMetricCard(
                label: 'WEIGHT',
                icon: Icons.monitor_weight_outlined,
                trailing: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _weight.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' kg',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    _buildGlassSlider(
                      value: _weight,
                      min: 40,
                      max: 150,
                      divisions: 220,
                      onChanged: (v) => setState(() => _weight = v),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('40',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 11)),
                          Text('150',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Page 3: Activity ─────────────────────────────────────────────────────

  Widget _buildActivityPage() {
    final levels = [
      {
        'id': 'sedentary',
        'label': 'No activity',
        'desc': 'Sedentary lifestyle, primarily desk work.',
        'icon': Icons.weekend_outlined,
      },
      {
        'id': 'light',
        'label': 'Low',
        'desc': 'Light active routine 1-3 days a week.',
        'icon': Icons.directions_walk_rounded,
      },
      {
        'id': 'moderate',
        'label': 'Medium',
        'desc': 'Moderate exercise 3-5 days a week.',
        'icon': Icons.directions_run_rounded,
      },
      {
        'id': 'active',
        'label': 'Highly active',
        'desc': 'Intense training 6+ days a week.',
        'icon': Icons.fitness_center_rounded,
      },
      {
        'id': 'very_active',
        'label': 'Extreme',
        'desc': 'Physical job + daily intense exercise.',
        'icon': Icons.bolt_rounded,
      },
    ];

    return SlideTransition(
      position: _contentSlideAnim,
      child: FadeTransition(
        opacity: _contentFadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Baseline\nActivity',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Select your current level to calibrate\noptimization protocols.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              ...levels.asMap().entries.map((entry) {
                final i = entry.key;
                final l = entry.value;
                final isSelected = _activityLevel == l['id'];

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + i * 80),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, child) => Opacity(
                    opacity: val,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - val)),
                      child: child,
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _activityLevel = l['id'] as String);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _primary.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? _primary.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.08),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon box
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primary.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              l['icon'] as IconData,
                              color: isSelected ? _primary : Colors.grey[500],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l['label'] as String,
                                  style: GoogleFonts.poppins(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.85),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l['desc'] as String,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Radio
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isSelected ? _primary : Colors.grey[600]!,
                                width: isSelected ? 6 : 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Page 4: Goal ─────────────────────────────────────────────────────────

  Widget _buildGoalPage() {
    final goals = [
      {
        'id': 'lose_fat',
        'label': 'Lose Fat',
        'desc': 'Maximize calorie burn and lean out safely.',
        'icon': Icons.local_fire_department_rounded,
      },
      {
        'id': 'maintain',
        'label': 'Maintain Weight',
        'desc': 'Optimize metabolism and body recomposition.',
        'icon': Icons.balance_rounded,
      },
      {
        'id': 'gain_muscle',
        'label': 'Gain Muscle',
        'desc': 'Focus on hypertrophy and strength metrics.',
        'icon': Icons.fitness_center_rounded,
      },
    ];

    return SlideTransition(
      position: _contentSlideAnim,
      child: FadeTransition(
        opacity: _contentFadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Define your\ntarget.',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Select your primary objective to calibrate\nyour FitLens AI baseline metrics.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ...goals.asMap().entries.map((entry) {
                final i = entry.key;
                final g = entry.value;
                final isSelected = _goal == g['id'];

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + i * 100),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, child) => Opacity(
                    opacity: val,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - val)),
                      child: child,
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _goal = g['id'] as String);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _primary.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? _primary.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.08),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon box
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primary.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              g['icon'] as IconData,
                              color: isSelected ? _primary : Colors.grey[600],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g['label'] as String,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  g['desc'] as String,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Radio indicator
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isSelected ? _primary : Colors.grey[600]!,
                                width: isSelected ? 6 : 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Reusable Glass Metric Card ───────────────────────────────────────────

  Widget _buildGlassMetricCard({
    required String label,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (trailing != null) trailing,
                  if (trailing == null)
                    Icon(icon, color: Colors.grey[600], size: 18),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }

  // ─── Glass Slider ─────────────────────────────────────────────────────────

  Widget _buildGlassSlider({
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: _primary,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
        thumbColor: _primary,
        overlayColor: _primary.withValues(alpha: 0.15),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        trackHeight: 4,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions ?? (max - min).toInt(),
        onChanged: (v) {
          HapticFeedback.selectionClick();
          onChanged(v);
        },
      ),
    );
  }

  // ─── Glass Text Field ─────────────────────────────────────────────────────

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _primary.withValues(alpha: 0.7),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ─── Gender Option ────────────────────────────────────────────────────────

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _gender = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? _primary.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? _primary.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? _primary : Colors.grey[500],
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? _primary : Colors.grey[500],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
