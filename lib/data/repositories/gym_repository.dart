import '../../domain/domain.dart';

/// Local storage operations for the application's core data.
abstract interface class GymRepository {
  Future<void> saveMuscle(Muscle muscle);

  Future<List<Muscle>> getMuscles();

  Future<void> saveExercise(Exercise exercise);

  Future<void> updateExercise(Exercise exercise);

  Future<void> deleteExercise(String exerciseId);

  Future<List<Exercise>> getExercises({String? muscleId});

  /// Saves a new workout snapshot without replacing existing history.
  Future<void> saveWorkout(Workout workout);

  /// Updates an existing workout's exercises and sets in place.
  Future<void> updateWorkout(Workout workout);

  /// Deletes a workout and its associated exercises and sets.
  Future<void> deleteWorkout(String workoutId);

  /// Returns the most recent workout exercise for [exerciseId],
  /// optionally excluding [excludingWorkoutId].
  Future<WorkoutExercise?> getLatestWorkoutExercise(
    String exerciseId, {
    String? excludingWorkoutId,
  });

  /// Returns workouts from newest to oldest, optionally filtered by [exerciseId],
  /// including exercises and sets.
  Future<List<Workout>> getWorkouts({String? exerciseId});
}
