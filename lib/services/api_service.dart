import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  final String? token;

  ApiService({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // ── AUTH ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> register(
      String fullName, String email,
      String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  // ── MARKET ─────────────────────────────────────────────────

  Future<List<dynamic>> getIndices() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/market/indices'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getGainers() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/market/gainers'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getLosers() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/market/losers'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getIpos() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/market/ipos'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getFno(String symbol) async {
    final response = await http.get(
      Uri.parse(
        '${AppConstants.baseUrl}/market/fno?symbol=$symbol'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ── PORTFOLIO ──────────────────────────────────────────────

  Future<List<dynamic>> getHoldings() async {
  final response = await http.get(
    Uri.parse(
      '${AppConstants.baseUrl}/portfolio/holdings'),
    headers: _headers,
  );
  if (response.statusCode == 403) {
    throw Exception('TOKEN_EXPIRED');
  }
  return jsonDecode(response.body);
}


  Future<Map<String, dynamic>> addHolding(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(
        '${AppConstants.baseUrl}/portfolio/holdings'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateHolding(
      int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(
        '${AppConstants.baseUrl}/portfolio/holdings/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<void> deleteHolding(int id) async {
    await http.delete(
      Uri.parse(
        '${AppConstants.baseUrl}/portfolio/holdings/$id'),
      headers: _headers,
    );
  }

  // ── WATCHLIST ──────────────────────────────────────────────

  Future<List<dynamic>> getWatchlist() async {
  final response = await http.get(
    Uri.parse('${AppConstants.baseUrl}/watchlist'),
    headers: _headers,
  );
  if (response.statusCode == 403) {
    throw Exception('TOKEN_EXPIRED');
  }
  return jsonDecode(response.body);
}

  Future<Map<String, dynamic>> addToWatchlist(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/watchlist'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<void> removeFromWatchlist(int id) async {
    await http.delete(
      Uri.parse(
        '${AppConstants.baseUrl}/watchlist/$id'),
      headers: _headers,
    );
  }

  // ── STOCK DATA ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getStockQuote(
      String symbol) async {
    final response = await http.get(
      Uri.parse(
        '${AppConstants.baseUrl}/stocks/$symbol/quote'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getFundamentals(
      String symbol) async {
    final response = await http.get(
      Uri.parse(
        '${AppConstants.baseUrl}/stocks/$symbol/fundamentals'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getTechnicals(
      String symbol) async {
    final response = await http.get(
      Uri.parse(
        '${AppConstants.baseUrl}/stocks/$symbol/technicals'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ── AI ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> analyseStock(
      String symbol, String question) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/ai/analyse'),
      headers: _headers,
      body: jsonEncode({
        'symbol': symbol,
        'question': question,
        'analysisType': 'STOCK_ANALYSIS',
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> analysePortfolio(
      String question) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/ai/analyse'),
      headers: _headers,
      body: jsonEncode({
        'question': question,
        'analysisType': 'PORTFOLIO_ANALYSIS',
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> askGeneral(
      String question) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/ai/analyse'),
      headers: _headers,
      body: jsonEncode({
        'question': question,
        'analysisType': 'GENERAL',
      }),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> searchStocks(String query) async {
  final response = await http.get(
    Uri.parse(
      '${AppConstants.baseUrl}/stocks/search?query=$query'),
    headers: _headers,
  );
  return jsonDecode(response.body);
}

Future<Map<String, dynamic>> getStockInfo(
    String symbol) async {
  final response = await http.get(
    Uri.parse(
      '${AppConstants.baseUrl}/stocks/$symbol/info'),
    headers: _headers,
  );
  return jsonDecode(response.body);
}
}