import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'repositories/sqlite_gym_repository.dart';

/// Opens the repository using the appropriate SQLite implementation for the host.
Future<SqliteGymRepository> openAppGymRepository() {
  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    return SqliteGymRepository.open(factory: databaseFactoryFfi);
  }

  return SqliteGymRepository.open();
}
