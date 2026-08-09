import 'package:flutter/material.dart';

import '../../data/repositories/gym_repository.dart';
import '../../domain/domain.dart';
import '../widgets/muscle_illustration.dart';
import 'workout_recording_screen.dart';

class WorkoutCreationScreen extends StatefulWidget {
  const WorkoutCreationScreen({
    super.key,
    required this.repository,
    this.workoutIdGenerator,
    this.clock,
  });

  final GymRepository repository;
  final String Function()? workoutIdGenerator;
  final DateTime Function()? clock;

  @override
  State<WorkoutCreationScreen> createState() => _WorkoutCreationScreenState();
}

class _WorkoutCreationScreenState extends State<WorkoutCreationScreen> {
  List<Muscle> _muscles = const [];
  List<Exercise> _exercises = const [];
  final Set<String> _selectedExerciseIds = {};
  String? _muscleId;
  Object? _error;
  var _isLoading = true;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMuscles();
  }

  Future<void> _loadMuscles() async {
    try {
      final muscles = await widget.repository.getMuscles();
      if (!mounted) {
        return;
      }
      setState(() {
        _muscles = muscles;
        _muscleId = muscles.isEmpty ? null : muscles.first.id;
      });
      await _loadExercises();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadExercises() async {
    final muscleId = _muscleId;
    if (muscleId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final exercises = await widget.repository.getExercises(
        muscleId: muscleId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _exercises = exercises;
        _selectedExerciseIds.clear();
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startWorkout() async {
    if (_selectedExerciseIds.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);
    final now = (widget.clock ?? DateTime.now)();
    final workoutId =
        widget.workoutIdGenerator?.call() ??
        'workout-${now.microsecondsSinceEpoch}';
    final selectedExercises = _exercises
        .where((exercise) => _selectedExerciseIds.contains(exercise.id))
        .toList(growable: false);
    final workout = Workout(
      id: workoutId,
      performedAt: now,
      exercises: [
        for (var index = 0; index < selectedExercises.length; index++)
          WorkoutExercise(
            id: '$workoutId-exercise-$index',
            exerciseId: selectedExercises[index].id,
            sets: const [],
          ),
      ],
    );

    try {
      await widget.repository.saveWorkout(workout);
      if (mounted) {
        final allSelected = _exercises
            .where((e) => _selectedExerciseIds.contains(e.id))
            .toList(growable: false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutRecordingScreen(
              repository: widget.repository,
              workout: workout,
              exercises: allSelected,
            ),
          ),
          result: true,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to start the workout.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start workout')),
      body: switch ((_isLoading, _error)) {
        (true, _) => const Center(child: CircularProgressIndicator()),
        (false, Object()) => Center(
          child: OutlinedButton(
            onPressed: _loadMuscles,
            child: const Text('Retry'),
          ),
        ),
        (false, null) => _WorkoutSelection(
          muscles: _muscles,
          exercises: _exercises,
          muscleId: _muscleId,
          selectedExerciseIds: _selectedExerciseIds,
          isSaving: _isSaving,
          onMuscleChanged: (muscleId) {
            setState(() {
              _muscleId = muscleId;
              _isLoading = true;
            });
            _loadExercises();
          },
          onExerciseChanged: (exerciseId, selected) {
            setState(() {
              if (selected) {
                _selectedExerciseIds.add(exerciseId);
              } else {
                _selectedExerciseIds.remove(exerciseId);
              }
            });
          },
          onStart: _startWorkout,
        ),
      },
    );
  }
}

class _WorkoutSelection extends StatelessWidget {
  const _WorkoutSelection({
    required this.muscles,
    required this.exercises,
    required this.muscleId,
    required this.selectedExerciseIds,
    required this.isSaving,
    required this.onMuscleChanged,
    required this.onExerciseChanged,
    required this.onStart,
  });

  final List<Muscle> muscles;
  final List<Exercise> exercises;
  final String? muscleId;
  final Set<String> selectedExerciseIds;
  final bool isSaving;
  final ValueChanged<String> onMuscleChanged;
  final void Function(String exerciseId, bool selected) onExerciseChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    if (muscles.isEmpty) {
      return const Center(child: Text('No muscle groups are available.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (muscleId != null) ...[
                MuscleIllustration(muscleId: muscleId!, size: 52),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: muscleId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Muscle Group',
                  ),
                  items: muscles
                      .map(
                        (muscle) => DropdownMenuItem(
                          value: muscle.id,
                          child: Text(muscle.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      onMuscleChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: exercises.isEmpty
              ? const Center(child: Text('No exercises for this muscle.'))
              : ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return CheckboxListTile(
                      secondary: MuscleIllustration(
                        muscleId: exercise.muscleId,
                        size: 38,
                      ),
                      title: Text(exercise.name),
                      value: selectedExerciseIds.contains(exercise.id),
                      onChanged: (value) =>
                          onExerciseChanged(exercise.id, value ?? false),
                    );
                  },
                ),
        ),

        SafeArea(
          minimum: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: selectedExerciseIds.isEmpty || isSaving
                  ? null
                  : onStart,
              child: Text(isSaving ? 'Starting...' : 'Start workout'),
            ),
          ),
        ),
      ],
    );
  }
}
