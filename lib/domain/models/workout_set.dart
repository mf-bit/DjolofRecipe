/// One performed set, containing its weight and repetitions.
class WorkoutSet {
  WorkoutSet({
    required String id,
    required this.weight,
    required this.repetitions,
  }) : id = _requiredText(id, 'id') {
    if (!weight.isFinite || weight < 0) {
      throw ArgumentError.value(
        weight,
        'weight',
        'must be a finite value >= 0',
      );
    }
    if (repetitions <= 0) {
      throw ArgumentError.value(
        repetitions,
        'repetitions',
        'must be greater than 0',
      );
    }
  }

  final String id;
  final double weight;
  final int repetitions;

  static String _requiredText(String value, String fieldName) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      throw ArgumentError.value(value, fieldName, 'must not be empty');
    }
    return trimmedValue;
  }
}
