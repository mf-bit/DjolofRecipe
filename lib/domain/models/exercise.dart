/// An exercise associated with a [Muscle] through [muscleId].
class Exercise {
  Exercise({required String id, required String name, required String muscleId})
    : id = _requiredText(id, 'id'),
      name = _requiredText(name, 'name'),
      muscleId = _requiredText(muscleId, 'muscleId');

  final String id;
  final String name;
  final String muscleId;

  static String _requiredText(String value, String fieldName) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      throw ArgumentError.value(value, fieldName, 'must not be empty');
    }
    return trimmedValue;
  }
}
