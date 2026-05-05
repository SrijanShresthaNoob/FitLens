// lib/screens/scan/scan_screen.dart
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../widgets/glass_nav_bar.dart';
import '../../services/gemini_service.dart';
import '../../services/ad_service.dart';
import '../../providers/nutrition_provider.dart';
import '../../models/food_entry.dart';
import '../home/home_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  // Camera
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;

  // State
  File? _capturedImage;
  bool _isAnalyzing = false;
  FoodEntry? _result;
  final _picker = ImagePicker();

  // Screen states
  _ScanState _screenState = _ScanState.camera;

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _scanLineController;
  late AnimationController _cornerController;
  late AnimationController _resultController;
  late AnimationController _macroCardController;
  late AnimationController _captureController;
  late AnimationController _analyzeTextController;

  // Animations
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _scanLineAnim;
  late Animation<double> _cornerAnim;
  late Animation<double> _resultFadeAnim;
  late Animation<Offset> _resultSlideAnim;
  late Animation<double> _captureScaleAnim;
  late List<Animation<double>> _macroCardAnims;

  // Analyzing text
  String _analyzeText = 'Scanning food item...';
  final List<String> _analyzeTexts = [
    'Scanning food item...',
    'Detecting ingredients...',
    'Calculating macros...',
    'Almost done...',
  ];
  int _analyzeTextIndex = 0;

  static const Color _primary = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initCamera();
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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scanLineController,
        curve: Curves.easeInOut,
      ),
    );

    _cornerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cornerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cornerController, curve: Curves.easeOutBack),
    );

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _resultFadeAnim = CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOut,
    );
    _resultSlideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOutCubic,
    ));

    _macroCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _macroCardAnims = List.generate(3, (i) {
      final start = i * 0.15;
      final end = start + 0.6;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _macroCardController,
          curve: Interval(start, end, curve: Curves.easeOutBack),
        ),
      );
    });

    _captureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _captureScaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _captureController, curve: Curves.easeOut),
    );

    _analyzeTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeController.forward();
    _cornerController.forward();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      _cameraController = CameraController(
        _cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _cameraReady = true);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraReady) return;

    HapticFeedback.mediumImpact();
    await _captureController.forward();
    await _captureController.reverse();

    try {
      final xFile = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = File(xFile.path);
        _screenState = _ScanState.analyzing;
      });
      await _analyzeImage();
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked == null) return;
    setState(() {
      _capturedImage = File(picked.path);
      _screenState = _ScanState.analyzing;
    });
    await _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    if (_capturedImage == null) return;
    setState(() => _isAnalyzing = true);

    _startAnalyzeTextCycle();

    try {
      final result = await GeminiService.analyzeFood(_capturedImage!);
      setState(() {
        _result = result;
        _isAnalyzing = false;
        _screenState = _ScanState.result;
      });

      _resultController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _macroCardController.forward();

      AdService.showInterstitial();
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _screenState = _ScanState.camera;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startAnalyzeTextCycle() async {
    while (_isAnalyzing && mounted) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!_isAnalyzing || !mounted) break;

      await _analyzeTextController.forward();
      setState(() {
        _analyzeTextIndex = (_analyzeTextIndex + 1) % _analyzeTexts.length;
        _analyzeText = _analyzeTexts[_analyzeTextIndex];
      });
      _analyzeTextController.reset();
    }
  }

  Future<void> _logFood() async {
    if (_result == null) return;
    HapticFeedback.lightImpact();

    await context.read<NutritionProvider>().addEntry(_result!);

    if (mounted) {
      // Navigate to home instead of pop to avoid black screen
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
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );

      // Show snackbar after navigation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                  const SizedBox(width: 10),
                  Text(
                    'Food logged!',
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
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _scanLineController.dispose();
    _cornerController.dispose();
    _resultController.dispose();
    _macroCardController.dispose();
    _captureController.dispose();
    _analyzeTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background layer ────────────────────────────────
            _buildBackground(),

            // ── Scan overlay ────────────────────────────────────
            if (_screenState == _ScanState.camera) _buildScanOverlay(),

            // ── Top bar ─────────────────────────────────────────
            _buildTopBar(),

            // ── Macro cards ─────────────────────────────────────
            if (_screenState == _ScanState.result && _result != null)
              _buildFloatingMacroCards(),

            // ── Analyzing overlay ────────────────────────────────
            if (_screenState == _ScanState.analyzing) _buildAnalyzingOverlay(),

            // ── Camera controls ──────────────────────────────────
            if (_screenState == _ScanState.camera) _buildCameraControls(),

            // ── Result panel ─────────────────────────────────────
            if (_screenState == _ScanState.result && _result != null)
              _buildResultPanel(),

            // ── Shared Glass Nav Bar ──────────────────────────────
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GlassNavBar(currentTab: NavTab.scan),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Background ─────────────────────────────────────────────────────────

  Widget _buildBackground() {
    if (_capturedImage != null) {
      return Image.file(
        _capturedImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (_cameraReady && _cameraController != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController!.value.previewSize!.height,
            height: _cameraController!.value.previewSize!.width,
            child: CameraPreview(_cameraController!),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF0A0A0F),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: _primary),
            const SizedBox(height: 20),
            Text(
              'Please scan a food item',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Scan Overlay ───────────────────────────────────────────────────────

  Widget _buildScanOverlay() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.85,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.45),
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _cornerAnim,
          builder: (context, _) {
            return Center(
              child: Transform.scale(
                scale: _cornerAnim.value,
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: CustomPaint(
                    painter: _CornerBracketPainter(
                      color: _primary,
                      opacity: _cornerAnim.value,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _scanLineAnim,
          builder: (context, _) {
            final size = MediaQuery.of(context).size;
            final top =
                size.height * 0.3 + (size.height * 0.4 * _scanLineAnim.value);
            return Positioned(
              top: top,
              left: size.width * 0.15,
              right: size.width * 0.15,
              child: Opacity(
                opacity: (0.8 - (_scanLineAnim.value - 0.5).abs() * 1.2)
                    .clamp(0.0, 0.8),
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _primary.withValues(alpha: 0.8),
                        _primary,
                        _primary.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, _) => Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary,
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: _pulseAnim.value * 0.8),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Top Bar ────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ✅ PASTE THE FULL BACK BUTTON HERE
                GestureDetector(
                  onTap: () {
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
                        transitionDuration: const Duration(milliseconds: 350),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
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

                // Title pill stays here...
                // Retake button stays here...
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Floating Macro Cards ────────────────────────────────────────────────

  Widget _buildFloatingMacroCards() {
    if (_result == null) return const SizedBox();

    final macros = [
      {
        'label': 'PROTEIN',
        'value': '${_result!.protein.toInt()}g',
        'color': const Color(0xFF10B981),
      },
      {
        'label': 'CARBS',
        'value': '${_result!.carbs.toInt()}g',
        'color': const Color(0xFFF59E0B),
      },
      {
        'label': 'FAT',
        'value': '${_result!.fat.toInt()}g',
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      right: 16,
      child: Row(
        children: List.generate(3, (i) {
          final macro = macros[i];
          return Expanded(
            child: AnimatedBuilder(
              animation: _macroCardAnims[i],
              builder: (context, child) {
                return Transform.scale(
                  scale: _macroCardAnims[i].value,
                  child: Opacity(
                    opacity: _macroCardAnims[i].value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.only(
                  left: i == 0 ? 0 : 6,
                  right: i == 2 ? 0 : 6,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.18),
                            Colors.white.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            macro['label'] as String,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            macro['value'] as String,
                            style: GoogleFonts.poppins(
                              color: macro['color'] as Color,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Analyzing Overlay ───────────────────────────────────────────────────

  Widget _buildAnalyzingOverlay() {
    return Positioned(
      bottom: 160,
      left: 40,
      right: 40,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _primary.withValues(alpha: _pulseAnim.value * 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha: _pulseAnim.value * 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: _primary,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _analyzeText,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Camera Controls ─────────────────────────────────────────────────────

  Widget _buildCameraControls() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _pickFromGallery,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _capturePhoto,
            child: AnimatedBuilder(
              animation: Listenable.merge([_captureScaleAnim, _pulseAnim]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _captureScaleAnim.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(
                              alpha: _pulseAnim.value * 0.5),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF10B981),
                        Color(0xFF059669),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.center_focus_strong_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }

  // ─── Result Panel ────────────────────────────────────────────────────────

  Widget _buildResultPanel() {
    if (_result == null) return const SizedBox();

    return Positioned(
      bottom: 90,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _resultSlideAnim,
        child: FadeTransition(
          opacity: _resultFadeAnim,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _result!.emoji ?? '🍽️',
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _result!.name,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_result!.calories.toInt()} kcal',
                                style: GoogleFonts.poppins(
                                  color: _primary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildResultMacro(
                          'Protein',
                          '${_result!.protein.toInt()}g',
                          const Color(0xFF10B981),
                        ),
                        _buildMacroDivider(),
                        _buildResultMacro(
                          'Carbs',
                          '${_result!.carbs.toInt()}g',
                          const Color(0xFFF59E0B),
                        ),
                        _buildMacroDivider(),
                        _buildResultMacro(
                          'Fat',
                          '${_result!.fat.toInt()}g',
                          const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _logFood,
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: double.infinity,
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _primary.withValues(alpha: 0.9),
                                      const Color(0xFF059669)
                                          .withValues(alpha: 0.9),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primary.withValues(
                                        alpha: _pulseAnim.value * 0.4,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Done — Log Food',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildResultMacro(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroDivider() => Container(
        width: 1,
        height: 36,
        color: Colors.white.withValues(alpha: 0.15),
      );
} // ← END OF _ScanScreenState

// ─── Screen State Enum ───────────────────────────────────────────────────────

enum _ScanState { camera, analyzing, result }

// ─── Corner Bracket Painter ──────────────────────────────────────────────────

class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double opacity;

  _CornerBracketPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity * 0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const len = 28.0;
    const r = 8.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
        ..lineTo(len, 0),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width - r, 0)
        ..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))
        ..lineTo(size.width, len),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - len)
        ..lineTo(0, size.height - r)
        ..arcToPoint(Offset(r, size.height),
            radius: const Radius.circular(r), clockwise: false)
        ..lineTo(len, size.height),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, size.height)
        ..lineTo(size.width - r, size.height)
        ..arcToPoint(Offset(size.width, size.height - r),
            radius: const Radius.circular(r), clockwise: false)
        ..lineTo(size.width, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerBracketPainter old) =>
      old.opacity != opacity || old.color != color;
}
