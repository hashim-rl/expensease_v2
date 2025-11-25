import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';

class CurrencyService {
  // Replace with your actual key or use a secure environment variable in production
  final String _apiKey = 'e588abc122f3bfa75efa65a3';
  final String _baseUrl = 'https://v6.exchangerate-api.com/v6/';
  final _box = GetStorage();

  /// Fetches the conversion rate.
  /// Strategy: Try Network -> Save to Cache.
  /// If Network fails -> Return Cache.
  /// If Cache missing -> Throw Error.
  Future<double> getConversionRate(String fromCurrency, String toCurrency) async {
    // 1. Create a unique key for this pair (e.g., "rate_EUR_USD")
    final String cacheKey = 'rate_${fromCurrency}_$toCurrency';

    try {
      debugPrint('--- CURRENCY SERVICE: Fetching rate for $fromCurrency -> $toCurrency');

      final response = await http
          .get(Uri.parse('$_baseUrl$_apiKey/pair/$fromCurrency/$toCurrency'))
          .timeout(const Duration(seconds: 5)); // 5s timeout for travel conditions

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final double rate = (data['conversion_rate'] as num).toDouble();

        // 2. Success! Save to cache for offline use later
        await _box.write(cacheKey, rate);
        await _box.write('${cacheKey}_timestamp', DateTime.now().toIso8601String());

        debugPrint('--- CURRENCY SERVICE: Rate fetched & cached: $rate');
        return rate;
      } else {
        throw Exception('API returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('!!! CURRENCY SERVICE ERROR: $e');
      debugPrint('--- CURRENCY SERVICE: Attempting to fall back to offline cache...');

      // 3. Fallback: Check if we have a saved rate
      if (_box.hasData(cacheKey)) {
        final double cachedRate = _box.read(cacheKey);
        final String timestamp = _box.read('${cacheKey}_timestamp') ?? 'Unknown';

        debugPrint('--- CURRENCY SERVICE: Found cached rate: $cachedRate (Saved: $timestamp)');
        return cachedRate;
      } else {
        // 4. Critical Failure: No internet AND no cache
        throw Exception('Offline: No saved rate for $fromCurrency to $toCurrency. Please connect to internet once.');
      }
    }
  }
}