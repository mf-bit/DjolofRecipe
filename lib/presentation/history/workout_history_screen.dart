import 'package:flutter/material.dart';

import '../../data/repositories/gym_repository.dart';
import '../../domain/domain.dart';
import '../workouts/workout_creation_screen.dart';
import 'workout_detail_screen.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key, required this.repository});

  final GymRepository repository;

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  List<Workout> _workouts = const [];
  List<Exercise> _exercises = const [];
  Object? _loadError;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final workouts = await widget.repository.getWorkouts();
      final exercises = await widget.repository.getExercises();
      if (!mounted) return;
      setState(() {
        _workouts = workouts;
        _exercises = exercises;
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

  String _exerciseName(String exerciseId) {
    for (final exercise in _exercises) {
      if (exercise.id == exerciseId) {
        return exercise.name;
      }
    }
    return 'Exercise';
  }

  String _workoutSummary(Workout workout) {
    if (workout.exercises.isEmpty) {
      return 'No exercises';
    }
    return workout.exercises
        .map((e) {
          final name = _exerciseName(e.exerciseId);
          final count = e.sets.length;
          return '$name ($count ${count == 1 ? 'set' : 'sets'})';
        })
        .join(', ');
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

  Future<void> _deleteWorkout(Workout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete workout?'),
        content: Text(
          'Delete workout from ${_formatDate(workout.performedAt)}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.repository.deleteWorkout(workout.id);
      await _loadHistory();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to delete the workout.')),
        );
      }
    }
  }

  Future<void> _openWorkoutDetail(Workout workout) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(
          workout: workout,
          exercises: _exercises,
          repository: widget.repository,
        ),
      ),
    );
    await _loadHistory();
  }

  Future<void> _startWorkout() async {
    final started = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutCreationScreen(repository: widget.repository),
      ),
    );
    if (started == true) {
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Workout history',
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
              const Text('Unable to load workout history.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadHistory,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        (false, null) when _workouts.isEmpty => Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(120),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No workout history yet.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start recording your training sessions to track your progression over time.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _startWorkout,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start workout'),
                ),
              ],
            ),
          ),
        ),
        (false, null) => ListView.separated(
          itemCount: _workouts.length,
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final workout = _workouts[index];
            return Material(
              color: isDark ? const Color(0xFF1B241F) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2A3830)
                        : const Color(0xFFEBE5D8),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    _formatDate(workout.performedAt),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _workoutSummary(workout),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF5A665E),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
                        tooltip: 'Delete workout',
                        onPressed: () => _deleteWorkout(workout),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                  onTap: () => _openWorkoutDetail(workout),
                ),
              ),
            );
          },
        ),
      },
    );
  }
}
