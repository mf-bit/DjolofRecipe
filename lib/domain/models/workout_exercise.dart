import 'workout_set.dart';

/// An [Exercise] performed as part of a workout.
class WorkoutExercise {
  WorkoutExercise({
    required String id,
    required String exerciseId,
    required List<WorkoutSet> sets,
  }) : id = _requiredText(id, 'id'),
       exerciseId = _requiredText(exerciseId, 'exerciseId'),
       sets = List.unmodifiable(sets);

  final String id;
  final String exerciseId;
  final List<WorkoutSet> sets;

  static String _requiredText(String value, String fieldName) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      throw ArgumentError.value(value, fieldName, 'must not be empty');
    }
    return trimmedValue;
  }
}
