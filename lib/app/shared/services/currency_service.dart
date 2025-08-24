import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  // Replace 'YOUR_API_KEY' with the key you got from exchangerate-api.com
  final String _apiKey = 'e588abc122f3bfa75efa65a3';
  final String _baseUrl = 'https://v6.exchangerate-api.com/v6/';

  // Fetches the conversion rate between two currencies
  Future<double> getConversionRate(String fromCurrency, String toCurrency) async {
    final response = await http.get(Uri.parse('$_baseUrl$_apiKey/pair/$fromCurrency/$toCurrency'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // The API returns the conversion rate in the 'conversion_rate' field
      return (data['conversion_rate'] as num).toDouble();
    } else {
      throw Exception('Failed to load exchange rate');
    }
  }
}