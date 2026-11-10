import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/safety_info.dart';
import '../services/safety_info_service.dart';

/// Cache-first access to [SafetyInfo].
///
/// Looks in the local `safety_cache` table first; only calls the remote
/// [SafetyInfoService] on a miss (or when [forceRefresh] is set), then stores
/// the result so the next lookup for that country is offline and free.
class SafetyRepository {
  final Database _db;
  final SafetyInfoService _service;

  SafetyRepository(this._db, this._service);

  Future<CachedSafetyInfo?> cached(String destinationCode) async {
    final rows = await _db.query(
      'safety_cache',
      where: 'destination_code = ?',
      whereArgs: [destinationCode],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return CachedSafetyInfo(
      SafetyInfo.fromJson(
          jsonDecode(row['payload'] as String) as Map<String, dynamic>),
      DateTime.parse(row['fetched_at'] as String),
    );
  }

  Future<CachedSafetyInfo> get(String destinationCode,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final hit = await cached(destinationCode);
      if (hit != null) return hit;
    }
    final info = await _service.fetch(destinationCode);
    final now = DateTime.now();
    await _db.insert(
      'safety_cache',
      {
        'destination_code': destinationCode,
        'payload': jsonEncode(info.toJson()),
        'fetched_at': now.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return CachedSafetyInfo(info, now);
  }
}
