import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Asset map — exercise name keywords → asset path
// Images are sourced from wger.de (open-source exercise database, CC-BY-SA).
// ---------------------------------------------------------------------------
const _exerciseAssets = <String, String>{
  'bench_press': 'assets/exercises/bench_press.png',
  'squat': 'assets/exercises/squat.jpeg',
  'barbell_row': 'assets/exercises/barbell_row.png',
  'bent_over_row': 'assets/exercises/barbell_row.png',
  'lat_pulldown': 'assets/exercises/lat_pulldown.png',
  'overhead_press': 'assets/exercises/overhead_press.png',
  'shoulder_press': 'assets/exercises/shoulder_press.png',
  'bicep_curl': 'assets/exercises/bicep_curl.png',
  'deadlift': 'assets/exercises/deadlift.jpeg',
  'romanian_deadlift': 'assets/exercises/romanian_deadlift.png',
  'tricep_extension': 'assets/exercises/tricep_extension.png',
  'pull_up': 'assets/exercises/pull_up.jpg',
  'lunge': 'assets/exercises/lunge.png',
  'push_up': 'assets/exercises/push_up.png',
};

/// Maps an exercise name string to a downloaded asset path (or null if unknown).
String? _assetPathFor(String exerciseName) {
  final lower = exerciseName.toLowerCase();

  if (lower.contains('bench')) return _exerciseAssets['bench_press'];
  if (lower.contains('romanian') || lower.contains('rdl')) {
    return _exerciseAssets['romanian_deadlift'];
  }
  if (lower.contains('deadlift')) return _exerciseAssets['deadlift'];
  if (lower.contains('squat')) return _exerciseAssets['squat'];
  if (lower.contains('barbell row') ||
      lower.contains('bent over row') ||
      lower.contains('bent-over row')) {
    return _exerciseAssets['barbell_row'];
  }
  if (lower.contains('lat pulldown') || lower.contains('lat pull')) {
    return _exerciseAssets['lat_pulldown'];
  }
  if (lower.contains('pull up') ||
      lower.contains('pull-up') ||
      lower.contains('pullup') ||
      lower.contains('chin up') ||
      lower.contains('chin-up')) {
    return _exerciseAssets['pull_up'];
  }
  if (lower.contains('overhead') ||
      lower.contains('military press') ||
      lower.contains('ohp')) {
    return _exerciseAssets['overhead_press'];
  }
  if (lower.contains('shoulder press')) {
    return _exerciseAssets['shoulder_press'];
  }
  if (lower.contains('bicep') || lower.contains('curl')) {
    return _exerciseAssets['bicep_curl'];
  }
  if (lower.contains('tricep')) return _exerciseAssets['tricep_extension'];
  if (lower.contains('lunge')) return _exerciseAssets['lunge'];
  if (lower.contains('push up') ||
      lower.contains('push-up') ||
      lower.contains('pushup')) {
    return _exerciseAssets['push_up'];
  }
  if (lower.contains('row') || lower.contains('pull')) {
    return _exerciseAssets['barbell_row'];
  }
  if (lower.contains('press') && lower.contains('chest')) {
    return _exerciseAssets['bench_press'];
  }
  if (lower.contains('press')) return _exerciseAssets['shoulder_press'];
  return null;
}

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------

/// Shows a real exercise illustration (when available) or an animated
/// canvas diagram as a fallback.
class ExerciseDemonstrationWidget extends StatefulWidget {
  const ExerciseDemonstrationWidget({
    super.key,
    required this.exerciseName,
    this.muscleId,
    this.compact = false,
    this.autoPlay = true,
  });

  final String exerciseName;
  final String? muscleId;
  final bool compact;
  final bool autoPlay;

  @override
  State<ExerciseDemonstrationWidget> createState() =>
      _ExerciseDemonstrationWidgetState();
}

class _ExerciseDemonstrationWidgetState
    extends State<ExerciseDemonstrationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest && widget.autoPlay) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _controller.stop();
        _isPlaying = false;
      } else {
        _controller.repeat(reverse: true);
        _isPlaying = true;
      }
    });
  }

  ({String primaryTarget, String cue, _ExerciseType type}) _getExerciseMeta() {
    final lower = widget.exerciseName.toLowerCase();
    if (lower.contains('bench') ||
        lower.contains('press') && lower.contains('chest')) {
      return (
        primaryTarget: 'Chest, Front Deltoids, Triceps',
        cue: 'Retract scapula, lower bar to mid-chest, press upward explosively.',
        type: _ExerciseType.benchPress,
      );
    } else if (lower.contains('squat')) {
      return (
        primaryTarget: 'Quadriceps, Glutes, Hamstrings',
        cue: 'Keep chest high, brace core, break parallel, drive through mid-foot.',
        type: _ExerciseType.squat,
      );
    } else if (lower.contains('row') || lower.contains('pull')) {
      return (
        primaryTarget: 'Latissimus Dorsi, Rhomboids, Biceps',
        cue: 'Hinge at hips, pull elbows toward hips, squeeze shoulder blades.',
        type: _ExerciseType.row,
      );
    } else if (lower.contains('shoulder') ||
        lower.contains('overhead') ||
        lower.contains('military')) {
      return (
        primaryTarget: 'Deltoids, Upper Trapezius, Triceps',
        cue: 'Press straight overhead, lock out elbows without arching lower back.',
        type: _ExerciseType.overheadPress,
      );
    } else if (lower.contains('curl') || lower.contains('bicep')) {
      return (
        primaryTarget: 'Biceps Brachii, Forearms',
        cue: 'Keep elbows tucked at sides, curl without swinging, control eccentric.',
        type: _ExerciseType.curl,
      );
    } else if (lower.contains('deadlift')) {
      return (
        primaryTarget: 'Hamstrings, Glutes, Lower Back',
        cue: 'Push floor away, keep bar close to shins, stand tall with glute lock.',
        type: _ExerciseType.deadlift,
      );
    } else {
      return (
        primaryTarget: widget.muscleId != null
            ? '${widget.muscleId![0].toUpperCase()}${widget.muscleId!.substring(1)} Focus'
            : 'Target Muscle Group',
        cue: 'Maintain steady tempo, focus on mind-muscle connection and full range of motion.',
        type: _ExerciseType.generic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final meta = _getExerciseMeta();
    final assetPath = _assetPathFor(widget.exerciseName);

    if (widget.compact) {
      return _CompactDemonstration(
        exerciseName: widget.exerciseName,
        assetPath: assetPath,
        controller: _controller,
        meta: meta,
        colorScheme: colorScheme,
      );
    }

    return _FullDemonstration(
      exerciseName: widget.exerciseName,
      assetPath: assetPath,
      controller: _controller,
      meta: meta,
      colorScheme: colorScheme,
      isPlaying: _isPlaying,
      onTogglePlayPause: _togglePlayPause,
    );
  }
}

// ---------------------------------------------------------------------------
// Compact view
// ---------------------------------------------------------------------------

class _CompactDemonstration extends StatelessWidget {
  const _CompactDemonstration({
    required this.exerciseName,
    required this.assetPath,
    required this.controller,
    required this.meta,
    required this.colorScheme,
  });

  final String exerciseName;
  final String? assetPath;
  final AnimationController controller;
  final ({String primaryTarget, String cue, _ExerciseType type}) meta;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(140),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (assetPath != null)
            Image.asset(
              assetPath!,
              fit: BoxFit.cover,
              errorBuilder: (context, e, s) => _FallbackCanvas(
                controller: controller,
                type: meta.type,
                colorScheme: colorScheme,
                height: 120,
              ),
            )
          else
            _FallbackCanvas(
              controller: controller,
              type: meta.type,
              colorScheme: colorScheme,
              height: 120,
            ),
          // Gradient overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colorScheme.surface.withAlpha(180),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 8,
            child: Row(
              children: [
                Icon(
                  Icons.slow_motion_video,
                  size: 14,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Exercise Guide',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full view
// ---------------------------------------------------------------------------

class _FullDemonstration extends StatelessWidget {
  const _FullDemonstration({
    required this.exerciseName,
    required this.assetPath,
    required this.controller,
    required this.meta,
    required this.colorScheme,
    required this.isPlaying,
    required this.onTogglePlayPause,
  });

  final String exerciseName;
  final String? assetPath;
  final AnimationController controller;
  final ({String primaryTarget, String cue, _ExerciseType type}) meta;
  final ColorScheme colorScheme;
  final bool isPlaying;
  final VoidCallback onTogglePlayPause;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(128)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fitness_center_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      assetPath != null
                          ? 'Exercise Illustration'
                          : 'Motion Demonstration',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Play/pause only relevant for the canvas fallback
                if (assetPath == null)
                  IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                    tooltip: isPlaying
                        ? 'Pause demonstration'
                        : 'Play demonstration',
                    onPressed: onTogglePlayPause,
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Image / canvas area
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 200,
                color: colorScheme.surfaceContainerHighest.withAlpha(100),
                child: assetPath != null
                    ? _RealImage(
                        assetPath: assetPath!,
                        colorScheme: colorScheme,
                        fallbackType: meta.type,
                        controller: controller,
                      )
                    : _FallbackCanvas(
                        controller: controller,
                        type: meta.type,
                        colorScheme: colorScheme,
                        height: 200,
                      ),
              ),
            ),
            const SizedBox(height: 4),

            // Attribution when real image shown
            if (assetPath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Illustration: wger.de — Open Exercise Database (CC BY-SA)',
                  style: TextStyle(
                    fontSize: 9,
                    color: colorScheme.onSurfaceVariant.withAlpha(140),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

            const SizedBox(height: 4),

            // Coaching cue box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(120),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.track_changes,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          meta.primaryTarget,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta.cue,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onPrimaryContainer.withAlpha(220),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Real image widget with graceful error fallback
// ---------------------------------------------------------------------------

class _RealImage extends StatelessWidget {
  const _RealImage({
    required this.assetPath,
    required this.colorScheme,
    required this.fallbackType,
    required this.controller,
  });

  final String assetPath;
  final ColorScheme colorScheme;
  final _ExerciseType fallbackType;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _FallbackCanvas(
          controller: controller,
          type: fallbackType,
          colorScheme: colorScheme,
          height: 200,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Canvas fallback (original animated stick-figure drawing)
// ---------------------------------------------------------------------------

class _FallbackCanvas extends StatelessWidget {
  const _FallbackCanvas({
    required this.controller,
    required this.type,
    required this.colorScheme,
    required this.height,
  });

  final AnimationController controller;
  final _ExerciseType type;
  final ColorScheme colorScheme;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(double.infinity, height),
          painter: _ExerciseMotionPainter(
            progress: controller.value,
            type: type,
            primaryColor: colorScheme.primary,
            accentColor: const Color(0xFFFF9100),
            surfaceColor: colorScheme.surface,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Enum + Painter (unchanged from before)
// ---------------------------------------------------------------------------

enum _ExerciseType {
  benchPress,
  squat,
  row,
  overheadPress,
  curl,
  deadlift,
  generic,
}

class _ExerciseMotionPainter extends CustomPainter {
  _ExerciseMotionPainter({
    required this.progress,
    required this.type,
    required this.primaryColor,
    required this.accentColor,
    required this.surfaceColor,
  });

  final double progress; // 0.0 to 1.0
  final _ExerciseType type;
  final Color primaryColor;
  final Color accentColor;
  final Color surfaceColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Background glow
    final glowPaint = Paint()
      ..color = primaryColor.withAlpha(20)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 60, glowPaint);

    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final weightPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;

    switch (type) {
      case _ExerciseType.benchPress:
        _drawBenchPress(canvas, cx, cy, linePaint, accentPaint, weightPaint);
      case _ExerciseType.squat:
        _drawSquat(canvas, cx, cy, linePaint, accentPaint, weightPaint);
      case _ExerciseType.row:
        _drawRow(canvas, cx, cy, linePaint, accentPaint, weightPaint);
      case _ExerciseType.overheadPress:
        _drawOverheadPress(canvas, cx, cy, linePaint, accentPaint, weightPaint);
      case _ExerciseType.curl:
        _drawCurl(canvas, cx, cy, linePaint, accentPaint, weightPaint);
      case _ExerciseType.deadlift:
      case _ExerciseType.generic:
        _drawGeneric(canvas, cx, cy, linePaint, accentPaint, weightPaint);
    }
  }

  void _drawBenchPress(
    Canvas canvas,
    double cx,
    double cy,
    Paint bodyPaint,
    Paint activePaint,
    Paint barPaint,
  ) {
    // Bench table
    canvas.drawLine(
      Offset(cx - 50, cy + 30),
      Offset(cx + 50, cy + 30),
      Paint()
        ..color = Colors.grey.withAlpha(120)
        ..strokeWidth = 4,
    );
    canvas.drawLine(
      Offset(cx - 35, cy + 30),
      Offset(cx - 35, cy + 50),
      Paint()
        ..color = Colors.grey.withAlpha(120)
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(cx + 35, cy + 30),
      Offset(cx + 35, cy + 50),
      Paint()
        ..color = Colors.grey.withAlpha(120)
        ..strokeWidth = 3,
    );

    // Torso
    canvas.drawCircle(Offset(cx - 35, cy + 20), 8, bodyPaint);
    canvas.drawLine(
      Offset(cx - 25, cy + 25),
      Offset(cx + 25, cy + 25),
      activePaint,
    );

    // Barbell (0 = top extended, 1 = lowered to chest)
    final barY = cy - 25 + (progress * 40);

    canvas.drawLine(
      Offset(cx - 5, cy + 25),
      Offset(cx - 10, barY + 5),
      bodyPaint,
    );
    canvas.drawLine(
      Offset(cx + 10, cy + 25),
      Offset(cx + 5, barY + 5),
      bodyPaint,
    );

    canvas.drawLine(
      Offset(cx - 45, barY),
      Offset(cx + 45, barY),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 40, barY), width: 8, height: 26),
        const Radius.circular(2),
      ),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 40, barY), width: 8, height: 26),
        const Radius.circular(2),
      ),
      barPaint,
    );
  }

  void _drawSquat(
    Canvas canvas,
    double cx,
    double cy,
    Paint bodyPaint,
    Paint activePaint,
    Paint barPaint,
  ) {
    final dip = progress * 35;
    final headY = cy - 40 + dip;
    final hipY = cy - 10 + dip;
    final kneeY = cy + 15 + (dip * 0.4);
    final footY = cy + 45;

    canvas.drawCircle(Offset(cx, headY), 8, bodyPaint);
    canvas.drawLine(Offset(cx, headY + 8), Offset(cx, hipY), bodyPaint);
    canvas.drawLine(
      Offset(cx, hipY),
      Offset(cx - 15 - (progress * 10), kneeY),
      activePaint,
    );
    canvas.drawLine(
      Offset(cx, hipY),
      Offset(cx + 15 + (progress * 10), kneeY),
      activePaint,
    );
    canvas.drawLine(
      Offset(cx - 15 - (progress * 10), kneeY),
      Offset(cx - 20, footY),
      bodyPaint,
    );
    canvas.drawLine(
      Offset(cx + 15 + (progress * 10), kneeY),
      Offset(cx + 20, footY),
      bodyPaint,
    );

    final barY = headY + 6;
    canvas.drawLine(
      Offset(cx - 45, barY),
      Offset(cx + 45, barY),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 40, barY), width: 8, height: 26),
        const Radius.circular(2),
      ),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 40, barY), width: 8, height: 26),
        const Radius.circular(2),
      ),
      barPaint,
    );
  }

  void _drawOverheadPress(
    Canvas canvas,
    double cx,
    double cy,
    Paint bodyPaint,
    Paint activePaint,
    Paint barPaint,
  ) {
    final headY = cy - 15;
    final barY = cy - 50 + (progress * 42);

    canvas.drawCircle(Offset(cx, headY), 8, bodyPaint);
    canvas.drawLine(Offset(cx, headY + 8), Offset(cx, cy + 25), bodyPaint);
    canvas.drawLine(Offset(cx, cy + 25), Offset(cx - 15, cy + 55), bodyPaint);
    canvas.drawLine(Offset(cx, cy + 25), Offset(cx + 15, cy + 55), bodyPaint);
    canvas.drawLine(
      Offset(cx - 16, headY + 12),
      Offset(cx + 16, headY + 12),
      activePaint,
    );
    canvas.drawLine(
      Offset(cx - 16, headY + 12),
      Offset(cx - 25, barY),
      bodyPaint,
    );
    canvas.drawLine(
      Offset(cx + 16, headY + 12),
      Offset(cx + 25, barY),
      bodyPaint,
    );

    canvas.drawLine(
      Offset(cx - 45, barY),
      Offset(cx + 45, barY),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 40, barY), width: 8, height: 24),
        const Radius.circular(2),
      ),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 40, barY), width: 8, height: 24),
        const Radius.circular(2),
      ),
      barPaint,
    );
  }

  void _drawCurl(
    Canvas canvas,
    double cx,
    double cy,
    Paint bodyPaint,
    Paint activePaint,
    Paint barPaint,
  ) {
    final headY = cy - 35;
    canvas.drawCircle(Offset(cx, headY), 8, bodyPaint);
    canvas.drawLine(Offset(cx, headY + 8), Offset(cx, cy + 15), bodyPaint);
    canvas.drawLine(Offset(cx, cy + 15), Offset(cx - 12, cy + 50), bodyPaint);
    canvas.drawLine(Offset(cx, cy + 15), Offset(cx + 12, cy + 50), bodyPaint);

    final elbowY = cy - 5;
    final handY = cy - 20 + (progress * 30);
    final handX = cx + 20 - (progress * 5);

    canvas.drawLine(
      Offset(cx + 8, headY + 12),
      Offset(cx + 12, elbowY),
      activePaint,
    );
    canvas.drawLine(Offset(cx + 12, elbowY), Offset(handX, handY), bodyPaint);
    canvas.drawCircle(Offset(handX, handY), 7, barPaint);
  }

  void _drawRow(
    Canvas canvas,
    double cx,
    double cy,
    Paint bodyPaint,
    Paint activePaint,
    Paint barPaint,
  ) {
    final barY = cy + (progress * 25);

    canvas.drawCircle(Offset(cx - 25, cy - 25), 8, bodyPaint);
    canvas.drawLine(Offset(cx - 20, cy - 20), Offset(cx + 15, cy), activePaint);
    canvas.drawLine(Offset(cx + 15, cy), Offset(cx + 25, cy + 45), bodyPaint);
    canvas.drawLine(Offset(cx - 5, cy - 10), Offset(cx - 5, barY), bodyPaint);

    canvas.drawLine(
      Offset(cx - 35, barY),
      Offset(cx + 25, barY),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 30, barY), width: 8, height: 22),
        const Radius.circular(2),
      ),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 20, barY), width: 8, height: 22),
        const Radius.circular(2),
      ),
      barPaint,
    );
  }

  void _drawGeneric(
    Canvas canvas,
    double cx,
    double cy,
    Paint bodyPaint,
    Paint activePaint,
    Paint barPaint,
  ) {
    final wave = math.sin(progress * math.pi * 2);
    canvas.drawCircle(Offset(cx, cy - 30 + wave * 5), 8, bodyPaint);
    canvas.drawLine(
      Offset(cx, cy - 22 + wave * 5),
      Offset(cx, cy + 15),
      activePaint,
    );
    canvas.drawLine(Offset(cx, cy + 15), Offset(cx - 15, cy + 50), bodyPaint);
    canvas.drawLine(Offset(cx, cy + 15), Offset(cx + 15, cy + 50), bodyPaint);
    canvas.drawLine(
      Offset(cx - 40, cy - 10 - wave * 15),
      Offset(cx + 40, cy - 10 - wave * 15),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ExerciseMotionPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.type != type;
  }
}
