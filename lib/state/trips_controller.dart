import 'package:flutter/foundation.dart';

import '../data/trip_repository.dart';
import '../models/trip.dart';

class TripsController extends ChangeNotifier {
  final TripRepository _repo;
  TripsController(this._repo);

  List<Trip> _trips = const [];
  bool _loading = true;

  List<Trip> get trips => _trips;
  bool get loading => _loading;

  Future<void> load() async {
    _trips = await _repo.all();
    _loading = false;
    notifyListeners();
  }

  Future<Trip> add(Trip trip) async {
    final saved = await _repo.insert(trip);
    await load();
    return saved;
  }

  Future<void> remove(Trip trip) async {
    if (trip.id == null) return;
    await _repo.delete(trip.id!);
    await load();
  }
}
