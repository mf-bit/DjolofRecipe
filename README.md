# Gym Progression

A local-first Flutter mobile application for tracking gym workouts and progression.

## Project Status

M4 — Workout Creation is implementation complete and awaiting manual approval.

The current app supports exercise management and starting a workout. A user can choose a muscle group, select its exercises, and create a timestamped local workout session. Set recording, history UI, and progression features are deferred to their respective milestones in `PROJECT_PLAN.md`.

## Local Storage

The app uses a local SQLite database with foreign-key relationships between muscles, exercises, workouts, workout exercises, and workout sets. A workout and all of its nested records are saved in one transaction. Existing workout IDs are never replaced, preventing an accidental overwrite of historical workout data.

## Purpose

The application helps the user remember what they previously did for each exercise.

Before performing an exercise, the user can see the previous:

- weight
- repetitions
- number of sets

The user can then record the current workout and compare their performance with the previous one.

## Core Workflow

1. Select a muscle to train.
2. See exercises associated with that muscle.
3. See previous performance for each exercise.
4. Perform the exercise.
5. Record each set:
   - weight
   - repetitions
6. Complete the workout.
7. Review previous workouts and progression later.

## Important Concept

The number of sets is not fixed.

For example, one workout may contain:

- 3 sets

while another may contain:

- 4 sets

or:

- 5 sets

Each set independently stores its weight and repetitions.

## Initial Scope

The first version is local-only.

There is intentionally no:

- backend
- authentication
- cloud synchronization
- social functionality
- AI
- notifications
- advertisements

These may be considered in future versions.

## Development

Development is organized into milestones.

See:

- `AGENTS.md` — instructions for Codex and development rules.
- `PROJECT_PLAN.md` — complete milestone plan and current progress.

Each milestone is manually validated before moving to the next one.

### Commands

Run the app:

```sh
flutter run
```

Run automated checks:

```sh
dart format .
flutter analyze
flutter test
```
