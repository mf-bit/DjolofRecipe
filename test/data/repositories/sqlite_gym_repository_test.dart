import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_progression/data/data.dart';
import 'package:gym_progression/domain/domain.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory databaseDirectory;
  late String databasePath;
  late SqliteGymRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseDirectory = await Directory.systemTemp.createTemp(
      'gym_progression_repository_test_',
    );
    databasePath = '${databaseDirectory.path}/gym_progression.db';
    repository = await _openRepository(databasePath);
  });

  tearDown(() async {
    await repository.close();
    await databaseDirectory.delete(recursive: true);
  });

  test('persists core data across a repository restart', () async {
    await _saveBenchPress(repository);
    await repository.close();
    repository = await _openRepository(databasePath);

    final muscles = await repository.getMuscles();
    final exercises = await repository.getExercises(muscleId: 'chest');
    final workouts = await repository.getWorkouts();

    expect(muscles.map((item) => item.id), ['chest']);
    expect(exercises.map((item) => item.id), ['bench-press']);
    expect(workouts.single.id, 'workout-1');
    expect(workouts.single.exercises.single.sets, hasLength(2));
  });

  test('preserves historical workouts with their distinct sets', () async {
    await _saveBenchPress(repository);
    final secondWorkout = Workout(
      id: 'workout-2',
      performedAt: DateTime.utc(2026, 8, 26),
      exercises: [
        WorkoutExercise(
          id: 'workout-exercise-2',
          exerciseId: 'bench-press',
          sets: [
            WorkoutSet(id: 'set-3', weight: 62.5, repetitions: 8),
            WorkoutSet(id: 'set-4', weight: 62.5, repetitions: 7),
          ],
        ),
      ],
    );
    await repository.saveWorkout(secondWorkout);

    final workouts = await repository.getWorkouts();

    expect(workouts.map((workout) => workout.id), ['workout-2', 'workout-1']);
    expect(workouts.last.exercises.single.sets[0].weight, 60);
    expect(workouts.last.exercises.single.sets[1].repetitions, 9);
    expect(workouts.first.exercises.single.sets[0].weight, 62.5);
    expect(workouts.first.exercises.single.sets[1].repetitions, 7);
  });

  test('does not overwrite an existing workout', () async {
    await _saveBenchPress(repository);

    await expectLater(
      () => repository.saveWorkout(
        Workout(
          id: 'workout-1',
          performedAt: DateTime.utc(2026, 8, 26),
          exercises: const [],
        ),
      ),
      throwsA(isA<DatabaseException>()),
    );

    final workouts = await repository.getWorkouts();
    expect(workouts, hasLength(1));
    expect(workouts.single.exercises.single.sets.first.weight, 60);
  });

  test('updates and deletes an exercise without workout history', () async {
    await repository.saveMuscle(Muscle(id: 'legs', name: 'Legs'));
    await repository.saveExercise(
      Exercise(id: 'squat', name: 'Squat', muscleId: 'legs'),
    );

    await repository.updateExercise(
      Exercise(id: 'squat', name: 'Barbell Squat', muscleId: 'legs'),
    );
    expect((await repository.getExercises()).single.name, 'Barbell Squat');

    await repository.deleteExercise('squat');
    expect(await repository.getExercises(), isEmpty);
  });

  test('does not delete an exercise with workout history', () async {
    await _saveBenchPress(repository);

    await expectLater(
      () => repository.deleteExercise('bench-press'),
      throwsA(isA<DatabaseException>()),
    );

    expect((await repository.getExercises()).single.id, 'bench-press');
  });

  test('persists a started workout before sets are recorded', () async {
    await repository.saveMuscle(Muscle(id: 'chest', name: 'Chest'));
    await repository.saveExercise(
      Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
    );
    final performedAt = DateTime.utc(2026, 8, 25, 10, 30);
    await repository.saveWorkout(
      Workout(
        id: 'workout-1',
        performedAt: performedAt,
        exercises: [
          WorkoutExercise(
            id: 'workout-exercise-1',
            exerciseId: 'bench-press',
            sets: const [],
          ),
        ],
      ),
    );

    final workout = (await repository.getWorkouts()).single;
    expect(workout.performedAt, performedAt);
    expect(workout.exercises.single.exerciseId, 'bench-press');
    expect(workout.exercises.single.sets, isEmpty);
  });

  test('updates an existing workout with new sets', () async {
    await repository.saveMuscle(Muscle(id: 'chest', name: 'Chest'));
    await repository.saveExercise(
      Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
    );

    // Save a workout with no sets (as created by M4).
    await repository.saveWorkout(
      Workout(
        id: 'workout-1',
        performedAt: DateTime.utc(2026, 8, 25, 10, 30),
        exercises: [
          WorkoutExercise(
            id: 'we-1',
            exerciseId: 'bench-press',
            sets: const [],
          ),
        ],
      ),
    );

    // Update with recorded sets.
    await repository.updateWorkout(
      Workout(
        id: 'workout-1',
        performedAt: DateTime.utc(2026, 8, 25, 10, 30),
        exercises: [
          WorkoutExercise(
            id: 'we-1',
            exerciseId: 'bench-press',
            sets: [
              WorkoutSet(id: 'set-1', weight: 60, repetitions: 10),
              WorkoutSet(id: 'set-2', weight: 62.5, repetitions: 8),
            ],
          ),
        ],
      ),
    );

    final workouts = await repository.getWorkouts();
    expect(workouts, hasLength(1));
    final sets = workouts.single.exercises.single.sets;
    expect(sets, hasLength(2));
    expect(sets[0].weight, 60);
    expect(sets[0].repetitions, 10);
    expect(sets[1].weight, 62.5);
    expect(sets[1].repetitions, 8);
  });

  test('updateWorkout does not affect other workouts', () async {
    await _saveBenchPress(repository);

    // Save a second workout.
    await repository.saveWorkout(
      Workout(
        id: 'workout-2',
        performedAt: DateTime.utc(2026, 8, 26),
        exercises: [
          WorkoutExercise(
            id: 'we-2',
            exerciseId: 'bench-press',
            sets: const [],
          ),
        ],
      ),
    );

    // Update only the second workout.
    await repository.updateWorkout(
      Workout(
        id: 'workout-2',
        performedAt: DateTime.utc(2026, 8, 26),
        exercises: [
          WorkoutExercise(
            id: 'we-2',
            exerciseId: 'bench-press',
            sets: [WorkoutSet(id: 'set-3', weight: 65, repetitions: 6)],
          ),
        ],
      ),
    );

    final workouts = await repository.getWorkouts();
    expect(workouts, hasLength(2));

    // First workout (newest) is workout-2.
    final updatedWorkout = workouts.first;
    expect(updatedWorkout.id, 'workout-2');
    expect(updatedWorkout.exercises.single.sets, hasLength(1));
    expect(updatedWorkout.exercises.single.sets[0].weight, 65);

    // Original workout is unchanged.
    final originalWorkout = workouts.last;
    expect(originalWorkout.id, 'workout-1');
    expect(originalWorkout.exercises.single.sets, hasLength(2));
    expect(originalWorkout.exercises.single.sets[0].weight, 60);
  });

  test('updateWorkout throws for a non-existent workout', () async {
    await expectLater(
      () => repository.updateWorkout(
        Workout(
          id: 'does-not-exist',
          performedAt: DateTime.utc(2026, 8, 25),
          exercises: const [],
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('deletes a workout and preserves other workouts', () async {
    await _saveBenchPress(repository);

    // Save a second workout
    await repository.saveWorkout(
      Workout(
        id: 'workout-2',
        performedAt: DateTime.utc(2026, 8, 26),
        exercises: [
          WorkoutExercise(
            id: 'we-2',
            exerciseId: 'bench-press',
            sets: [WorkoutSet(id: 's-3', weight: 65, repetitions: 5)],
          ),
        ],
      ),
    );

    expect(await repository.getWorkouts(), hasLength(2));

    // Delete the first workout
    await repository.deleteWorkout('workout-1');

    final remaining = await repository.getWorkouts();
    expect(remaining, hasLength(1));
    expect(remaining.single.id, 'workout-2');
    expect(remaining.single.exercises.single.sets.single.weight, 65);
  });

  test('deleteWorkout throws for a non-existent workout', () async {
    await expectLater(
      () => repository.deleteWorkout('does-not-exist'),
      throwsA(isA<StateError>()),
    );
  });

  test('retrieves previous performance for specific exercises', () async {
    await repository.saveMuscle(Muscle(id: 'chest', name: 'Chest'));
    await repository.saveMuscle(Muscle(id: 'back', name: 'Back'));
    await repository.saveExercise(
      Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
    );
    await repository.saveExercise(
      Exercise(id: 'barbell-row', name: 'Barbell Row', muscleId: 'back'),
    );

    // Workout 1: Bench Press on day 1
    await repository.saveWorkout(
      Workout(
        id: 'workout-1',
        performedAt: DateTime.utc(2026, 8, 20),
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
      ),
    );

    // Workout 2: Barbell Row on day 2
    await repository.saveWorkout(
      Workout(
        id: 'workout-2',
        performedAt: DateTime.utc(2026, 8, 22),
        exercises: [
          WorkoutExercise(
            id: 'we-2',
            exerciseId: 'barbell-row',
            sets: [WorkoutSet(id: 's-3', weight: 50, repetitions: 12)],
          ),
        ],
      ),
    );

    // Workout 3: Bench Press on day 3 with higher weight
    await repository.saveWorkout(
      Workout(
        id: 'workout-3',
        performedAt: DateTime.utc(2026, 8, 24),
        exercises: [
          WorkoutExercise(
            id: 'we-3',
            exerciseId: 'bench-press',
            sets: [
              WorkoutSet(id: 's-4', weight: 62.5, repetitions: 10),
              WorkoutSet(id: 's-5', weight: 62.5, repetitions: 8),
            ],
          ),
        ],
      ),
    );

    // Should retrieve the latest bench press (from workout-3)
    final latestBench = await repository.getLatestWorkoutExercise(
      'bench-press',
    );
    expect(latestBench, isNotNull);
    expect(latestBench!.sets, hasLength(2));
    expect(latestBench.sets[0].weight, 62.5);
    expect(latestBench.sets[0].repetitions, 10);

    // When excluding workout-3, should retrieve workout-1's bench press
    final prevBench = await repository.getLatestWorkoutExercise(
      'bench-press',
      excludingWorkoutId: 'workout-3',
    );
    expect(prevBench, isNotNull);
    expect(prevBench!.sets, hasLength(2));
    expect(prevBench.sets[0].weight, 60);

    // Barbell row retrieves its own history
    final latestRow = await repository.getLatestWorkoutExercise('barbell-row');
    expect(latestRow, isNotNull);
    expect(latestRow!.sets, hasLength(1));
    expect(latestRow.sets[0].weight, 50);

    // Non-performed exercise returns null
    final noHistory = await repository.getLatestWorkoutExercise('squat');
    expect(noHistory, isNull);
  });

  test('getLatestWorkoutExercise ignores workouts with no sets', () async {
    await repository.saveMuscle(Muscle(id: 'chest', name: 'Chest'));
    await repository.saveExercise(
      Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
    );

    // Workout 1 has sets
    await repository.saveWorkout(
      Workout(
        id: 'workout-1',
        performedAt: DateTime.utc(2026, 8, 20),
        exercises: [
          WorkoutExercise(
            id: 'we-1',
            exerciseId: 'bench-press',
            sets: [WorkoutSet(id: 's-1', weight: 60, repetitions: 10)],
          ),
        ],
      ),
    );

    // Workout 2 is started but has no sets
    await repository.saveWorkout(
      Workout(
        id: 'workout-2',
        performedAt: DateTime.utc(2026, 8, 22),
        exercises: [
          WorkoutExercise(
            id: 'we-2',
            exerciseId: 'bench-press',
            sets: const [],
          ),
        ],
      ),
    );

    final latest = await repository.getLatestWorkoutExercise('bench-press');
    expect(latest, isNotNull);
    expect(latest!.id, 'we-1');
    expect(latest.sets.single.weight, 60);
  });

  test('filters workouts by exerciseId', () async {
    await repository.saveMuscle(Muscle(id: 'chest', name: 'Chest'));
    await repository.saveMuscle(Muscle(id: 'back', name: 'Back'));
    await repository.saveExercise(
      Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
    );
    await repository.saveExercise(
      Exercise(id: 'barbell-row', name: 'Barbell Row', muscleId: 'back'),
    );

    await repository.saveWorkout(
      Workout(
        id: 'w-1',
        performedAt: DateTime.utc(2026, 8, 20),
        exercises: [
          WorkoutExercise(
            id: 'we-1',
            exerciseId: 'bench-press',
            sets: [WorkoutSet(id: 's-1', weight: 60, repetitions: 10)],
          ),
        ],
      ),
    );

    await repository.saveWorkout(
      Workout(
        id: 'w-2',
        performedAt: DateTime.utc(2026, 8, 22),
        exercises: [
          WorkoutExercise(
            id: 'we-2',
            exerciseId: 'barbell-row',
            sets: [WorkoutSet(id: 's-2', weight: 50, repetitions: 12)],
          ),
        ],
      ),
    );

    final benchWorkouts = await repository.getWorkouts(
      exerciseId: 'bench-press',
    );
    expect(benchWorkouts.map((w) => w.id), ['w-1']);

    final rowWorkouts = await repository.getWorkouts(exerciseId: 'barbell-row');
    expect(rowWorkouts.map((w) => w.id), ['w-2']);

    final allWorkouts = await repository.getWorkouts();
    expect(allWorkouts.map((w) => w.id), ['w-2', 'w-1']);
  });
}

Future<SqliteGymRepository> _openRepository(String databasePath) {
  return SqliteGymRepository.open(
    factory: databaseFactoryFfi,
    databasePath: databasePath,
  );
}

Future<void> _saveBenchPress(SqliteGymRepository repository) async {
  await repository.saveMuscle(Muscle(id: 'chest', name: 'Chest'));
  await repository.saveExercise(
    Exercise(id: 'bench-press', name: 'Bench Press', muscleId: 'chest'),
  );
  await repository.saveWorkout(
    Workout(
      id: 'workout-1',
      performedAt: DateTime.utc(2026, 8, 25),
      exercises: [
        WorkoutExercise(
          id: 'workout-exercise-1',
          exerciseId: 'bench-press',
          sets: [
            WorkoutSet(id: 'set-1', weight: 60, repetitions: 10),
            WorkoutSet(id: 'set-2', weight: 60, repetitions: 9),
          ],
        ),
      ],
    ),
  );
}
