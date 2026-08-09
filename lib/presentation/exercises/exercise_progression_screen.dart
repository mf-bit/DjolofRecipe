import 'package:flutter/material.dart';

import '../../data/repositories/gym_repository.dart';

import '../../domain/domain.dart';
import '../widgets/exercise_demonstration.dart';
import '../widgets/progression_chart.dart';

class ExerciseProgressionScreen extends StatefulWidget {
  const ExerciseProgressionScreen({
    super.key,
    required this.exercise,
    required this.repository,
  });

  final Exercise exercise;
  final GymRepository repository;

  @override
  State<ExerciseProgressionScreen> createState() =>
      _ExerciseProgressionScreenState();
}

class _ExerciseProgressionScreenState extends State<ExerciseProgressionScreen> {
  List<({DateTime performedAt, WorkoutExercise workoutExercise})> _sessions =
      const [];
  Object? _loadError;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgression();
  }

  Future<void> _loadProgression() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final workouts = await widget.repository.getWorkouts(
        exerciseId: widget.exercise.id,
      );
      final sessions =
          <({DateTime performedAt, WorkoutExercise workoutExercise})>[];
      for (final workout in workouts) {
        for (final we in workout.exercises) {
          if (we.exerciseId == widget.exercise.id && we.sets.isNotEmpty) {
            sessions.add((
              performedAt: workout.performedAt,
              workoutExercise: we,
            ));
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  static String _formatWeight(double weight) {
    if (weight == weight.roundToDouble()) {
      return '${weight.toInt()} kg';
    }
    return '$weight kg';
  }

  double? _maxWeight() {
    double? max;
    for (final session in _sessions) {
      for (final set in session.workoutExercise.sets) {
        if (max == null || set.weight > max) {
          max = set.weight;
        }
      }
    }
    return max;
  }

  int? _maxReps() {
    int? max;
    for (final session in _sessions) {
      for (final set in session.workoutExercise.sets) {
        if (max == null || set.repetitions > max) {
          max = set.repetitions;
        }
      }
    }
    return max;
  }

  @override
  Widget build(BuildContext context) {
    final maxWeight = _maxWeight();
    final maxReps = _maxReps();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.exercise.name} progression',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: switch ((_isLoading, _loadError)) {
        (true, _) => const Center(child: CircularProgressIndicator()),
        (false, Object()) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Unable to load progression data.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadProgression,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        (false, null) when _sessions.isEmpty => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ExerciseDemonstrationWidget(
              exerciseName: widget.exercise.name,
              muscleId: widget.exercise.muscleId,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B241F) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2A3830)
                      : const Color(0xFFEBE5D8),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.show_chart_rounded,
                      size: 36,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No workout history for this exercise yet.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Start a session and record your sets to visualize your strength progression.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        (false, null) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Exercise Demonstration Motion Guide
            ExerciseDemonstrationWidget(
              exerciseName: widget.exercise.name,
              muscleId: widget.exercise.muscleId,
            ),
            const SizedBox(height: 16),

            // Progression Chart
            ProgressionChart(sessions: _sessions),
            const SizedBox(height: 16),

            // Summary Stats Cards (Aesthetic KPI dashboard)
            if (maxWeight != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B241F) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2A3830)
                        : const Color(0xFFEBE5D8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 20 : 6),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        value: '${_sessions.length}',
                        label: _sessions.length == 1 ? 'Session' : 'Sessions',
                        color: colorScheme.primary,
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: isDark
                            ? const Color(0xFF2E3B33)
                            : const Color(0xFFE5DFD3),
                      ),
                      _StatColumn(
                        value: _formatWeight(maxWeight),
                        label: 'Max Weight',
                        color: colorScheme.tertiary,
                      ),
                      if (maxReps != null) ...[
                        Container(
                          height: 36,
                          width: 1,
                          color: isDark
                              ? const Color(0xFF2E3B33)
                              : const Color(0xFFE5DFD3),
                        ),
                        _StatColumn(
                          value: '$maxReps',
                          label: 'Max Reps',
                          color: colorScheme.secondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            Text(
              'History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            for (final session in _sessions) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B241F) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2A3830)
                        : const Color(0xFFEBE5D8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 15 : 5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 15,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(session.performedAt),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${session.workoutExercise.sets.length} ${session.workoutExercise.sets.length == 1 ? 'set' : 'sets'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      for (
                        var i = 0;
                        i < session.workoutExercise.sets.length;
                        i++
                      ) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Set ${i + 1}:',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_formatWeight(session.workoutExercise.sets[i].weight)} × ${session.workoutExercise.sets[i].repetitions}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${_formatWeight(session.workoutExercise.sets[i].weight * session.workoutExercise.sets[i].repetitions)} vol',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      },
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.outline,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
