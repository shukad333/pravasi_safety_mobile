import '../models/safety_info.dart';

/// Source of carry / don't-carry guidance for a destination.
///
/// Kept abstract so the backing source can change later (your own backend,
/// a curated dataset, a different model) without touching the UI or cache.
abstract class SafetyInfoService {
  Future<SafetyInfo> fetch(String destinationCode);
}

class SafetyInfoException implements Exception {
  final String message;
  const SafetyInfoException(this.message);
  @override
  String toString() => message;
}
