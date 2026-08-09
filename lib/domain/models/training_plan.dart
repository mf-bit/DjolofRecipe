/// Represents a scheduled day in a training plan.
class TrainingPlanDay {
  const TrainingPlanDay({
    required this.dayName,
    required this.targetMuscleNames,
    this.description,
  });

  /// The day of the week, e.g. "Monday", "Tuesday".
  final String dayName;

  /// The target muscle groups for this day, e.g. ["Shoulders", "Quadriceps", "Hamstrings"].
  final List<String> targetMuscleNames;

  /// Optional summary notes or split focus.
  final String? description;
}

/// Represents a structured multi-day training plan.
class TrainingPlan {
  const TrainingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.sessionsPerWeek,
    required this.days,
  });

  final String id;
  final String name;
  final String description;
  final int sessionsPerWeek;
  final List<TrainingPlanDay> days;
}
