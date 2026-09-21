import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:costreveal_sach_engine/bridge/gemini_api.dart';

void main() {
  group('GeminiApi JSON Validation', () {
    late GeminiApi api;

    setUp(() {
      api = GeminiApi(apiKey: 'dummy');
    });

    test('Valid JSON -> CandidateLoanTerms', () {
      final json = {
        'principal_amount': 50000.0,
        'tenure_months': 24,
        'advertised_flat_rate': 12.0,
        'upfront_processing_fee': 2500,
        'monthly_insurance_premium': 150
      };

      final result = api.validateAndMap(json);

      expect(result.principal_amount, 50000.0);
      expect(result.tenure_months, 24);
      expect(result.advertised_flat_rate, 12.0);
      expect(result.upfront_processing_fee, 2500.0);
      expect(result.monthly_insurance_premium, 150.0);
    });

    test('Missing field resolves to null', () {
      final json = {
        'principal_amount': 50000.0,
      };

      final result = api.validateAndMap(json);

      expect(result.principal_amount, 50000.0);
      expect(result.tenure_months, isNull);
    });

    test('Wrong type handled gracefully if compatible, or null', () {
      final json = {
        'principal_amount': '50000',
        'tenure_months': 24.5
      };

      final result = api.validateAndMap(json);

      expect(result.principal_amount, 50000.0);
      expect(result.tenure_months, 24);
    });

    test('Extra unexpected field is ignored', () {
      final json = {
        'principal_amount': 1000.0,
        'extra_field': 'malicious data'
      };

      final result = api.validateAndMap(json);

      expect(result.principal_amount, 1000.0);
      expect(result.tenure_months, isNull);
    });

    test('Negative numeric value throws AIUnavailableException', () {
      final json = {
        'principal_amount': -5000.0,
      };
      expect(() => api.validateAndMap(json), throwsA(isA<AIUnavailableException>()));
    });
    
    test('Non-finite numeric value throws AIUnavailableException', () {
      final json = {
        'principal_amount': double.infinity,
      };
      expect(() => api.validateAndMap(json), throwsA(isA<AIUnavailableException>()));
    });
  });

  group('GeminiApi Network and Error Mapping', () {
    test('HTTP 429 maps to specific High traffic message', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Quota exceeded', 429);
      });
      final api = GeminiApi(apiKey: 'dummy', client: mockClient);

      expect(
        () => api.extractFromText('test'),
        throwsA(
          isA<AIUnavailableException>().having(
            (e) => e.message,
            'message',
            contains('High traffic detected'),
          ),
        ),
      );
    });

    for (final code in [400, 401, 403, 404]) {
      test('HTTP $code exposes "HTTP $code" safely', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Error from server', code);
        });
        final api = GeminiApi(apiKey: 'dummy', client: mockClient);

        expect(
          () => api.extractFromText('test'),
          throwsA(
            isA<AIUnavailableException>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('HTTP $code'),
                contains('Error from server'),
                isNot(contains('dummy')), // API key shouldn't be exposed
              ),
            ),
          ),
        );
      });
    }

    test('Network failure maps to generic network error message', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Connection refused');
      });
      final api = GeminiApi(apiKey: 'dummy', client: mockClient);

      expect(
        () => api.extractFromText('test'),
        throwsA(
          isA<AIUnavailableException>().having(
            (e) => e.message,
            'message',
            contains('Network or unavailable error'),
          ),
        ),
      );
    });

    test('Valid API response parses successfully', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['x-goog-api-key'], 'dummy');
        expect(request.url.queryParameters.containsKey('key'), isFalse);
        
        final mockResponse = {
          "candidates": [
            {
              "content": {
                "parts": [
                  {
                    "text": jsonEncode({
                      "principal_amount": 10000,
                      "tenure_months": 12
                    })
                  }
                ]
              }
            }
          ]
        };
        return http.Response(jsonEncode(mockResponse), 200);
      });
      final api = GeminiApi(apiKey: 'dummy', client: mockClient);

      final result = await api.extractFromText('test');
      expect(result.principal_amount, 10000.0);
      expect(result.tenure_months, 12);
    });

    test('First 503 then successful response', () async {
      int attempt = 0;
      final mockClient = MockClient((request) async {
        attempt++;
        if (attempt == 1) return http.Response('Service Unavailable', 503);
        final mockResponse = {
          "candidates": [{"content": {"parts": [{"text": jsonEncode({"principal_amount": 20000})}]}}]
        };
        return http.Response(jsonEncode(mockResponse), 200);
      });
      final api = GeminiApi(apiKey: 'dummy', client: mockClient);

      final result = await api.extractFromText('test');
      expect(result.principal_amount, 20000.0);
      expect(attempt, 2);
    });

    test('Two 503 responses then successful response', () async {
      int attempt = 0;
      final mockClient = MockClient((request) async {
        attempt++;
        if (attempt <= 2) return http.Response('Service Unavailable', 503);
        final mockResponse = {
          "candidates": [{"content": {"parts": [{"text": jsonEncode({"principal_amount": 30000})}]}}]
        };
        return http.Response(jsonEncode(mockResponse), 200);
      });
      final api = GeminiApi(apiKey: 'dummy', client: mockClient);

      final result = await api.extractFromText('test');
      expect(result.principal_amount, 30000.0);
      expect(attempt, 3);
    });

    test('Three consecutive 503 responses throws AIUnavailableException', () async {
      int attempt = 0;
      final mockClient = MockClient((request) async {
        attempt++;
        return http.Response('Service Unavailable', 503);
      });
      final api = GeminiApi(apiKey: 'dummy', client: mockClient);

      expect(
        () => api.extractFromText('test'),
        throwsA(
          isA<AIUnavailableException>().having(
            (e) => e.message,
            'message',
            contains('AI service is temporarily busy. Please retry or use Manual Entry/Demo Mode.'),
          ),
        ),
      );
    });
    
    test('Malformed JSON in response throws parsing error', () async {
      final mockClient = MockClient((request) async {
        final mockResponse = {
          "candidates": [
            {
              "content": {
                "parts": [
                  {
                    "text": "{ bad json"
                  }
                ]
              }
            }
          ]
        };
        return http.Response(jsonEncode(mockResponse), 200);
      });
      final api = GeminiApi(apiKey: 'dummy', client: mockClient);

      expect(
        () => api.extractFromText('test'),
        throwsA(
          isA<AIUnavailableException>().having(
            (e) => e.message,
            'message',
            contains('Malformed JSON'),
          ),
        ),
      );
    });
  });
}
