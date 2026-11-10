import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:provider/provider.dart';

import 'data/app_database.dart';
import 'data/safety_repository.dart';
import 'data/trip_repository.dart';
import 'screens/dashboard_screen.dart';
import 'services/api_key_store.dart';
import 'services/claude_safety_service.dart';
import 'state/trips_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Browser build: SQLite runs as WebAssembly, persisted in IndexedDB.
  if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
  final db = await AppDatabase.open();
  final keys = ApiKeyStore();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: keys),
        Provider.value(
            value: SafetyRepository(db, ClaudeSafetyService(keys))),
        ChangeNotifierProvider(
            create: (_) => TripsController(TripRepository(db))..load()),
      ],
      child: const PravasiSafetyApp(),
    ),
  );
}

class PravasiSafetyApp extends StatelessWidget {
  const PravasiSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = Colors.teal;
    return MaterialApp(
      title: 'Pravasi Safety',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(
          colorSchemeSeed: seed,
          brightness: Brightness.dark,
          useMaterial3: true),
      home: const DashboardScreen(),
    );
  }
}
