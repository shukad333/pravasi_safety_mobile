import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../data/countries.dart';
import '../models/safety_info.dart';
import 'api_key_store.dart';
import 'safety_info_service.dart';

/// Generates [SafetyInfo] with the Claude Messages API (raw HTTP – there is
/// no official Dart SDK).
///
/// NOTE: calling the API straight from the device with a user-supplied key is
/// fine for a prototype. For a store release, route this through your own
/// backend so the key never ships on devices.
class ClaudeSafetyService implements SafetyInfoService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const model = 'claude-opus-5-5';

  final ApiKeyStore _keys;
  final http.Client _http;

  ClaudeSafetyService(this._keys, {http.Client? client})
      : _http = client ?? http.Client();

  static const _system = '''
You are a customs and travel-safety assistant for people travelling abroad.
Given a destination country, list what a traveller should and should not carry
when entering it through airport/land customs.

- prohibited: items that are banned outright on entry (e.g. specific medicines,
  narcotics, certain foods, e-cigarettes, publications) – be specific to the
  country, not generic airline security rules.
- restricted: items allowed only with a permit, prescription, declaration or
  quantity limit (cash thresholds, alcohol/tobacco allowances, medicines,
  drones, food, plants). Put the concrete limit or requirement in details.
- recommended: practical things worth carrying for this destination
  (documents, prescriptions with letters, plug adapters, etc.).
- tips: short entry/customs tips specific to this country.
- disclaimer: one sentence reminding the user to verify with official customs
  and embassy sources, since rules change.

Keep each details field to one or two sentences. If you are unsure about a
rule, say so in its details rather than inventing specifics.''';

  @override
  Future<SafetyInfo> fetch(String destinationCode) async {
    final apiKey = await _keys.read();
    if (apiKey == null || apiKey.isEmpty) {
      throw const SafetyInfoException(
          'Add your Anthropic API key in Settings to fetch safety info.');
    }

    final country = countryByCode(destinationCode);
    final body = {
      'model': model,
      'max_tokens': 16000,
      'system': _system,
      'output_config': {
        'effort': 'medium',
        'format': {'type': 'json_schema', 'schema': safetyInfoJsonSchema},
      },
      // If a safety classifier declines, the API retries on a fallback model
      // within the same call.
      'fallbacks': 'default',
      'messages': [
        {
          'role': 'user',
          'content':
              'Destination country: ${country.name} (ISO code ${country.code}).',
        }
      ],
    };

    final http.Response res;
    try {
      res = await _http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'content-type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': '2026-10-21',
              'anthropic-beta': 'server-side-fallback-2026-07-01',
              // Required for CORS when calling the API from a browser.
              if (kIsWeb) 'anthropic-dangerous-direct-browser-access': 'true',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(minutes: 3));
    } on TimeoutException {
      throw const SafetyInfoException('Request timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw SafetyInfoException('Network error: ${e.message}');
    }

    if (res.statusCode != 200) {
      throw SafetyInfoException(_describeError(res));
    }

    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final stopReason = json['stop_reason'];
    if (stopReason == 'refusal') {
      throw const SafetyInfoException(
          'The model declined to answer for this destination.');
    }
    if (stopReason == 'max_tokens') {
      throw const SafetyInfoException('Response was cut off. Please retry.');
    }

    final text = (json['content'] as List)
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join();
    try {
      return SafetyInfo.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } on FormatException {
      throw const SafetyInfoException('Received an unreadable response.');
    }
  }

  String _describeError(http.Response res) {
    String? apiMessage;
    try {
      apiMessage = (jsonDecode(res.body)['error'] as Map?)?['message'] as String?;
    } catch (_) {}
    switch (res.statusCode) {
      case 401:
        return 'Invalid API key. Check it in Settings.';
      case 429:
        return 'Rate limited. Please wait a moment and retry.';
      case >= 500:
        return 'Service temporarily unavailable (${res.statusCode}). Retry shortly.';
      default:
        return 'Request failed (${res.statusCode})'
            '${apiMessage != null ? ': $apiMessage' : ''}';
    }
  }
}
