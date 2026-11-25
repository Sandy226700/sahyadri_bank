import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiService {
  static Future<Map<String, dynamic>> fetchHealth() async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/health'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load health status');
  }

  static Future<List<dynamic>> fetchAccounts() async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/accounts'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load accounts');
  }

  static Future<List<dynamic>> fetchTransactions({String sourceFormat = 'ALL'}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/transactions')
        .replace(queryParameters: {'source_format': sourceFormat});
    final res = await http.get(uri);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load transactions');
  }

  static Future<List<dynamic>> fetchBranchSummary() async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/ops/branch-summary'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load branch summary');
  }

  static Future<List<dynamic>> fetchAuditLogs() async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/ops/audit'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load audit logs');
  }
}
