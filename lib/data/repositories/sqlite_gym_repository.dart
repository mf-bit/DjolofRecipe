import 'package:sqflite/sqflite.dart';

import '../../domain/domain.dart';
import 'gym_repository.dart';

/// SQLite-backed local storage for the application's core data.
class SqliteGymRepository implements GymRepository {
  SqliteGymRepository._(this._database);

  static const _databaseName = 'gym_progression.db';
  static const _schemaVersion = 1;

  final Database _database;

  /// Opens the application's local database.
  ///
  /// A [factory] and [databasePath] can be supplied by tests or another host.
  static Future<SqliteGymRepository> open({
    DatabaseFactory? factory,
    String? databasePath,
  }) async {
    final effectiveFactory = factory ?? databaseFactory;
    final effectivePath =
        databasePath ??
        '${await effectiveFactory.getDatabasesPath()}/$_databaseName';
    final database = await effectiveFactory.openDatabase(
      effectivePath,
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE muscles (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL
            )
          ''');
          await database.execute('''
            CREATE TABLE exercises (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              muscle_id TEXT NOT NULL,
              FOREIGN KEY (muscle_id) REFERENCES muscles(id) ON DELETE RESTRICT
            )
          ''');
          await database.execute('''
            CREATE TABLE workouts (
              id TEXT PRIMARY KEY,
              performed_at INTEGER NOT NULL
            )
          ''');
          await database.execute('''
            CREATE TABLE workout_exercises (
              id TEXT PRIMARY KEY,
              workout_id TEXT NOT NULL,
              exercise_id TEXT NOT NULL,
              position INTEGER NOT NULL,
              FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE,
              FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE RESTRICT,
              UNIQUE (workout_id, position)
            )
          ''');
          await database.execute('''
            CREATE TABLE workout_sets (
              id TEXT PRIMARY KEY,
              workout_exercise_id TEXT NOT NULL,
              position INTEGER NOT NULL,
              weight REAL NOT NULL,
              repetitions INTEGER NOT NULL,
              FOREIGN KEY (workout_exercise_id)
                REFERENCES workout_exercises(id) ON DELETE CASCADE,
              UNIQUE (workout_exercise_id, position)
            )
          ''');
        },
      ),
    );

    return SqliteGymRepository._(database);
  }

  @override
  Future<void> saveMuscle(Muscle muscle) {
    return _database.insert('muscles', {
      'id': muscle.id,
      'name': muscle.name,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  @override
  Future<List<Muscle>> getMuscles() async {
    final rows = await _database.query('muscles', orderBy: 'name ASC');
    return rows
        .map(
          (row) =>
              Muscle(id: row['id']! as String, name: row['name']! as String),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveExercise(Exercise exercise) {
    return _database.insert('exercises', {
      'id': exercise.id,
      'name': exercise.name,
      'muscle_id': exercise.muscleId,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  @override
  Future<void> updateExercise(Exercise exercise) async {
    final rowsUpdated = await _database.update(
      'exercises',
      {'name': exercise.name, 'muscle_id': exercise.muscleId},
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
    if (rowsUpdated == 0) {
      throw StateError('Exercise ${exercise.id} does not exist.');
    }
  }

  @override
  Future<void> deleteExercise(String exerciseId) async {
    final rowsDeleted = await _database.delete(
      'exercises',
      where: 'id = ?',
      whereArgs: [exerciseId],
    );
    if (rowsDeleted == 0) {
      throw StateError('Exercise $exerciseId does not exist.');
    }
  }

  @override
  Future<List<Exercise>> getExercises({String? muscleId}) async {
    final rows = await _database.query(
      'exercises',
      where: muscleId == null ? null : 'muscle_id = ?',
      whereArgs: muscleId == null ? null : [muscleId],
      orderBy: 'name ASC',
    );
    return rows
        .map(
          (row) => Exercise(
            id: row['id']! as String,
            name: row['name']! as String,
            muscleId: row['muscle_id']! as String,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveWorkout(Workout workout) {
    return _database.transaction((transaction) async {
      await transaction.insert('workouts', {
        'id': workout.id,
        'performed_at': workout.performedAt.toUtc().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.abort);

      for (
        var exerciseIndex = 0;
        exerciseIndex < workout.exercises.length;
        exerciseIndex++
      ) {
        final workoutExercise = workout.exercises[exerciseIndex];
        await transaction.insert('workout_exercises', {
          'id': workoutExercise.id,
          'workout_id': workout.id,
          'exercise_id': workoutExercise.exerciseId,
          'position': exerciseIndex,
        }, conflictAlgorithm: ConflictAlgorithm.abort);

        for (
          var setIndex = 0;
          setIndex < workoutExercise.sets.length;
          setIndex++
        ) {
          final workoutSet = workoutExercise.sets[setIndex];
          await transaction.insert('workout_sets', {
            'id': workoutSet.id,
            'workout_exercise_id': workoutExercise.id,
            'position': setIndex,
            'weight': workoutSet.weight,
            'repetitions': workoutSet.repetitions,
          }, conflictAlgorithm: ConflictAlgorithm.abort);
        }
      }
    });
  }

  @override
  Future<void> updateWorkout(Workout workout) {
    return _database.transaction((transaction) async {
      // Verify the workout exists.
      final rowsUpdated = await transaction.update(
        'workouts',
        {'performed_at': workout.performedAt.toUtc().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [workout.id],
      );
      if (rowsUpdated == 0) {
        throw StateError('Workout ${workout.id} does not exist.');
      }

      // Delete existing exercises (CASCADE removes their sets too).
      await transaction.delete(
        'workout_exercises',
        where: 'workout_id = ?',
        whereArgs: [workout.id],
      );

      // Re-insert exercises and sets.
      for (
        var exerciseIndex = 0;
        exerciseIndex < workout.exercises.length;
        exerciseIndex++
      ) {
        final workoutExercise = workout.exercises[exerciseIndex];
        await transaction.insert('workout_exercises', {
          'id': workoutExercise.id,
          'workout_id': workout.id,
          'exercise_id': workoutExercise.exerciseId,
          'position': exerciseIndex,
        }, conflictAlgorithm: ConflictAlgorithm.abort);

        for (
          var setIndex = 0;
          setIndex < workoutExercise.sets.length;
          setIndex++
        ) {
          final workoutSet = workoutExercise.sets[setIndex];
          await transaction.insert('workout_sets', {
            'id': workoutSet.id,
            'workout_exercise_id': workoutExercise.id,
            'position': setIndex,
            'weight': workoutSet.weight,
            'repetitions': workoutSet.repetitions,
          }, conflictAlgorithm: ConflictAlgorithm.abort);
        }
      }
    });
  }

  @override
  Future<void> deleteWorkout(String workoutId) async {
    final rowsDeleted = await _database.delete(
      'workouts',
      where: 'id = ?',
      whereArgs: [workoutId],
    );
    if (rowsDeleted == 0) {
      throw StateError('Workout $workoutId does not exist.');
    }
  }

  @override
  Future<WorkoutExercise?> getLatestWorkoutExercise(
    String exerciseId, {
    String? excludingWorkoutId,
  }) async {
    final rows = await _database.rawQuery(
      '''
      SELECT we.id, we.exercise_id, we.position
      FROM workout_exercises we
      INNER JOIN workouts w ON we.workout_id = w.id
      INNER JOIN workout_sets ws ON ws.workout_exercise_id = we.id
      WHERE we.exercise_id = ?
        ${excludingWorkoutId != null ? 'AND w.id != ?' : ''}
      ORDER BY w.performed_at DESC, we.position ASC
      LIMIT 1
    ''',
      [exerciseId, ?excludingWorkoutId],
    );

    if (rows.isEmpty) {
      return null;
    }

    return _workoutExerciseFromRow(rows.first);
  }

  @override
  Future<List<Workout>> getWorkouts({String? exerciseId}) async {
    List<Map<String, Object?>> workoutRows;
    if (exerciseId == null) {
      workoutRows = await _database.query(
        'workouts',
        orderBy: 'performed_at DESC',
      );
    } else {
      workoutRows = await _database.rawQuery(
        '''
        SELECT DISTINCT w.id, w.performed_at
        FROM workouts w
        INNER JOIN workout_exercises we ON we.workout_id = w.id
        WHERE we.exercise_id = ?
        ORDER BY w.performed_at DESC
      ''',
        [exerciseId],
      );
    }

    return Future.wait(workoutRows.map(_workoutFromRow));
  }

  Future<Workout> _workoutFromRow(Map<String, Object?> row) async {
    final workoutId = row['id']! as String;
    final exerciseRows = await _database.query(
      'workout_exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'position ASC',
    );
    final exercises = await Future.wait(
      exerciseRows.map(_workoutExerciseFromRow),
    );

    return Workout(
      id: workoutId,
      performedAt: DateTime.fromMillisecondsSinceEpoch(
        row['performed_at']! as int,
        isUtc: true,
      ),
      exercises: exercises,
    );
  }

  Future<WorkoutExercise> _workoutExerciseFromRow(
    Map<String, Object?> row,
  ) async {
    final workoutExerciseId = row['id']! as String;
    final setRows = await _database.query(
      'workout_sets',
      where: 'workout_exercise_id = ?',
      whereArgs: [workoutExerciseId],
      orderBy: 'position ASC',
    );

    return WorkoutExercise(
      id: workoutExerciseId,
      exerciseId: row['exercise_id']! as String,
      sets: setRows
          .map(
            (setRow) => WorkoutSet(
              id: setRow['id']! as String,
              weight: (setRow['weight']! as num).toDouble(),
              repetitions: setRow['repetitions']! as int,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> close() => _database.close();
}
