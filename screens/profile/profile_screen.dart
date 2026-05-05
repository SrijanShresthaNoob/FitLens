// lib/screens/profile/profile_screen.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  UserProfile? _profile;

  // Controllers — matched to your exact model fields
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController; // heightCm
  late TextEditingController _weightController; // weightKg
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  // Dropdowns — matched to your model
  String _selectedGender = 'Male';
  String _selectedGoal = 'Maintain';
  String _selectedActivityLevel = 'Moderate';
  bool _isSaving = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  final List<String> _goals = [
    'Lose Weight',
    'Maintain',
    'Gain Muscle',
    'Bulk',
  ];

  final List<String> _activityLevels = [
    'Sedentary',
    'Light',
    'Moderate',
    'Active',
    'Very Active',
  ];

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _cardController;
  late AnimationController _avatarController;

  // Animations
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _avatarScaleAnim;
  late List<Animation<Offset>> _cardSlideAnims;
  late List<Animation<double>> _cardFadeAnims;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _setupAnimations();
    _loadProfile();
    _startAnimations();
  }

  void _initControllers() {
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _avatarScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _avatarController,
        curve: Curves.elasticOut,
      ),
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // 7 cards total
    _cardSlideAnims = List.generate(7, (i) {
      final start = (i * 0.12).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.4),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _cardController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));
    });

    _cardFadeAnims = List.generate(7, (i) {
      final start = (i * 0.12).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _cardController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ));
    });
  }

  void _startAnimations() async {
    _fadeController.forward();
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _avatarController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _cardController.forward();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('userProfile');
    if (raw != null) {
      final profile = UserProfile.fromJson(jsonDecode(raw));
      setState(() {
        _profile = profile;
        // Map to your exact field names
        _nameController.text = profile.name;
        _ageController.text = profile.age.toString();
        _heightController.text = profile.heightCm.toString(); // heightCm
        _weightController.text = profile.weightKg.toString(); // weightKg
        _caloriesController.text = profile.dailyCalories.toString();
        _proteinController.text = profile.proteinTarget.toString();
        _carbsController.text = profile.carbsTarget.toString();
        _fatController.text = profile.fatTarget.toString();
        _selectedGender = profile.gender;
        _selectedGoal = profile.goal;
        _selectedActivityLevel = profile.activityLevel; // activityLevel
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    // Build updated profile using your exact model constructor
    final updated = UserProfile(
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text) ?? _profile?.age ?? 25,
      gender: _selectedGender,
      heightCm: double.tryParse(_heightController.text) ??
          _profile?.heightCm ??
          170, // heightCm
      weightKg: double.tryParse(_weightController.text) ??
          _profile?.weightKg ??
          70, // weightKg
      activityLevel: _selectedActivityLevel, // activityLevel
      goal: _selectedGoal,
      dailyCalories: double.tryParse(_caloriesController.text) ??
          _profile?.dailyCalories ??
          2000,
      proteinTarget: double.tryParse(_proteinController.text) ??
          _profile?.proteinTarget ??
          150,
      carbsTarget: double.tryParse(_carbsController.text) ??
          _profile?.carbsTarget ??
          200,
      fatTarget:
          double.tryParse(_fatController.text) ?? _profile?.fatTarget ?? 65,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userProfile', jsonEncode(updated.toJson()));

    setState(() {
      _profile = updated;
      _isSaving = false;
    });

    if (mounted) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981)),
              const SizedBox(width: 10),
              Text(
                'Profile saved!',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF111118),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  Future<void> _forgetMe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => _buildForgetMeDialog(),
    );

    if (confirmed == true) {
      HapticFeedback.heavyImpact();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final box = await Hive.openBox('food_entries');
      await box.clear();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _cardController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 110, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar + Name ──────────────────────────────────────
              _buildAvatarSection(),
              const SizedBox(height: 32),

              // ── Identity & Metrics ─────────────────────────────────
              _buildAnimatedCard(
                index: 0,
                child: _buildGlassCard(
                  title: 'Identity & Metrics',
                  icon: Icons.person_outline_rounded,
                  child: _buildIdentityFields(),
                ),
              ),
              const SizedBox(height: 16),

              // ── Activity Level ─────────────────────────────────────
              _buildAnimatedCard(
                index: 1,
                child: _buildGlassCard(
                  title: 'Activity Level',
                  icon: Icons.directions_run_rounded,
                  child: _buildActivitySelector(),
                ),
              ),
              const SizedBox(height: 16),

              // ── Goal ───────────────────────────────────────────────
              _buildAnimatedCard(
                index: 2,
                child: _buildGlassCard(
                  title: 'Goal',
                  icon: Icons.flag_rounded,
                  child: _buildGoalSelector(),
                ),
              ),
              const SizedBox(height: 16),

              // ── Daily Targets ──────────────────────────────────────
              _buildAnimatedCard(
                index: 3,
                child: _buildGlassCard(
                  title: 'Daily Targets',
                  icon: Icons.track_changes_rounded,
                  child: _buildTargetFields(),
                ),
              ),
              const SizedBox(height: 28),

              // ── Save Button ────────────────────────────────────────
              _buildAnimatedCard(
                index: 4,
                child: _buildSaveButton(),
              ),
              const SizedBox(height: 48),

              // ── Divider ────────────────────────────────────────────
              _buildAnimatedCard(
                index: 5,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // ── Forget Me ──────────────────────────────────────────
              _buildAnimatedCard(
                index: 6,
                child: _buildForgetMeButton(),
              ),
              const SizedBox(height: 12),

              Center(
                child: Text(
                  'Permanently deletes all your food history\nand resets the app. This is irreversible.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Glass AppBar ─────────────────────────────────────────────────────────

  PreferredSizeWidget _buildGlassAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
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
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      // Back button with glass effect
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Profile',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
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

  // ─── Avatar Section ───────────────────────────────────────────────────────

  Widget _buildAvatarSection() {
    final initial = (_profile?.name ?? 'U').substring(0, 1).toUpperCase();

    return Center(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_avatarScaleAnim, _pulseAnim]),
            builder: (context, child) {
              return Transform.scale(
                scale: _avatarScaleAnim.value,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(
                          alpha: _pulseAnim.value * 0.4,
                        ),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
            },
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.3),
                    const Color(0xFF0D3D2E),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF10B981),
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            _profile?.name ?? 'User',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          // Shows goal + activity level under name
          Text(
            '$_selectedGoal  ·  $_selectedActivityLevel',
            style: TextStyle(
              color: const Color(0xFF10B981).withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Glass Card Wrapper ───────────────────────────────────────────────────

  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.07),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Identity Fields — uses heightCm + weightKg ───────────────────────────

  Widget _buildIdentityFields() {
    return Column(
      children: [
        _buildField(
          'FULL NAME',
          _nameController,
          hint: 'Your name',
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildField(
                'AGE',
                _ageController,
                hint: '25',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildGenderDropdown()),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildField(
                'HEIGHT (CM)',
                _heightController, // → heightCm
                hint: '170',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                'WEIGHT (KG)',
                _weightController, // → weightKg
                hint: '70',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Activity Level Selector ──────────────────────────────────────────────

  Widget _buildActivitySelector() {
    return Column(
      children: _activityLevels.map((level) {
        final isSelected = _selectedActivityLevel == level;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedActivityLevel = level);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF10B981).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : Colors.grey[700]!,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  level,
                  style: GoogleFonts.poppins(
                    color:
                        isSelected ? const Color(0xFF10B981) : Colors.grey[400],
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF10B981),
                    size: 18,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Goal Selector ────────────────────────────────────────────────────────

  Widget _buildGoalSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _goals.map((goal) {
        final isSelected = _selectedGoal == goal;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedGoal = goal);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF10B981).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Text(
              goal,
              style: GoogleFonts.poppins(
                color: isSelected ? const Color(0xFF10B981) : Colors.grey[400],
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Daily Target Fields ──────────────────────────────────────────────────

  Widget _buildTargetFields() {
    return Column(
      children: [
        _buildField(
          'DAILY CALORIES (KCAL)',
          _caloriesController,
          hint: '2000',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildField(
                'PROTEIN (G)',
                _proteinController,
                hint: '150',
                keyboardType: TextInputType.number,
                accentColor: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                'CARBS (G)',
                _carbsController,
                hint: '200',
                keyboardType: TextInputType.number,
                accentColor: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildField(
          'FAT (G)',
          _fatController,
          hint: '65',
          keyboardType: TextInputType.number,
          accentColor: const Color(0xFF3B82F6),
        ),
      ],
    );
  }

  // ─── Gender Dropdown ──────────────────────────────────────────────────────

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GENDER',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              isExpanded: true,
              dropdownColor: const Color(0xFF111118),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white54,
              ),
              items: _genders
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedGender = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── Reusable Text Field ──────────────────────────────────────────────────

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
    Color accentColor = const Color(0xFF10B981),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[700]),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
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
                color: accentColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Save Button ──────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveProfile,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Save Changes',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── Forget Me Button ─────────────────────────────────────────────────────

  Widget _buildForgetMeButton() {
    return GestureDetector(
      onTap: _forgetMe,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.withValues(alpha: 0.18),
                  Colors.red.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_forever_rounded,
                      color: Colors.red[400], size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'FORGET ME',
                    style: GoogleFonts.poppins(
                      color: Colors.red[400],
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 1.5,
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

  // ─── Forget Me Dialog ─────────────────────────────────────────────────────

  Widget _buildForgetMeDialog() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: 0.15),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Center(
                      child: Text('⚠️', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Forget Me?',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This will permanently delete all your food history and reset the app to brand new. This cannot be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      // Cancel
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, false),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Delete
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, true),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.withValues(alpha: 0.8),
                                  Colors.red.withValues(alpha: 0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Delete All',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Animated Card Wrapper ────────────────────────────────────────────────

  Widget _buildAnimatedCard({required int index, required Widget child}) {
    final safeIndex = index.clamp(0, _cardSlideAnims.length - 1);
    return SlideTransition(
      position: _cardSlideAnims[safeIndex],
      child: FadeTransition(
        opacity: _cardFadeAnims[safeIndex],
        child: child,
      ),
    );
  }
}
