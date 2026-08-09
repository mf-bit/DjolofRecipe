import 'package:flutter/material.dart';

import '../../data/repositories/gym_repository.dart';
import '../../domain/domain.dart';
import '../widgets/exercise_demonstration.dart';

class WorkoutRecordingScreen extends StatefulWidget {
  const WorkoutRecordingScreen({
    super.key,
    required this.repository,
    required this.workout,
    required this.exercises,
    this.setIdGenerator,
  });

  final GymRepository repository;
  final Workout workout;
  final List<Exercise> exercises;
  final String Function()? setIdGenerator;

  @override
  State<WorkoutRecordingScreen> createState() => _WorkoutRecordingScreenState();
}

class _WorkoutRecordingScreenState extends State<WorkoutRecordingScreen> {
  late final List<_ExerciseDraft> _exerciseDrafts;
  Map<String, List<WorkoutSet>> _previousSets = {};
  var _isLoadingPrevious = true;
  var _isSaving = false;
  var _setIdCount = 0;

  @override
  void initState() {
    super.initState();
    _exerciseDrafts = widget.workout.exercises
        .map(
          (workoutExercise) => _ExerciseDraft(
            workoutExercise: workoutExercise,
            name: _exerciseName(workoutExercise.exerciseId),
          ),
        )
        .toList(growable: false);
    _loadPreviousPerformance();
  }

  Future<void> _loadPreviousPerformance() async {
    final results = <String, List<WorkoutSet>>{};
    for (final exercise in widget.workout.exercises) {
      final latest = await widget.repository.getLatestWorkoutExercise(
        exercise.exerciseId,
        excludingWorkoutId: widget.workout.id,
      );
      results[exercise.exerciseId] = latest?.sets ?? const [];
    }
    if (mounted) {
      setState(() {
        _previousSets = results;
        _isLoadingPrevious = false;
      });
    }
  }

  @override
  void dispose() {
    for (final exercise in _exerciseDrafts) {
      exercise.dispose();
    }
    super.dispose();
  }

  String _exerciseName(String exerciseId) {
    for (final exercise in widget.exercises) {
      if (exercise.id == exerciseId) {
        return exercise.name;
      }
    }
    return 'Exercise';
  }

  void _addSet(_ExerciseDraft exercise) {
    setState(() => exercise.sets.add(_SetDraft(id: _nextSetId())));
  }

  void _removeSet(_ExerciseDraft exercise, _SetDraft set) {
    setState(() {
      exercise.sets.remove(set);
      set.dispose();
    });
  }

  String _nextSetId() {
    _setIdCount++;
    return widget.setIdGenerator?.call() ??
        '${widget.workout.id}-set-${DateTime.now().microsecondsSinceEpoch}-$_setIdCount';
  }

  Future<void> _saveWorkout() async {
    Workout workout;
    try {
      workout = Workout(
        id: widget.workout.id,
        performedAt: widget.workout.performedAt,
        exercises: _exerciseDrafts
            .map(
              (exercise) => WorkoutExercise(
                id: exercise.id,
                exerciseId: exercise.exerciseId,
                sets: exercise.sets.map((set) => set.toWorkoutSet()).toList(),
              ),
            )
            .toList(growable: false),
      );
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid weight and a positive repetition count.',
          ),
        ),
      );
      return;
    } on ArgumentError {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid weight and a positive repetition count.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.repository.updateWorkout(workout);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save the workout.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record workout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final exercise in _exerciseDrafts) ...[
            _ExerciseCard(
              exercise: exercise,
              previousSets: _previousSets[exercise.exerciseId],
              isLoadingPrevious: _isLoadingPrevious,
              onAddSet: () => _addSet(exercise),
              onRemoveSet: (set) => _removeSet(exercise, set),
            ),
            const SizedBox(height: 16),
          ],
          FilledButton(
            onPressed: _isSaving ? null : _saveWorkout,
            child: Text(_isSaving ? 'Saving...' : 'Save workout'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.previousSets,
    required this.isLoadingPrevious,
    required this.onAddSet,
    required this.onRemoveSet,
  });

  final _ExerciseDraft exercise;
  final List<WorkoutSet>? previousSets;
  final bool isLoadingPrevious;
  final VoidCallback onAddSet;
  final ValueChanged<_SetDraft> onRemoveSet;

  void _showFormGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExerciseDemonstrationWidget(exerciseName: exercise.name),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showFormGuide(context),
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: const Text('Guide', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _PreviousPerformanceSection(
              previousSets: previousSets,
              isLoading: isLoadingPrevious,
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < exercise.sets.length; index++)
              _SetFields(
                set: exercise.sets[index],
                number: index + 1,
                onRemove: () => onRemoveSet(exercise.sets[index]),
              ),
            OutlinedButton.icon(
              onPressed: onAddSet,
              icon: const Icon(Icons.add),
              label: const Text('Add set'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviousPerformanceSection extends StatelessWidget {
  const _PreviousPerformanceSection({
    required this.previousSets,
    required this.isLoading,
  });

  final List<WorkoutSet>? previousSets;
  final bool isLoading;

  static String _formatWeight(double weight) {
    if (weight == weight.roundToDouble()) {
      return '${weight.toInt()} kg';
    }
    return '$weight kg';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox.shrink();
    }

    final sets = previousSets;
    if (sets == null || sets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No previous performance recorded.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Previous performance',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          for (var index = 0; index < sets.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                'Set ${index + 1}: ${_formatWeight(sets[index].weight)} × ${sets[index].repetitions}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

class _SetFields extends StatelessWidget {
  const _SetFields({
    required this.set,
    required this.number,
    required this.onRemove,
  });

  final _SetDraft set;
  final int number;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text('$number'),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: Key('weight-field-${set.id}'),
              controller: set.weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Weight',
                suffixText: 'kg',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: Key('repetitions-field-${set.id}'),
              controller: set.repetitionsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Reps',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: 'Remove set $number',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _ExerciseDraft {
  _ExerciseDraft({required WorkoutExercise workoutExercise, required this.name})
    : id = workoutExercise.id,
      exerciseId = workoutExercise.exerciseId,
      sets = workoutExercise.sets
          .map(_SetDraft.fromWorkoutSet)
          .toList(growable: true);

  final String id;
  final String exerciseId;
  final String name;
  final List<_SetDraft> sets;

  void dispose() {
    for (final set in sets) {
      set.dispose();
    }
  }
}

class _SetDraft {
  _SetDraft({required this.id})
    : weightController = TextEditingController(),
      repetitionsController = TextEditingController();

  _SetDraft.fromWorkoutSet(WorkoutSet set)
    : id = set.id,
      weightController = TextEditingController(text: set.weight.toString()),
      repetitionsController = TextEditingController(
        text: set.repetitions.toString(),
      );

  final String id;
  final TextEditingController weightController;
  final TextEditingController repetitionsController;

  WorkoutSet toWorkoutSet() {
    final weight = double.tryParse(weightController.text.trim());
    final repetitions = int.tryParse(repetitionsController.text.trim());
    if (weight == null || repetitions == null) {
      throw const FormatException();
    }
    return WorkoutSet(id: id, weight: weight, repetitions: repetitions);
  }

  void dispose() {
    weightController.dispose();
    repetitionsController.dispose();
  }
}
