import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:bouh/authentication/AuthSession.dart';
import 'package:bouh/dto/DrawingAnalysis/AnalysisResultDto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/theme/base_themes/typography.dart';
import 'package:bouh/View/DrawingAnalysis/drawing_analysis_stepper.dart';
import 'package:bouh/View/DrawingAnalysis/AnalysisResultsPage.dart';
import 'package:bouh/services/DrawingAnalysisService.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ProcessingAnalysisPage extends StatefulWidget {
  final File imageFile;
  final String childId;
  final String childName;

  const ProcessingAnalysisPage({
    super.key,
    required this.imageFile,
    required this.childId,
    required this.childName,
  });

  @override
  State<ProcessingAnalysisPage> createState() => _ProcessingAnalysisPageState();
}

class _ProcessingAnalysisPageState extends State<ProcessingAnalysisPage>
    with SingleTickerProviderStateMixin {
  //Progress 0.0–1.0.
  double _progress = 0.0;

  //Status line under the circle.
  String _statusText = 'جاري التحليل...';

  Timer? _timer;
  bool _hasError = false;

  //Wave fill animation.
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  final _analysisService = DrawingAnalysisService();

  //Status messages shown in order while loading.
  static const List<String> _statusMessages = [
    'جاري التحليل...',
    'تحديد الشعور',
    'جاري تحميل إجابات التحليل..',
    'تقريباً جاهز...',
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);
    _runAnalysis();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  // upload → analyze → navigate
  // Progress is split into two phases:
  //   0%  → 50%  : actual upload progress from Firebase Storage
  //   50% → 85%  : slow animation while backend analyzes
  //   85% → 100% : jumps when backend responds
  Future<void> _runAnalysis() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.getIdToken(true); // force token refresh
      }
      // ── Compress before upload ───────────────────────────────────────────
      final File fileToUpload = await _compressImage(widget.imageFile);
      // ── Phase 1: Upload image to Firebase Storage ────────────────────────
      final caregiverId = AuthSession.instance.userId ?? 'unknown';
      final String storagePath =
          'drawings/$caregiverId/${widget.childId}/${const Uuid().v4()}.jpg';

      final ref = FirebaseStorage.instance.ref(storagePath);
      final uploadTask = ref.putFile(
        fileToUpload,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Reflect real upload progress on the wave (0.0 → 0.5)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (!mounted) return;
        final double uploadProgress =
            snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _progress = (uploadProgress * 0.5).clamp(0.0, 0.5);
          _statusText = 'جاري الرفع....';
        });
      });

      await uploadTask;

      final String downloadURL = await ref.getDownloadURL();

      // ── Phase 2: Slow animation while backend runs (0.5 → 0.85) ─────────
      setState(() {
        _progress = 0.5;
        _statusText = 'جاري التحليل...';
      });
      _startSlowProgressFrom(0.5);

      // ── Phase 3: Call the backend analyze endpoint ────────────────────────
      final AnalysisResult result = await _analysisService.analyze(
        imagePath: storagePath,
        imageURL: downloadURL,
        childId: widget.childId,
      );

      if (!mounted) return;

      // Analysis done — fill to 100%
      _timer?.cancel();
      setState(() {
        _progress = 1.0;
        _statusText = 'تقريباً جاهز...';
      });

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => AnalysisResultsPage(
            hideStepper: false,
            emotionalInterpretation: result.emotionalInterpretation,
            doctorIds: result.doctorIds,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[ProcessingAnalysisPage] ERROR: $e');
      if (!mounted) return;
      _timer?.cancel();
      setState(() => _hasError = true);
    }
  }

  // Slowly moves progress from [startFrom] → 0.85 while waiting for backend
  void _startSlowProgressFrom(double startFrom) {
    _timer?.cancel();
    const duration = Duration(milliseconds: 600);
    int step = 0;

    void tick() {
      if (!mounted) return;
      step++;
      final p = (startFrom + (step / 25) * (0.95 - startFrom)).clamp(
        startFrom,
        0.95,
      );
      setState(() {
        _progress = p;
        _statusText =
            _statusMessages[(step ~/ 7).clamp(0, _statusMessages.length - 1)];
      });
      if (p < 0.95) _timer = Timer(duration, tick);
    }

    _timer = Timer(duration, tick);
  }

  // Compresses the image to a target size in KB before uploading.
  // This reduces upload time and makes the backend classification faster.
  // Target: 200 KB max — enough quality for the ConvNeXt model to classify.
  Future<File> _compressImage(File file) async {
    final int originalBytes = await file.length();
    final int originalKb = (originalBytes / 1024).ceil();

    // If already under 200 KB, no compression needed
    if (originalKb <= 200) return file;

    final String targetPath =
        '${file.parent.path}/compressed_${file.uri.pathSegments.last}';

    final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70, // 70% quality — good balance between size and accuracy
      minWidth: 224, // minimum width the ConvNeXt model needs
      minHeight: 224, // minimum height the ConvNeXt model needs
    );

    if (compressed == null)
      return file; // fallback to original if compression fails

    final int compressedKb = (await compressed.length() / 1024).ceil();
    debugPrint('[Compress] $originalKb KB → $compressedKb KB');

    return File(compressed.path);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.lightGrey,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 38),
              const DrawingAnalysisStepper(currentStep: 1),
              Expanded(
                child: Center(
                  child: _hasError
                      ? _buildErrorState()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCircularProgress(),
                            const SizedBox(height: 24),
                            Text(
                              _statusText,
                              style: BTypography.bodyText.copyWith(
                                color: BColors.darkerGrey,
                                fontWeight: FontWeight.w500,
                                fontSize: 24,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: BColors.accent, size: 64),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ أثناء تحليل الرسمة',
            style: BTypography.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى التحقق من الاتصال بالإنترنت والمحاولة مرة أخرى',
            style: BTypography.bodyText.copyWith(color: BColors.darkerGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: BColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: Text('حاول مجدداً', style: BTypography.buttonText),
          ),
        ],
      ),
    );
  }

  //Ocean-style progress with animated wave: inner circle fills from the bottom,
  //top edge is a moving wave. Percentage text is centered on top.
  Widget _buildCircularProgress() {
    const double size = 210;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          //Circle border and background
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromARGB(255, 219, 219, 219),
              border: Border.all(
                color: const Color.fromARGB(167, 255, 132, 75),
                width: 3,
              ),
            ),
          ),

          //Animated wave fill (clipped to circle)
          ClipOval(
            child: AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(size, size),
                  painter: _OceanWavePainter(
                    progress: _progress,
                    wavePhase: _waveAnimation.value,
                    color: BColors.accent,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

//Paints the ocean fill with a wavy top edge
class _OceanWavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color color;

  _OceanWavePainter({
    required this.progress,
    required this.wavePhase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final w = size.width;
    final h = size.height;
    //Fill level from bottom (y increases downward). Flat level would be at y = h * (1 - progress).
    final fillLevel = h * (1 - progress);
    const waveAmplitude = 6.0;
    const waveLength = 0.020; //cycles per pixel (controls the wave shape)
    final phase = wavePhase * 2 * math.pi;

    final path = Path();
    path.moveTo(0, h);
    path.lineTo(0, fillLevel + waveAmplitude * math.sin(phase));
    for (double x = 0; x <= w; x += 2) {
      final y =
          fillLevel +
          waveAmplitude * math.sin(x * waveLength * 2 * math.pi + phase);
      path.lineTo(x, y);
    }
    path.lineTo(w, h);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_OceanWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase;
  }
}
