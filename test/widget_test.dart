import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_progression/data/data.dart';
import 'package:gym_progression/domain/domain.dart';
import 'package:gym_progression/main.dart';
import 'package:gym_progression/presentation/workouts/workout_recording_screen.dart';

void main() {
  testWidgets('creates, edits, and deletes an exercise', (tester) async {
    final repository = _MemoryGymRepository();
    await tester.pumpWidget(
      GymProgressionApp(
        repository: repository,
        exerciseIdGenerator: () => 'exercise-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No exercises yet.'), findsOneWidget);
    expect(repository.muscles, hasLength(7));

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('exercise-name-field')),
      'Squat',
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('Chest'), findsWidgets);

    await tester.tap(find.byTooltip('Edit Squat'));

    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('exercise-name-field')),
      'Barbell Squat',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Barbell Squat'), findsOneWidget);
    expect(find.text('Squat'), findsNothing);

    await tester.tap(find.byTooltip('Delete Barbell Squat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No exercises yet.'), findsOneWidget);
  });

  testWidgets('starts a workout and navigates to set recording', (
    tester,
  ) async {
    final repository = _MemoryGymRepository()
      ..muscles.add(Muscle(id: 'chest', name: 'Chest'))
      ..muscles.add(Muscle(id: 'back', name: 'Back'))
      ..exercises.add(
        Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
      )
      ..exercises.add(
        Exercise(id: 'barbell-row', name: 'Barbell Row', muscleId: 'back'),
      );
    final performedAt = DateTime.utc(2026, 8, 25, 10, 30);

    await tester.pumpWidget(
      GymProgressionApp(
        repository: repository,
        workoutIdGenerator: () => 'workout-1',
        clock: () => performedAt,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Start workout'));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Barbell Row'), findsNothing);

    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Start workout'));
    await tester.pumpAndSettle();

    // The workout shell is persisted.
    expect(repository.workouts, hasLength(1));
    expect(repository.workouts.single.id, 'workout-1');
    expect(repository.workouts.single.performedAt, performedAt);
    expect(
      repository.workouts.single.exercises.single.exerciseId,
      'bench-press',
    );
    expect(repository.workouts.single.exercises.single.sets, isEmpty);

    // We navigated to the recording screen.
    expect(find.text('Record workout'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
  });

  testWidgets('records sets with different weights and reps', (tester) async {
    final repository = _MemoryGymRepository();
    final workout = Workout(
      id: 'workout-1',
      performedAt: DateTime.utc(2026, 8, 25, 10, 30),
      exercises: [
        WorkoutExercise(id: 'we-1', exerciseId: 'bench-press', sets: const []),
      ],
    );
    repository.workouts.add(workout);
    final exercises = [
      Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
    ];

    var setIdCounter = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: WorkoutRecordingScreen(
          repository: repository,
          workout: workout,
          exercises: exercises,
          setIdGenerator: () => 'set-${++setIdCounter}',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Screen shows the exercise with no sets.
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Save workout'), findsOneWidget);

    // Add first set.
    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('weight-field-set-1')), '60');
    await tester.enterText(
      find.byKey(const Key('repetitions-field-set-1')),
      '10',
    );

    // Add second set with different weight.
    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('weight-field-set-2')), '62.5');
    await tester.enterText(
      find.byKey(const Key('repetitions-field-set-2')),
      '8',
    );

    // Add third set.
    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('weight-field-set-3')), '60');
    await tester.enterText(
      find.byKey(const Key('repetitions-field-set-3')),
      '9',
    );

    // Remove second set.
    await tester.tap(find.byTooltip('Remove set 2'));
    await tester.pumpAndSettle();

    // Save workout.
    await tester.tap(find.text('Save workout'));
    await tester.pumpAndSettle();

    // Verify persisted data.
    final saved = repository.workouts.single;
    expect(saved.id, 'workout-1');
    final sets = saved.exercises.single.sets;
    expect(sets, hasLength(2));
    expect(sets[0].weight, 60);
    expect(sets[0].repetitions, 10);
    expect(sets[1].weight, 60);
    expect(sets[1].repetitions, 9);
  });

  testWidgets('shows error when set fields are invalid', (tester) async {
    final repository = _MemoryGymRepository();
    final workout = Workout(
      id: 'workout-1',
      performedAt: DateTime.utc(2026, 8, 25, 10, 30),
      exercises: [
        WorkoutExercise(id: 'we-1', exerciseId: 'bench-press', sets: const []),
      ],
    );
    repository.workouts.add(workout);
    final exercises = [
      Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
    ];

    var setIdCounter = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: WorkoutRecordingScreen(
          repository: repository,
          workout: workout,
          exercises: exercises,
          setIdGenerator: () => 'set-${++setIdCounter}',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Add a set but leave fields empty.
    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save workout'));
    await tester.pumpAndSettle();

    // Error snackbar is shown.
    expect(
      find.text('Enter a valid weight and a positive repetition count.'),
      findsOneWidget,
    );

    // Workout was NOT updated (still has empty sets).
    expect(repository.workouts.single.exercises.single.sets, isEmpty);
  });

  testWidgets('displays previous performance for exercises with history', (
    tester,
  ) async {
    final repository = _MemoryGymRepository();
    // Historical workout from yesterday
    final previousWorkout = Workout(
      id: 'workout-prev',
      performedAt: DateTime.utc(2026, 8, 24, 10, 0),
      exercises: [
        WorkoutExercise(
          id: 'we-prev',
          exerciseId: 'bench-press',
          sets: [
            WorkoutSet(id: 's-1', weight: 60, repetitions: 11),
            WorkoutSet(id: 's-2', weight: 60, repetitions: 10),
            WorkoutSet(id: 's-3', weight: 60, repetitions: 9),
          ],
        ),
      ],
    );
    repository.workouts.add(previousWorkout);

    // Today's active workout
    final currentWorkout = Workout(
      id: 'workout-today',
      performedAt: DateTime.utc(2026, 8, 25, 10, 0),
      exercises: [
        WorkoutExercise(
          id: 'we-today',
          exerciseId: 'bench-press',
          sets: const [],
        ),
      ],
    );
    repository.workouts.add(currentWorkout);

    final exercises = [
      Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: WorkoutRecordingScreen(
          repository: repository,
          workout: currentWorkout,
          exercises: exercises,
          setIdGenerator: () => 'set-today-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify previous performance is displayed clearly
    expect(find.text('Previous performance'), findsOneWidget);
    expect(find.text('Set 1: 60 kg × 11'), findsOneWidget);
    expect(find.text('Set 2: 60 kg × 10'), findsOneWidget);
    expect(find.text('Set 3: 60 kg × 9'), findsOneWidget);

    // Enter today's progression
    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('weight-field-set-today-1')),
      '62.5',
    );
    await tester.enterText(
      find.byKey(const Key('repetitions-field-set-today-1')),
      '10',
    );

    await tester.tap(find.text('Save workout'));
    await tester.pumpAndSettle();

    // Verify historical workout was preserved and NOT overwritten
    final historicalWorkout = repository.workouts.firstWhere(
      (w) => w.id == 'workout-prev',
    );
    expect(historicalWorkout.exercises.single.sets, hasLength(3));
    expect(historicalWorkout.exercises.single.sets[0].weight, 60);
    expect(historicalWorkout.exercises.single.sets[0].repetitions, 11);

    // Verify today's workout has new progression
    final savedToday = repository.workouts.firstWhere(
      (w) => w.id == 'workout-today',
    );
    expect(savedToday.exercises.single.sets, hasLength(1));
    expect(savedToday.exercises.single.sets.single.weight, 62.5);
    expect(savedToday.exercises.single.sets.single.repetitions, 10);
  });

  testWidgets(
    'displays distinct previous performance per exercise and empty message when none',
    (tester) async {
      final repository = _MemoryGymRepository();
      // Historical workout with Bench Press
      repository.workouts.add(
        Workout(
          id: 'workout-prev',
          performedAt: DateTime.utc(2026, 8, 24, 10, 0),
          exercises: [
            WorkoutExercise(
              id: 'we-bench',
              exerciseId: 'bench-press',
              sets: [WorkoutSet(id: 's-1', weight: 80, repetitions: 5)],
            ),
          ],
        ),
      );

      // Today's workout with Bench Press and Incline Bench Press
      final currentWorkout = Workout(
        id: 'workout-today',
        performedAt: DateTime.utc(2026, 8, 25, 10, 0),
        exercises: [
          WorkoutExercise(
            id: 'we-1',
            exerciseId: 'bench-press',
            sets: const [],
          ),
          WorkoutExercise(
            id: 'we-2',
            exerciseId: 'incline-bench',
            sets: const [],
          ),
        ],
      );
      repository.workouts.add(currentWorkout);

      final exercises = [
        Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
        Exercise(
          id: 'incline-bench',
          name: 'Incline Bench Press',
          muscleId: 'chest',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutRecordingScreen(
            repository: repository,
            workout: currentWorkout,
            exercises: exercises,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bench Press shows its previous performance
      expect(find.text('Set 1: 80 kg × 5'), findsOneWidget);

      // Incline Bench Press shows empty state
      expect(find.text('No previous performance recorded.'), findsOneWidget);
    },
  );

  testWidgets('views workout history and opens workout details', (
    tester,
  ) async {
    final repository = _MemoryGymRepository()
      ..muscles.add(Muscle(id: 'chest', name: 'Chest'))
      ..exercises.add(
        Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
      );

    final workout1 = Workout(
      id: 'w-1',
      performedAt: DateTime.utc(2026, 8, 20, 14, 0),
      exercises: [
        WorkoutExercise(
          id: 'we-1',
          exerciseId: 'bench-press',
          sets: [
            WorkoutSet(id: 's-1', weight: 60, repetitions: 10),
            WorkoutSet(id: 's-2', weight: 60, repetitions: 9),
          ],
        ),
      ],
    );

    final workout2 = Workout(
      id: 'w-2',
      performedAt: DateTime.utc(2026, 8, 22, 16, 30),
      exercises: [
        WorkoutExercise(
          id: 'we-2',
          exerciseId: 'bench-press',
          sets: [WorkoutSet(id: 's-3', weight: 62.5, repetitions: 8)],
        ),
      ],
    );

    repository.workouts.addAll([workout1, workout2]);

    await tester.pumpWidget(GymProgressionApp(repository: repository));
    await tester.pumpAndSettle();

    // Open Workout History
    await tester.tap(find.byTooltip('Workout history'));
    await tester.pumpAndSettle();

    expect(find.text('Workout history'), findsOneWidget);
    // Both workouts are listed
    expect(find.textContaining('Bench Press (1 set)'), findsOneWidget);
    expect(find.textContaining('Bench Press (2 sets)'), findsOneWidget);

    // Tap on the latest workout (w-2)
    await tester.tap(find.textContaining('Bench Press (1 set)'));
    await tester.pumpAndSettle();

    // Verify workout detail screen
    expect(find.text('Workout details'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Set 1:'), findsOneWidget);
    expect(find.text('62.5 kg × 8'), findsOneWidget);
  });

  testWidgets('views exercise progression from exercise management screen', (
    tester,
  ) async {
    final repository = _MemoryGymRepository()
      ..muscles.add(Muscle(id: 'chest', name: 'Chest'))
      ..exercises.add(
        Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
      );

    final workout1 = Workout(
      id: 'w-1',
      performedAt: DateTime.utc(2026, 8, 20, 10, 0),
      exercises: [
        WorkoutExercise(
          id: 'we-1',
          exerciseId: 'bench-press',
          sets: [WorkoutSet(id: 's-1', weight: 60, repetitions: 10)],
        ),
      ],
    );

    final workout2 = Workout(
      id: 'w-2',
      performedAt: DateTime.utc(2026, 8, 25, 10, 0),
      exercises: [
        WorkoutExercise(
          id: 'we-2',
          exerciseId: 'bench-press',
          sets: [WorkoutSet(id: 's-2', weight: 65, repetitions: 8)],
        ),
      ],
    );

    repository.workouts.addAll([workout1, workout2]);

    await tester.pumpWidget(GymProgressionApp(repository: repository));
    await tester.pumpAndSettle();

    // Tap the Bench Press exercise to view progression
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();

    // Progression screen is shown
    expect(find.text('Bench Press progression'), findsOneWidget);
    expect(find.text('Motion Demonstration'), findsOneWidget);

    // Scroll down to view the chart and stats
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget); // 2 sessions
    expect(find.text('65 kg'), findsWidgets); // Max weight & in set

    // Scroll down to view the earlier session
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('60 kg × 10'), findsOneWidget);
  });

  testWidgets('shows empty state when exercise has no workout history', (
    tester,
  ) async {
    final repository = _MemoryGymRepository()
      ..muscles.add(Muscle(id: 'chest', name: 'Chest'))
      ..exercises.add(
        Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
      );

    await tester.pumpWidget(GymProgressionApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();

    expect(
      find.text('No workout history for this exercise yet.'),
      findsOneWidget,
    );
  });

  testWidgets('filters exercises by muscle group chips', (tester) async {
    final repository = _MemoryGymRepository()
      ..muscles.add(Muscle(id: 'chest', name: 'Chest'))
      ..muscles.add(Muscle(id: 'back', name: 'Back'))
      ..exercises.add(
        Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
      )
      ..exercises.add(
        Exercise(id: 'barbell-row', name: 'Barbell Row', muscleId: 'back'),
      );

    await tester.pumpWidget(GymProgressionApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Barbell Row'), findsOneWidget);

    // Filter by Back
    await tester.tap(find.widgetWithText(FilterChip, 'Back'));
    await tester.pumpAndSettle();

    expect(find.text('Barbell Row'), findsOneWidget);
    expect(find.text('Bench Press'), findsNothing);

    // Filter back to All
    await tester.tap(find.widgetWithText(FilterChip, 'All'));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Barbell Row'), findsOneWidget);
  });

  testWidgets(
    'displays progression chart and switches between metrics (Weight, Reps, Volume)',
    (tester) async {
      final repository = _MemoryGymRepository()
        ..muscles.add(Muscle(id: 'chest', name: 'Chest'))
        ..exercises.add(
          Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
        );

      final workout1 = Workout(
        id: 'w-1',
        performedAt: DateTime.utc(2026, 8, 20, 10, 0),
        exercises: [
          WorkoutExercise(
            id: 'we-1',
            exerciseId: 'bench-press',
            sets: [
              WorkoutSet(id: 's-1', weight: 60, repetitions: 10),
              WorkoutSet(id: 's-2', weight: 60, repetitions: 8),
            ],
          ),
        ],
      );

      final workout2 = Workout(
        id: 'w-2',
        performedAt: DateTime.utc(2026, 8, 25, 10, 0),
        exercises: [
          WorkoutExercise(
            id: 'we-2',
            exerciseId: 'bench-press',
            sets: [WorkoutSet(id: 's-3', weight: 65, repetitions: 9)],
          ),
        ],
      );

      repository.workouts.addAll([workout1, workout2]);

      await tester.pumpWidget(GymProgressionApp(repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Scroll to chart
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Verify progression chart exists
      expect(find.text('Progression Chart'), findsOneWidget);
      expect(find.text('Max Weight'), findsWidgets);
      expect(find.text('Max Reps'), findsWidgets);
      expect(find.text('Total Volume'), findsOneWidget);

      // Switch to Max Reps metric
      await tester.tap(find.text('Max Reps').first);
      await tester.pumpAndSettle();

      // Switch to Total Volume metric
      await tester.tap(find.text('Total Volume'));
      await tester.pumpAndSettle();

      // Scroll down to stats card
      await tester.drag(find.byType(ListView), const Offset(0, -250));
      await tester.pumpAndSettle();

      // Check max reps summary card
      expect(find.text('10'), findsOneWidget); // Max reps across all sessions
    },
  );

  testWidgets('edits an existing workout from workout detail screen', (
    tester,
  ) async {
    final repository = _MemoryGymRepository()
      ..muscles.add(Muscle(id: 'chest', name: 'Chest'))
      ..exercises.add(
        Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
      );

    final workout = Workout(
      id: 'w-1',
      performedAt: DateTime.utc(2026, 8, 25, 10, 0),
      exercises: [
        WorkoutExercise(
          id: 'we-1',
          exerciseId: 'bench-press',
          sets: [WorkoutSet(id: 's-1', weight: 60, repetitions: 10)],
        ),
      ],
    );
    repository.workouts.add(workout);

    await tester.pumpWidget(GymProgressionApp(repository: repository));
    await tester.pumpAndSettle();

    // Open Workout History
    await tester.tap(find.byTooltip('Workout history'));
    await tester.pumpAndSettle();

    // Open workout details
    await tester.tap(find.textContaining('Bench Press'));
    await tester.pumpAndSettle();

    expect(find.text('Workout details'), findsOneWidget);
    expect(find.text('60 kg × 10'), findsOneWidget);

    // Tap Edit
    await tester.tap(find.byTooltip('Edit workout'));
    await tester.pumpAndSettle();

    expect(find.text('Record workout'), findsOneWidget);

    // Change weight to 70 and save
    await tester.enterText(find.byKey(const Key('weight-field-s-1')), '70');
    await tester.tap(find.text('Save workout'));
    await tester.pumpAndSettle();

    // Verify workout was updated
    expect(find.text('Workout details'), findsOneWidget);
    expect(find.text('70 kg × 10'), findsOneWidget);
    expect(repository.workouts.single.exercises.single.sets.single.weight, 70);
  });

  testWidgets(
    'deletes a workout with confirmation from workout detail screen',
    (tester) async {
      final repository = _MemoryGymRepository()
        ..muscles.add(Muscle(id: 'chest', name: 'Chest'))
        ..exercises.add(
          Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
        );

      final workout = Workout(
        id: 'w-1',
        performedAt: DateTime.utc(2026, 8, 25, 10, 0),
        exercises: [
          WorkoutExercise(
            id: 'we-1',
            exerciseId: 'bench-press',
            sets: [WorkoutSet(id: 's-1', weight: 60, repetitions: 10)],
          ),
        ],
      );
      repository.workouts.add(workout);

      await tester.pumpWidget(GymProgressionApp(repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Workout history'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Bench Press'));
      await tester.pumpAndSettle();

      // Tap Delete button
      await tester.tap(find.byTooltip('Delete workout'));
      await tester.pumpAndSettle();

      expect(find.text('Delete workout?'), findsOneWidget);

      // Confirm Delete
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      // History screen is shown and workout is gone
      expect(find.text('Workout history'), findsOneWidget);
      expect(find.text('No workout history yet.'), findsOneWidget);
      expect(repository.workouts, isEmpty);
    },
  );

  testWidgets('deletes a workout from workout history screen', (tester) async {
    final repository = _MemoryGymRepository()
      ..muscles.add(Muscle(id: 'chest', name: 'Chest'))
      ..exercises.add(
        Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
      );

    final workout = Workout(
      id: 'w-1',
      performedAt: DateTime.utc(2026, 8, 25, 10, 0),
      exercises: [
        WorkoutExercise(
          id: 'we-1',
          exerciseId: 'bench-press',
          sets: [WorkoutSet(id: 's-1', weight: 60, repetitions: 10)],
        ),
      ],
    );
    repository.workouts.add(workout);

    await tester.pumpWidget(GymProgressionApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Workout history'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Bench Press'), findsOneWidget);

    // Tap delete on the item
    await tester.tap(find.byTooltip('Delete workout'));
    await tester.pumpAndSettle();

    // Confirm Delete
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No workout history yet.'), findsOneWidget);
    expect(repository.workouts, isEmpty);
  });

  testWidgets(
    'displays training plan on home screen and allows switching plans',
    (tester) async {
      final repository = _MemoryGymRepository()
        ..muscles.add(Muscle(id: 'chest', name: 'Chest'))
        ..exercises.add(
          Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
        );

      await tester.pumpWidget(GymProgressionApp(repository: repository));
      await tester.pumpAndSettle();

      // Verify current training plan card is displayed on home page
      expect(find.text('3-Day Split (Personalized)'), findsOneWidget);
      expect(find.text('Active Training Schedule'), findsOneWidget);
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Shoulders • Quadriceps • Hamstrings'), findsOneWidget);

      // Tap Plans button to open suggested training plans sheet
      await tester.tap(find.widgetWithText(TextButton, 'Plans'));
      await tester.pumpAndSettle();

      expect(find.text('Training Plans'), findsOneWidget);
      expect(
        find.text('Choose a routine or explore suggestions'),
        findsOneWidget,
      );
      // Scroll down inside bottom sheet to PPL split button and tap
      final pplButton = find.byKey(const Key('select-plan-ppl-split'));
      await tester.dragUntilVisible(
        pplButton,
        find.byType(ListView).last,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(pplButton);
      await tester.pumpAndSettle();

      // Verify the home page updated to the new plan
      expect(find.text('Push / Pull / Legs (PPL)'), findsOneWidget);
      expect(find.text('Chest • Shoulders • Triceps'), findsOneWidget);
      expect(find.text('Back • Biceps'), findsOneWidget);
    },
  );
}

class _MemoryGymRepository implements GymRepository {
  final List<Muscle> muscles = [];
  final List<Exercise> exercises = [];
  final List<Workout> workouts = [];

  @override
  Future<void> deleteExercise(String exerciseId) async {
    exercises.removeWhere((exercise) => exercise.id == exerciseId);
  }

  @override
  Future<void> deleteWorkout(String workoutId) async {
    workouts.removeWhere((workout) => workout.id == workoutId);
  }

  @override
  Future<List<Exercise>> getExercises({String? muscleId}) async {
    return exercises
        .where((exercise) => muscleId == null || exercise.muscleId == muscleId)
        .toList(growable: false);
  }

  @override
  Future<List<Muscle>> getMuscles() async => List.unmodifiable(muscles);

  @override
  Future<List<Workout>> getWorkouts({String? exerciseId}) async {
    final list =
        workouts
            .where(
              (w) =>
                  exerciseId == null ||
                  w.exercises.any((we) => we.exerciseId == exerciseId),
            )
            .toList(growable: false)
          ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return List.unmodifiable(list);
  }

  @override
  Future<void> saveExercise(Exercise exercise) async {
    exercises.add(exercise);
  }

  @override
  Future<void> saveMuscle(Muscle muscle) async {
    muscles.add(muscle);
  }

  @override
  Future<void> saveWorkout(Workout workout) async {
    workouts.add(workout);
  }

  @override
  Future<void> updateWorkout(Workout workout) async {
    final index = workouts.indexWhere((item) => item.id == workout.id);
    if (index < 0) {
      throw StateError('Workout ${workout.id} does not exist.');
    }
    workouts[index] = workout;
  }

  @override
  Future<void> updateExercise(Exercise exercise) async {
    final index = exercises.indexWhere((item) => item.id == exercise.id);
    exercises[index] = exercise;
  }

  @override
  Future<WorkoutExercise?> getLatestWorkoutExercise(
    String exerciseId, {
    String? excludingWorkoutId,
  }) async {
    final sortedWorkouts =
        workouts
            .where(
              (w) => excludingWorkoutId == null || w.id != excludingWorkoutId,
            )
            .toList(growable: false)
          ..sort((a, b) => b.performedAt.compareTo(a.performedAt));

    for (final workout in sortedWorkouts) {
      for (final we in workout.exercises) {
        if (we.exerciseId == exerciseId && we.sets.isNotEmpty) {
          return we;
        }
      }
    }
    return null;
  }
}
