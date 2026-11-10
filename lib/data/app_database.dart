import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens the single on-device SQLite database used by the app.
///
/// Tables:
///  * `trips`        – the user's planned travels
///  * `safety_cache` – cached carry/don't-carry info per destination, so we
///                     don't call the network again for a country we've seen
class AppDatabase {
  static const _name = 'pravasi_safety.db';
  static const _version = 1;

  /// Opens (and creates/migrates) the database. Pass [path] to override the
  /// location, e.g. `inMemoryDatabasePath` in tests.
  static Future<Database> open({DatabaseFactory? factory, String? path}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), _name);
    return f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE trips (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              destination_code TEXT NOT NULL,
              origin_code TEXT,
              departure_date TEXT NOT NULL,
              return_date TEXT,
              notes TEXT,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE safety_cache (
              destination_code TEXT PRIMARY KEY,
              payload TEXT NOT NULL,
              fetched_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
  }
}
