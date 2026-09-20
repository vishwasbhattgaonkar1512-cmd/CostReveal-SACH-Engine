import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/loan_terms.dart';
import 'prompts.dart';

class AIUnavailableException implements Exception {
  final String message;
  AIUnavailableException(this.message);

  @override
  String toString() => message;
}

class GeminiApi {
  // Configured via environment variable or placeholder.
  // DO NOT hard-code a real API key.
  static const String _placeholderApiKey = 'API_KEY_PLACEHOLDER';
  
  final String _apiKey;
  final String _model = 'gemini-3.8-flash';
  final http.Client _client;

  GeminiApi({String? apiKey, http.Client? client}) 
    : _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: _placeholderApiKey),
      _client = client ?? http.Client();

  Future<CandidateLoanTerms> extractFromText(String text) async {
    return _extract([
      {"text": Prompts.extractionPrompt},
      {"text": text},
    ]);
  }

  Future<CandidateLoanTerms> extractFromImage(String base64Image) async {
    return _extract([
      {"text": Prompts.extractionPrompt},
      {
        "inlineData": {
          "mimeType": "image/jpeg",
          "data": base64Image,
        }
      },
    ]);
  }

  Future<CandidateLoanTerms> _extract(List<Map<String, dynamic>> parts) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/\$_model:generateContent?key=\$_apiKey');

    final body = jsonEncode({
      "contents": [
        {
          "parts": parts,
        }
      ],
      "generationConfig": {
        "responseMimeType": "application/json",
        "responseSchema": {
          "type": "object",
          "properties": {
            "principal_amount": {"type": "number", "nullable": true},
            "tenure_months": {"type": "integer", "nullable": true},
            "advertised_flat_rate": {"type": "number", "nullable": true},
            "upfront_processing_fee": {"type": "number", "nullable": true},
            "monthly_insurance_premium": {"type": "number", "nullable": true}
          }
        }
      }
    });

    try {
      final response = await _client.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 429) {
        throw AIUnavailableException('High traffic detected. Please use manual entry or Demo Mode.');
      }
      
      if (response.statusCode != 200) {
        throw AIUnavailableException('AI API error: HTTP \${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);
      
      final candidates = jsonResponse['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw AIUnavailableException('Empty response from AI.');
      }
      
      final content = candidates[0]['content'];
      if (content == null) {
         throw AIUnavailableException('No content returned from AI.');
      }
      
      final contentParts = content['parts'] as List<dynamic>?;
      if (contentParts == null || contentParts.isEmpty) {
         throw AIUnavailableException('Empty text parts from AI.');
      }
      
      String text = contentParts[0]['text'] ?? '';
      
      if (text.trim().isEmpty) {
        throw AIUnavailableException('Empty response from AI.');
      }
      
      // Parse JSON (remove markdown fences if somehow returned despite instructions)
      String cleanText = text.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      } else if (cleanText.startsWith('```')) {
        cleanText = cleanText.substring(3);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      
      final Map<String, dynamic> json = jsonDecode(cleanText.trim());
      
      return validateAndMap(json);
      
    } on AIUnavailableException {
      rethrow;
    } on FormatException catch (e) {
      throw AIUnavailableException('Malformed JSON response from AI: \$e');
    } catch (e) {
      throw AIUnavailableException('Network or unavailable error: \$e');
    }
  }

  CandidateLoanTerms validateAndMap(Map<String, dynamic> json) {
    final double? principal = _parseDouble(json['principal_amount']);
    final int? tenure = _parseInt(json['tenure_months']);
    final double? rate = _parseDouble(json['advertised_flat_rate']);
    final double? fee = _parseDouble(json['upfront_processing_fee']);
    final double? insurance = _parseDouble(json['monthly_insurance_premium']);

    if ((principal != null && principal < 0) ||
        (tenure != null && tenure < 0) ||
        (rate != null && rate < 0) ||
        (fee != null && fee < 0) ||
        (insurance != null && insurance < 0)) {
      throw AIUnavailableException('Invalid negative monetary or rate values detected.');
    }

    return CandidateLoanTerms(
      principal_amount: principal,
      tenure_months: tenure,
      advertised_flat_rate: rate,
      upfront_processing_fee: fee,
      monthly_insurance_premium: insurance,
    );
  }
  
  double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) {
      if (!val.isFinite) throw AIUnavailableException('Non-finite numeric value.');
      return val.toDouble();
    }
    if (val is String) {
      final parsed = double.tryParse(val);
      if (parsed != null && !parsed.isFinite) throw AIUnavailableException('Non-finite numeric value.');
      return parsed;
    }
    return null;
  }
  
  int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) {
      if (!val.isFinite) throw AIUnavailableException('Non-finite numeric value.');
      return val.toInt();
    }
    if (val is String) return int.tryParse(val);
    return null;
  }
}
