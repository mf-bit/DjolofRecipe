import 'workout_exercise.dart';

/// A training session performed at [performedAt].
class Workout {
  Workout({
    required String id,
    required this.performedAt,
    required List<WorkoutExercise> exercises,
  }) : id = _requiredText(id, 'id'),
       exercises = List.unmodifiable(exercises);

  final String id;
  final DateTime performedAt;
  final List<WorkoutExercise> exercises;

  static String _requiredText(String value, String fieldName) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      throw ArgumentError.value(value, fieldName, 'must not be empty');
    }
    return trimmedValue;
  }
}
