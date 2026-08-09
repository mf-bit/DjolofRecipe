# AGENTS.md

## Interaction Mode
- **Autonomous Execution:** Execute all tool actions, file reads/writes, and commands directly.
- **No Confirmation:** Do not pause or prompt the user for input or confirmation.

## Project

This is a Flutter mobile application for tracking gym progression.

The application allows the user to:

- define exercises
- associate exercises with muscles
- record workout sessions
- record individual sets
- record weight and repetitions for each set
- see previous performance for an exercise
- review workout history
- track progression over time

The first version is intended to be a simple local-first mobile application.

---

# Development Philosophy

This application must be developed incrementally.

The complete development plan is defined in `PROJECT_PLAN.md`.

Do NOT attempt to build the entire application at once.

Only implement the current milestone.

After completing a milestone, stop and wait for the human developer to manually validate it.

The human developer decides whether a milestone is approved.

---

# Milestone Rules

Before doing any implementation:

1. Read `PROJECT_PLAN.md`.
2. Identify the current milestone.
3. Read the existing project structure.
4. Understand the existing implementation.
5. Implement ONLY the current milestone.

Never implement future milestones unless explicitly instructed.

Do not anticipate future features by implementing them early.

---

# Human Approval

Codex must never consider a milestone APPROVED by itself.

Codex may report:

- implementation complete
- tests passing
- analyzer passing
- formatter passing

But only the human developer can approve a milestone.

The human developer will manually test the application.

Only after the human explicitly says that a milestone is approved should Codex proceed to the next milestone.

---

# After Every Milestone

Before reporting a milestone as complete:

1. Format the code.
2. Run Flutter static analysis.
3. Run the relevant tests.
4. Fix problems caused by the implementation.
5. Review the changes.
6. Update `PROJECT_PLAN.md`.
7. Explain what was implemented.
8. Explain what was tested.
9. Stop.

Do not start the next milestone automatically.

---

# Architecture Principles

Prefer a simple, maintainable architecture.

Separate, where appropriate:

- presentation/UI
- application/business logic
- domain models
- data/persistence

Do not introduce unnecessary abstractions.

Do not introduce a dependency unless there is a clear reason for it.

When a dependency or architectural decision is important, explain the reason before implementing it.

---

# Initial Product Scope

The first version should be local-only.

Do NOT introduce any of the following unless explicitly requested:

- backend
- authentication
- cloud synchronization
- remote APIs
- social features
- AI features
- notifications
- analytics
- subscriptions
- advertisements

The application should work completely offline for its core functionality.

---

# Core Domain Concepts

The application will eventually contain concepts similar to:

## Muscle

Represents a muscle or muscle group that the user trains.

Examples:

- Chest
- Back
- Shoulders
- Biceps
- Triceps
- Quadriceps
- Hamstrings

## Exercise

Represents an exercise performed by the user.

Examples:

- Bench Press
- Squat
- Barbell Row
- Lat Pulldown

An exercise is associated with a muscle.

## Workout

Represents a training session performed at a particular date/time.

## Workout Exercise

Represents an exercise performed during a particular workout.

## Set

Represents one set of an exercise.

A set contains at least:

- weight
- repetitions

The number of sets is dynamic.

The application must NOT assume that every exercise always contains three sets or any other fixed number.

---

# Important Product Behavior

The central workflow of the application is:

1. User decides which muscle to train.
2. User opens the application.
3. User selects the muscle.
4. The application shows the exercises associated with that muscle.
5. For each exercise, the application can show the previous performance.
6. The user uses the previous performance as a reference for today's workout.
7. The user records each set.
8. Each set contains its own weight and repetition count.
9. The number of sets may vary.
10. The workout is saved.
11. The next time the exercise is performed, the previous performance is available.

Historical workouts must never be overwritten when a new workout is recorded.

---

# Data Integrity

Historical workout data is important.

When a new workout is recorded:

- create new workout data
- preserve previous workouts
- preserve previous sets
- never overwrite historical performance merely because the same exercise is performed again

The application should eventually allow the user to reconstruct what they did on previous training days.

---

# Coding Style

Use idiomatic Dart and Flutter.

Prefer:

- clear names
- small functions
- small widgets
- testable business logic
- readable code
- explicit behavior

Avoid:

- unnecessary cleverness
- premature optimization
- unnecessary dependencies
- duplicated business logic
- giant widgets
- giant files

---

# Testing

Important business logic should have automated tests.

When a feature affects data or progression history, tests should verify that historical data remains correct.

Do not claim that a feature is complete merely because the application compiles.

---

# Communication

When finishing a milestone, report:

1. What was implemented.
2. Important architectural decisions.
3. Files that were created or modified.
4. Tests that were executed.
5. Whether formatting succeeded.
6. Whether static analysis succeeded.
7. Any remaining concerns.

Then stop and wait for the human developer.
