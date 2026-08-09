/// A muscle or muscle group to which exercises can belong.
class Muscle {
  Muscle({required String id, required String name})
    : id = _requiredText(id, 'id'),
      name = _requiredText(name, 'name');

  final String id;
  final String name;

  static String _requiredText(String value, String fieldName) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      throw ArgumentError.value(value, fieldName, 'must not be empty');
    }
    return trimmedValue;
  }
}
