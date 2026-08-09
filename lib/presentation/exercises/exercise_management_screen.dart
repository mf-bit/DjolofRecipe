import 'package:flutter/material.dart';

import '../../data/repositories/gym_repository.dart';
import '../../domain/domain.dart';
import '../history/workout_history_screen.dart';
import '../workouts/workout_creation_screen.dart';
import 'exercise_progression_screen.dart';
import '../widgets/muscle_illustration.dart';
import '../widgets/training_plans_sheet.dart';
import '../widgets/current_plan_card.dart';

class ExerciseManagementScreen extends StatefulWidget {
  const ExerciseManagementScreen({
    super.key,
    required this.repository,
    this.exerciseIdGenerator,
    this.workoutIdGenerator,
    this.clock,
  });

  final GymRepository repository;
  final String Function()? exerciseIdGenerator;
  final String Function()? workoutIdGenerator;
  final DateTime Function()? clock;

  @override
  State<ExerciseManagementScreen> createState() =>
      _ExerciseManagementScreenState();
}

class _ExerciseManagementScreenState extends State<ExerciseManagementScreen> {
  static const _defaultMuscles = [
    ('chest', 'Chest'),
    ('back', 'Back'),
    ('shoulders', 'Shoulders'),
    ('biceps', 'Biceps'),
    ('triceps', 'Triceps'),
    ('quadriceps', 'Quadriceps'),
    ('hamstrings', 'Hamstrings'),
  ];

  List<Muscle> _muscles = const [];
  List<Exercise> _exercises = const [];
  TrainingPlan _currentPlan = defaultTrainingPlans.first;
  Object? _loadError;
  var _isLoading = true;

  void _showTrainingPlansSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TrainingPlansSheet(
        currentPlanId: _currentPlan.id,
        onSelectPlan: (plan) {
          setState(() {
            _currentPlan = plan;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Active plan updated to "${plan.name}"'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      var muscles = await widget.repository.getMuscles();
      if (muscles.isEmpty) {
        for (final muscle in _defaultMuscles) {
          await widget.repository.saveMuscle(
            Muscle(id: muscle.$1, name: muscle.$2),
          );
        }
        muscles = await widget.repository.getMuscles();
      }
      final exercises = await widget.repository.getExercises();
      if (!mounted) {
        return;
      }
      setState(() {
        _muscles = muscles;
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _showExerciseForm([Exercise? exercise]) async {
    if (_muscles.isEmpty) {
      return;
    }

    final savedExercise = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExerciseForm(
        muscles: _muscles,
        exercise: exercise,
        exerciseIdGenerator: widget.exerciseIdGenerator ?? _newExerciseId,
      ),
    );
    if (savedExercise == null) {
      return;
    }

    try {
      if (exercise == null) {
        await widget.repository.saveExercise(savedExercise);
      } else {
        await widget.repository.updateExercise(savedExercise);
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save the exercise.')),
        );
      }
    }
  }

  Future<void> _deleteExercise(Exercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete exercise?'),
        content: Text('Delete ${exercise.name}?'),
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
    if (confirmed != true) {
      return;
    }

    try {
      await widget.repository.deleteExercise(exercise.id);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete an exercise with workout history.'),
          ),
        );
      }
    }
  }

  Future<void> _startWorkout() async {
    final started = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutCreationScreen(
          repository: widget.repository,
          workoutIdGenerator: widget.workoutIdGenerator,
          clock: widget.clock,
        ),
      ),
    );
    if (started == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Workout started.')));
    }
  }

  void _openWorkoutHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutHistoryScreen(repository: widget.repository),
      ),
    );
  }

  void _openExerciseProgression(Exercise exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseProgressionScreen(
          exercise: exercise,
          repository: widget.repository,
        ),
      ),
    );
  }

  String _newExerciseId() =>
      'exercise-${DateTime.now().microsecondsSinceEpoch}';

  String? _selectedMuscleFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final filteredExercises = _selectedMuscleFilter == null
        ? _exercises
        : _exercises
              .where((e) => e.muscleId == _selectedMuscleFilter)
              .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.fitness_center,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YawooDial',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Fitness Progression',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2A23) : const Color(0xFFEFE9DC),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.history_rounded, size: 22),
              tooltip: 'Workout history',
              onPressed: _isLoading ? null : _openWorkoutHistory,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
              tooltip: 'Start workout',
              onPressed: _isLoading ? null : _startWorkout,
            ),
          ),
        ],
      ),
      body: switch ((_isLoading, _loadError)) {
        (true, _) => const Center(child: CircularProgressIndicator()),
        (false, Object()) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Unable to load exercises.'),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
        (false, null) when _exercises.isEmpty => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.fitness_center_outlined,
                      size: 64,
                      color: colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No exercises yet.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add exercises to organize your workout routines and track progression.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
        (false, null) => Column(
          children: [
            // Fitness Hero Banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              height: 104,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.surfaceContainerHighest,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/fitness_banner.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withAlpha(210),
                            Colors.black.withAlpha(70),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'DAILY FOCUS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Track & Outperform',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Every repetition brings you closer to your peak',
                          style: TextStyle(
                            color: Colors.white.withAlpha(210),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            CurrentPlanCard(
              plan: _currentPlan,
              onTapChangePlan: _showTrainingPlansSheet,
            ),
            if (_muscles.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _selectedMuscleFilter == null,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: _selectedMuscleFilter == null
                                ? colorScheme.primary
                                : (isDark
                                      ? const Color(0xFF2E3D35)
                                      : const Color(0xFFE5DDD0)),
                          ),
                        ),
                        selectedColor: colorScheme.primary,
                        labelStyle: TextStyle(
                          color: _selectedMuscleFilter == null
                              ? Colors.white
                              : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF2C3530)),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedMuscleFilter = null);
                        },
                      ),
                    ),
                    for (final muscle in _muscles)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(muscle.name),
                          selected: _selectedMuscleFilter == muscle.id,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: _selectedMuscleFilter == muscle.id
                                  ? colorScheme.primary
                                  : (isDark
                                        ? const Color(0xFF2E3D35)
                                        : const Color(0xFFE5DDD0)),
                            ),
                          ),
                          selectedColor: colorScheme.primary,
                          labelStyle: TextStyle(
                            color: _selectedMuscleFilter == muscle.id
                                ? Colors.white
                                : (isDark
                                      ? Colors.white70
                                      : const Color(0xFF2C3530)),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedMuscleFilter = selected
                                  ? muscle.id
                                  : null;
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: filteredExercises.isEmpty
                  ? Center(
                      child: Text(
                        'No exercises found for this muscle group.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredExercises.length,
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final exercise = filteredExercises[index];
                        return Material(
                          color: isDark
                              ? const Color(0xFF1B241F)
                              : Colors.white,
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
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: MuscleIllustration(
                                muscleId: exercise.muscleId,
                                size: 44,
                              ),
                              title: Text(
                                exercise.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                _muscleName(exercise.muscleId),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF758279),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: () => _openExerciseProgression(exercise),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    tooltip: 'Edit ${exercise.name}',
                                    onPressed: () =>
                                        _showExerciseForm(exercise),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                    ),
                                    tooltip: 'Delete ${exercise.name}',
                                    onPressed: () => _deleteExercise(exercise),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _showExerciseForm,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add exercise',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String _muscleName(String muscleId) {
    for (final muscle in _muscles) {
      if (muscle.id == muscleId) {
        return muscle.name;
      }
    }
    return 'Unknown muscle';
  }
}

class _ExerciseForm extends StatefulWidget {
  const _ExerciseForm({
    required this.muscles,
    required this.exerciseIdGenerator,
    this.exercise,
  });

  final List<Muscle> muscles;
  final Exercise? exercise;
  final String Function() exerciseIdGenerator;

  @override
  State<_ExerciseForm> createState() => _ExerciseFormState();
}

class _ExerciseFormState extends State<_ExerciseForm> {
  late final TextEditingController _nameController;
  late String _muscleId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise?.name);
    _muscleId = widget.exercise?.muscleId ?? widget.muscles.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.pop(
      context,
      Exercise(
        id: widget.exercise?.id ?? widget.exerciseIdGenerator(),
        name: name,
        muscleId: _muscleId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.exercise != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D19) : const Color(0xFFFBF8F2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        top: 24,
        right: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFD6CFC1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            isEditing ? 'Edit exercise' : 'Add exercise',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('exercise-name-field'),
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Exercise name'),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _muscleId,
            decoration: const InputDecoration(labelText: 'Muscle'),
            items: widget.muscles
                .map(
                  (muscle) => DropdownMenuItem(
                    value: muscle.id,
                    child: Text(muscle.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                setState(() => _muscleId = value);
              }
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }
}
