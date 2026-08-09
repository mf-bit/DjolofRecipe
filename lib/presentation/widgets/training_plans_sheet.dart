import 'package:flutter/material.dart';

import '../../domain/models/training_plan.dart';

/// Predefined training plans including user requested split and standard options.
final List<TrainingPlan> defaultTrainingPlans = [
  const TrainingPlan(
    id: 'three-day-custom-split',
    name: '3-Day Split (Personalized)',
    description: 'Balanced 3-day weekly routine with targeted muscle focus.',
    sessionsPerWeek: 3,
    days: [
      TrainingPlanDay(
        dayName: 'Monday',
        targetMuscleNames: ['Shoulders', 'Quadriceps', 'Hamstrings'],
        description: 'Shoulders & Lower Body',
      ),
      TrainingPlanDay(
        dayName: 'Thursday',
        targetMuscleNames: ['Biceps', 'Back'],
        description: 'Back & Biceps Pull Focus',
      ),
      TrainingPlanDay(
        dayName: 'Saturday',
        targetMuscleNames: ['Chest', 'Triceps'],
        description: 'Chest & Triceps Push Focus',
      ),
    ],
  ),
  const TrainingPlan(
    id: 'ppl-split',
    name: 'Push / Pull / Legs (PPL)',
    description: 'Classic hypertrophy and strength split 3 to 6 times a week.',
    sessionsPerWeek: 3,
    days: [
      TrainingPlanDay(
        dayName: 'Tuesday',
        targetMuscleNames: ['Chest', 'Shoulders', 'Triceps'],
        description: 'Push: Chest, Shoulders & Triceps',
      ),
      TrainingPlanDay(
        dayName: 'Thursday',
        targetMuscleNames: ['Back', 'Biceps'],
        description: 'Pull: Back & Biceps',
      ),
      TrainingPlanDay(
        dayName: 'Sunday',
        targetMuscleNames: ['Quadriceps', 'Hamstrings'],
        description: 'Legs: Quadriceps & Hamstrings',
      ),
    ],
  ),
  const TrainingPlan(
    id: 'upper-lower-split',
    name: 'Upper / Lower Body Split',
    description: 'High-frequency 4-day split for balanced body development.',
    sessionsPerWeek: 4,
    days: [
      TrainingPlanDay(
        dayName: 'Monday',
        targetMuscleNames: ['Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps'],
        description: 'Upper Body Power',
      ),
      TrainingPlanDay(
        dayName: 'Tuesday',
        targetMuscleNames: ['Quadriceps', 'Hamstrings'],
        description: 'Lower Body Strength',
      ),
      TrainingPlanDay(
        dayName: 'Thursday',
        targetMuscleNames: ['Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps'],
        description: 'Upper Body Hypertrophy',
      ),
      TrainingPlanDay(
        dayName: 'Friday',
        targetMuscleNames: ['Quadriceps', 'Hamstrings'],
        description: 'Lower Body & Core',
      ),
    ],
  ),
  const TrainingPlan(
    id: 'full-body-split',
    name: 'Full Body 3x / Week',
    description:
        'Total body stimulation every workout with rest days in between.',
    sessionsPerWeek: 3,
    days: [
      TrainingPlanDay(
        dayName: 'Monday',
        targetMuscleNames: ['Chest', 'Back', 'Quadriceps'],
        description: 'Full Body Session A',
      ),
      TrainingPlanDay(
        dayName: 'Wednesday',
        targetMuscleNames: ['Shoulders', 'Hamstrings', 'Biceps'],
        description: 'Full Body Session B',
      ),
      TrainingPlanDay(
        dayName: 'Friday',
        targetMuscleNames: ['Chest', 'Back', 'Triceps', 'Quadriceps'],
        description: 'Full Body Session C',
      ),
    ],
  ),
];

/// Modal bottom sheet allowing users to view current plan details,
/// explore alternative suggested plans, and select their active plan.
class TrainingPlansSheet extends StatelessWidget {
  const TrainingPlansSheet({
    super.key,
    required this.currentPlanId,
    required this.onSelectPlan,
  });

  final String currentPlanId;
  final ValueChanged<TrainingPlan> onSelectPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141C18) : const Color(0xFFFBF8F2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 14, bottom: 10),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFD6CFC1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Training Plans',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Choose a routine or explore suggestions',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(18),
                  itemCount: defaultTrainingPlans.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final plan = defaultTrainingPlans[index];
                    final isSelected = plan.id == currentPlanId;

                    return _TrainingPlanCard(
                      plan: plan,
                      isSelected: isSelected,
                      onSelect: () {
                        onSelectPlan(plan);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrainingPlanCard extends StatelessWidget {
  const _TrainingPlanCard({
    required this.plan,
    required this.isSelected,
    required this.onSelect,
  });

  final TrainingPlan plan;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? (isSelected ? const Color(0xFF223028) : const Color(0xFF1B241F))
            : (isSelected ? const Color(0xFFF4FAF6) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : (isDark ? const Color(0xFF2A3830) : const Color(0xFFEBE5D8)),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 8),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              plan.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isSelected ? colorScheme.primary : null,
                              ),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${plan.sessionsPerWeek} sessions per week • ${plan.description}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Days split schedule
            ...plan.days.map((day) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 84,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF28362E)
                            : const Color(0xFFF3EEE3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        day.dayName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: day.targetMuscleNames.map((muscle) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withAlpha(
                                    120,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  muscle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (day.description != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              day.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: isSelected
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Current Plan'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    )
                  : FilledButton.icon(
                      key: Key('select-plan-${plan.id}'),
                      onPressed: onSelect,
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                      ),
                      label: const Text('Set as Active Plan'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
