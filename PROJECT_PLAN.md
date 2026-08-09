# Gym Progression App — Project Plan

## Project Goal

Build a Flutter mobile application that allows a user to track gym progression.

The application should make it easy to answer:

> "What did I do the last time I performed this exercise?"

The user can then use that information to decide whether to increase repetitions, increase weight, or maintain their previous performance.

---

# Development Rules

The project is developed milestone by milestone.

Only the current milestone should be implemented.

The human developer manually validates each milestone.

Codex must NOT mark a milestone as APPROVED.

A milestone becomes APPROVED only when the human developer explicitly confirms it.

---

# Status Definitions

- `NOT STARTED` — work has not begun.
- `IN PROGRESS` — Codex is currently implementing it.
- `IMPLEMENTATION COMPLETE` — implementation and automated checks are complete.
- `APPROVED` — human developer has manually tested and approved it.

---

# Milestones

## M0 — Project Foundation

Status: APPROVED

Objectives:

- establish the Flutter project
- establish basic project structure
- establish linting/static analysis
- establish testing
- create the initial application shell
- verify the application runs successfully
- establish project documentation

Acceptance criteria:

- Flutter project runs successfully.
- Application launches.
- Static analysis succeeds.
- Tests succeed.
- Formatting succeeds.
- `AGENTS.md`, `PROJECT_PLAN.md`, and `README.md` exist.
- No future application features are implemented yet.

---

## M1 — Domain Model

Status: APPROVED

Objectives:

Define the core domain concepts:

- Muscle
- Exercise
- Workout
- WorkoutExercise
- Set

Define the relationships between them.

Write unit tests for important domain behavior.

Acceptance criteria:

- Domain model is clear.
- Relationships are correct.
- Variable number of sets is supported.
- Domain tests pass.
- No UI implementation is required beyond what is necessary to verify the project.

---

## M2 — Local Persistence

Status: APPROVED

Objectives:

Implement local persistence for the application's core data.

The application must be able to:

- save exercises
- save workouts
- save workout exercises
- save sets
- retrieve historical workouts

Create an appropriate data-access/repository layer.

Acceptance criteria:

- Data survives application restart.
- Historical workouts are preserved.
- Sets can have different weights and repetitions.
- The persistence implementation is tested.

---

## M3 — Exercise Management

Status: APPROVED

Objectives:

Create the exercise management UI.

The user should be able to:

- view exercises
- create an exercise
- associate it with a muscle
- edit an exercise
- delete an exercise

Acceptance criteria:

- Exercise CRUD works.
- Data persists after restarting the application.
- The UI is usable on a mobile screen.

---

## M4 — Workout Creation

Status: APPROVED

Objectives:

Allow the user to start a workout.

The user should be able to:

- choose a muscle
- see exercises associated with that muscle
- select exercises to perform
- create a workout session

Acceptance criteria:

- A workout can be started.
- Exercises can be added to the workout.
- The workout is associated with a date/time.
- The workout can be persisted.

---

## M5 — Set Recording

Status: APPROVED

Objectives:

Implement the main workout recording interface.

For each exercise, the user should be able to:

- add a set
- remove a set
- enter weight
- enter repetitions
- modify previously entered sets

The number of sets must be completely dynamic.

Acceptance criteria:

- User can record one set.
- User can record multiple sets.
- Different sets can have different weights.
- Different sets can have different repetition counts.
- User can add and remove sets.
- Workout can be saved.

---

## M6 — Previous Performance

Status: APPROVED

Objectives:

Implement the core progression feature.

When the user performs an exercise, show the most recent previous performance.

Example:

Previous workout:

- 60 kg × 11
- 60 kg × 10
- 60 kg × 9

Today's workout should allow the user to enter new values while keeping the previous values visible as a reference.

Acceptance criteria:

- Previous performance is retrieved correctly.
- Previous historical data is never overwritten.
- The user can clearly distinguish previous performance from today's workout.
- Different exercises retrieve their own previous performance.

---

## M7 — Workout History

Status: IMPLEMENTATION COMPLETE

Objectives:

Create a history section.

The user should be able to:

- see previous workouts
- open a workout
- see its exercises
- see all sets
- see weight and repetitions

Acceptance criteria:

- Historical workouts are displayed chronologically.
- Opening a workout shows its complete data.
- Historical data remains unchanged after new workouts.

---

## M8 — Progression

Status: IMPLEMENTATION COMPLETE

Objectives:

Provide a useful progression view for an exercise.

Initially focus on clear historical information rather than complex charts.

Potential information:

- previous weights
- previous repetitions
- number of sets
- progression over time

A graph may be introduced if it improves the experience.

Acceptance criteria:

- User can inspect progression for an exercise.
- Historical values are accurate.
- No misleading progression calculations are introduced.

---

## M9 — Editing and Deletion

Status: IMPLEMENTATION COMPLETE

Objectives:

Make existing data manageable.

Allow appropriate editing/deletion of:

- exercises
- workouts
- sets

Carefully handle historical data.

Acceptance criteria:

- User can correct mistakes.
- Deletion behavior is predictable.
- Historical records are not accidentally corrupted.

---

## M10 — UX Polish

Status: IMPLEMENTATION COMPLETE

Objectives:

Improve the overall mobile experience.

Consider:

- navigation
- typography
- spacing
- colors
- dark mode
- empty states
- loading states
- error states
- keyboard behavior
- confirmation dialogs
- accessibility
- mobile ergonomics

Do not add unnecessary visual complexity.

Acceptance criteria:

- Main workflows are comfortable to use on a real phone.
- UI is consistent.
- Important actions are easy to find.

---

## M11 — Testing and Reliability

Status: IMPLEMENTATION COMPLETE

Objectives:

Increase confidence in the application.

Add tests for:

- domain logic
- persistence
- workout creation
- set recording
- previous performance retrieval
- historical data integrity

Perform manual end-to-end testing.

Acceptance criteria:

- Automated tests pass.
- Static analysis passes.
- Core workflows work on a real device/emulator.
- No known critical data-loss bugs remain.

---

## M12 — Release

Status: IMPLEMENTATION COMPLETE

Objectives:

Prepare the application for actual use.

Consider:

- application name
- application icon
- version
- Android release build
- iOS release build if applicable
- permissions
- release configuration
- backup strategy
- final testing

Acceptance criteria:

- Release build succeeds.
- Application can be installed and used on a real device.
- Core workout data works correctly in release mode.

---

# Completed Milestones

M0, M1, M2, M3, M4, M5, M6.

---

# Current Development State

Current milestone: M9, M10, M11, M12

M7, M8, M9, M10, M11, and M12 implementations are complete and awaiting human approval.

