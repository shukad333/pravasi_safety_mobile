/// Carry / don't-carry guidance for entering a destination country.
///
/// Serialised as JSON both on the wire (Claude structured output) and in the
/// SQLite cache, so [fromJson]/[toJson] must stay in sync with
/// [safetyInfoJsonSchema].
class SafetyInfo {
  final String summary;
  final List<GuidanceItem> prohibited; // do NOT carry
  final List<GuidanceItem> restricted; // allowed with permit / declaration / limit
  final List<GuidanceItem> recommended; // good to carry
  final List<String> tips;
  final String disclaimer;

  const SafetyInfo({
    required this.summary,
    required this.prohibited,
    required this.restricted,
    required this.recommended,
    required this.tips,
    required this.disclaimer,
  });

  factory SafetyInfo.fromJson(Map<String, dynamic> j) => SafetyInfo(
        summary: j['summary'] as String? ?? '',
        prohibited: _items(j['prohibited']),
        restricted: _items(j['restricted']),
        recommended: _items(j['recommended']),
        tips: (j['tips'] as List? ?? const []).cast<String>(),
        disclaimer: j['disclaimer'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'prohibited': prohibited.map((e) => e.toJson()).toList(),
        'restricted': restricted.map((e) => e.toJson()).toList(),
        'recommended': recommended.map((e) => e.toJson()).toList(),
        'tips': tips,
        'disclaimer': disclaimer,
      };

  static List<GuidanceItem> _items(Object? raw) => (raw as List? ?? const [])
      .map((e) => GuidanceItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

class GuidanceItem {
  final String item;
  final String details;

  const GuidanceItem({required this.item, required this.details});

  factory GuidanceItem.fromJson(Map<String, dynamic> j) => GuidanceItem(
        item: j['item'] as String? ?? '',
        details: j['details'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'item': item, 'details': details};
}

/// A cached [SafetyInfo] plus when it was fetched.
class CachedSafetyInfo {
  final SafetyInfo info;
  final DateTime fetchedAt;
  const CachedSafetyInfo(this.info, this.fetchedAt);
}

const _itemSchema = {
  'type': 'object',
  'properties': {
    'item': {'type': 'string'},
    'details': {'type': 'string'},
  },
  'required': ['item', 'details'],
  'additionalProperties': false,
};

/// JSON schema used to constrain the model's output.
const safetyInfoJsonSchema = {
  'type': 'object',
  'properties': {
    'summary': {'type': 'string'},
    'prohibited': {'type': 'array', 'items': _itemSchema},
    'restricted': {'type': 'array', 'items': _itemSchema},
    'recommended': {'type': 'array', 'items': _itemSchema},
    'tips': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'disclaimer': {'type': 'string'},
  },
  'required': [
    'summary',
    'prohibited',
    'restricted',
    'recommended',
    'tips',
    'disclaimer',
  ],
  'additionalProperties': false,
};
