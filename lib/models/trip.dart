import '../data/countries.dart';

/// A planned trip abroad.
class Trip {
  final int? id;
  final String destinationCode; // ISO 3166-1 alpha-2, e.g. "AE"
  final String? originCode; // optional: where the traveller departs from
  final DateTime departureDate;
  final DateTime? returnDate;
  final String? notes;
  final DateTime createdAt;

  const Trip({
    this.id,
    required this.destinationCode,
    this.originCode,
    required this.departureDate,
    this.returnDate,
    this.notes,
    required this.createdAt,
  });

  Country get destination => countryByCode(destinationCode);
  Country? get origin => originCode == null ? null : countryByCode(originCode!);

  bool get isPast {
    final end = returnDate ?? departureDate;
    final today = DateTime.now();
    return end.isBefore(DateTime(today.year, today.month, today.day));
  }

  Trip copyWith({int? id}) => Trip(
        id: id ?? this.id,
        destinationCode: destinationCode,
        originCode: originCode,
        departureDate: departureDate,
        returnDate: returnDate,
        notes: notes,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'destination_code': destinationCode,
        'origin_code': originCode,
        'departure_date': departureDate.toIso8601String(),
        'return_date': returnDate?.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory Trip.fromMap(Map<String, Object?> m) => Trip(
        id: m['id'] as int?,
        destinationCode: m['destination_code'] as String,
        originCode: m['origin_code'] as String?,
        departureDate: DateTime.parse(m['departure_date'] as String),
        returnDate: m['return_date'] == null
            ? null
            : DateTime.parse(m['return_date'] as String),
        notes: m['notes'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
