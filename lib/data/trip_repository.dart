import 'package:sqflite/sqflite.dart';

import '../models/trip.dart';

class TripRepository {
  final Database _db;
  TripRepository(this._db);

  /// Upcoming trips first (soonest departure), then past trips (most recent).
  Future<List<Trip>> all() async {
    final rows = await _db.query('trips', orderBy: 'departure_date ASC');
    final trips = rows.map(Trip.fromMap).toList();
    final upcoming = trips.where((t) => !t.isPast).toList();
    final past = trips.where((t) => t.isPast).toList().reversed.toList();
    return [...upcoming, ...past];
  }

  Future<Trip> insert(Trip trip) async {
    final map = trip.toMap()..remove('id');
    final id = await _db.insert('trips', map);
    return trip.copyWith(id: id);
  }

  Future<void> delete(int id) =>
      _db.delete('trips', where: 'id = ?', whereArgs: [id]);
}
