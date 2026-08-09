import 'package:flutter/material.dart';

import '../../data/repositories/gym_repository.dart';
import '../../domain/domain.dart';

import '../widgets/muscle_illustration.dart';
import '../workouts/workout_recording_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  const WorkoutDetailScreen({
    super.key,
    required this.workout,
    required this.exercises,
    this.repository,
  });

  final Workout workout;
  final List<Exercise> exercises;
  final GymRepository? repository;

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late Workout _workout;

  @override
  void initState() {
    super.initState();
    _workout = widget.workout;
  }

  String _exerciseName(String exerciseId) {
    for (final exercise in widget.exercises) {
      if (exercise.id == exerciseId) {
        return exercise.name;
      }
    }
    return 'Exercise';
  }

  String _exerciseMuscleId(String exerciseId) {
    for (final exercise in widget.exercises) {
      if (exercise.id == exerciseId) {
        return exercise.muscleId;
      }
    }
    return '';
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

  Future<void> _editWorkout() async {
    final repo = widget.repository;
    if (repo == null) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutRecordingScreen(
          repository: repo,
          workout: _workout,
          exercises: widget.exercises,
        ),
      ),
    );

    if (updated == true) {
      // Reload the updated workout
      final workouts = await repo.getWorkouts();
      final reloaded = workouts.firstWhere(
        (w) => w.id == _workout.id,
        orElse: () => _workout,
      );
      if (mounted) {
        setState(() {
          _workout = reloaded;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Workout updated.')));
      }
    }
  }

  Future<void> _deleteWorkout() async {
    final repo = widget.repository;
    if (repo == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete workout?'),
        content: const Text(
          'Are you sure you want to delete this workout? This action cannot be undone.',
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
      await repo.deleteWorkout(_workout.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to delete workout.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout details'),
        actions: [
          if (widget.repository != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit workout',
              onPressed: _editWorkout,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete workout',
              onPressed: _deleteWorkout,
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(_workout.performedAt),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_workout.exercises.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No exercises recorded for this workout.'),
              ),
            )
          else
            for (final workoutExercise in _workout.exercises) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          MuscleIllustration(
                            muscleId: _exerciseMuscleId(
                              workoutExercise.exerciseId,
                            ),
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _exerciseName(workoutExercise.exerciseId),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (workoutExercise.sets.isEmpty)
                        Text(
                          'No sets recorded.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        )
                      else
                        for (
                          var i = 0;
                          i < workoutExercise.sets.length;
                          i++
                        ) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  'Set ${i + 1}:',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_formatWeight(workoutExercise.sets[i].weight)} × ${workoutExercise.sets[i].repetitions}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}
