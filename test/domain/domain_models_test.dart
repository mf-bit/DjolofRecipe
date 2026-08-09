import 'package:flutter_test/flutter_test.dart';
import 'package:gym_progression/domain/domain.dart';

void main() {
  test('exercise is associated with a muscle by its ID', () {
    final muscle = Muscle(id: 'chest', name: 'Chest');
    final exercise = Exercise(
      id: 'bench-press',
      name: 'Bench Press',
      muscleId: muscle.id,
    );

    expect(exercise.muscleId, muscle.id);
  });

  test('workout retains its performed exercises and their sets', () {
    final workoutSet = WorkoutSet(id: 'set-1', weight: 60, repetitions: 10);
    final workoutExercise = WorkoutExercise(
      id: 'workout-exercise-1',
      exerciseId: 'bench-press',
      sets: [workoutSet],
    );
    final performedAt = DateTime.utc(2026, 8, 25);
    final workout = Workout(
      id: 'workout-1',
      performedAt: performedAt,
      exercises: [workoutExercise],
    );

    expect(workout.performedAt, performedAt);
    expect(workout.exercises.single.exerciseId, 'bench-press');
    expect(workout.exercises.single.sets.single.repetitions, 10);
  });

  test('workout exercises support a variable number of sets', () {
    final sets = [
      WorkoutSet(id: 'set-1', weight: 60, repetitions: 10),
      WorkoutSet(id: 'set-2', weight: 60, repetitions: 9),
      WorkoutSet(id: 'set-3', weight: 62.5, repetitions: 8),
      WorkoutSet(id: 'set-4', weight: 62.5, repetitions: 7),
    ];
    final workoutExercise = WorkoutExercise(
      id: 'workout-exercise-1',
      exerciseId: 'bench-press',
      sets: sets,
    );

    expect(workoutExercise.sets, hasLength(4));
  });

  test(
    'workout model snapshots cannot be mutated through collection fields',
    () {
      final sets = [WorkoutSet(id: 'set-1', weight: 60, repetitions: 10)];
      final workoutExercise = WorkoutExercise(
        id: 'workout-exercise-1',
        exerciseId: 'bench-press',
        sets: sets,
      );
      final exercises = [workoutExercise];
      final workout = Workout(
        id: 'workout-1',
        performedAt: DateTime.utc(2026, 8, 25),
        exercises: exercises,
      );

      sets.add(WorkoutSet(id: 'set-2', weight: 60, repetitions: 9));
      exercises.clear();

      expect(workout.exercises, hasLength(1));
      expect(workout.exercises.single.sets, hasLength(1));
      expect(
        () => workout.exercises.add(workoutExercise),
        throwsUnsupportedError,
      );
    },
  );

  test('sets reject invalid recorded values', () {
    expect(
      () => WorkoutSet(id: 'set-1', weight: -1, repetitions: 10),
      throwsArgumentError,
    );
    expect(
      () => WorkoutSet(id: 'set-1', weight: 60, repetitions: 0),
      throwsArgumentError,
    );
  });

  test('training plan contains structured days with target muscles', () {
    const plan = TrainingPlan(
      id: 'custom-plan',
      name: 'Custom Split',
      description: '3-day split',
      sessionsPerWeek: 3,
      days: [
        TrainingPlanDay(
          dayName: 'Monday',
          targetMuscleNames: ['Shoulders', 'Quadriceps'],
          description: 'Upper/Lower mix',
        ),
      ],
    );

    expect(plan.name, 'Custom Split');
    expect(plan.sessionsPerWeek, 3);
    expect(plan.days.single.dayName, 'Monday');
    expect(plan.days.single.targetMuscleNames, ['Shoulders', 'Quadriceps']);
  });
}
