import 'package:flutter_test/flutter_test.dart';
import 'package:pravasi_safety/data/app_database.dart';
import 'package:pravasi_safety/data/safety_repository.dart';
import 'package:pravasi_safety/data/trip_repository.dart';
import 'package:pravasi_safety/models/safety_info.dart';
import 'package:pravasi_safety/models/trip.dart';
import 'package:pravasi_safety/services/safety_info_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeService implements SafetyInfoService {
  int calls = 0;
  @override
  Future<SafetyInfo> fetch(String code) async {
    calls++;
    return SafetyInfo(
      summary: 'Summary for $code #$calls',
      prohibited: const [GuidanceItem(item: 'E-cigarettes', details: 'Banned')],
      restricted: const [],
      recommended: const [],
      tips: const ['Declare cash over limit'],
      disclaimer: 'Verify officially.',
    );
  }
}

void main() {
  sqfliteFfiInit();
  late Database db;

  setUp(() async {
    db = await AppDatabase.open(
        factory: databaseFactoryFfi, path: inMemoryDatabasePath);
  });
  tearDown(() => db.close());

  test('safety info is fetched once, then served from SQLite cache', () async {
    final service = _FakeService();
    final repo = SafetyRepository(db, service);

    final first = await repo.get('SG');
    final second = await repo.get('SG');

    expect(service.calls, 1);
    expect(second.info.summary, first.info.summary);
    expect(second.info.prohibited.single.item, 'E-cigarettes');
    expect(second.info.tips, ['Declare cash over limit']);
  });

  test('forceRefresh refetches and overwrites cache', () async {
    final service = _FakeService();
    final repo = SafetyRepository(db, service);

    await repo.get('AE');
    final refreshed = await repo.get('AE', forceRefresh: true);

    expect(service.calls, 2);
    expect((await repo.cached('AE'))!.info.summary, refreshed.info.summary);
  });

  test('trips: upcoming sorted soonest first, past trips after', () async {
    final repo = TripRepository(db);
    final now = DateTime.now();
    Trip t(String code, int days) => Trip(
        destinationCode: code,
        departureDate: now.add(Duration(days: days)),
        createdAt: now);

    await repo.insert(t('JP', 30));
    await repo.insert(t('GB', -40));
    await repo.insert(t('SA', 5));

    final codes = (await repo.all()).map((e) => e.destinationCode).toList();
    expect(codes, ['SA', 'JP', 'GB']);
  });
}
