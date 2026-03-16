import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Change this to your Render deployment URL
  static const String baseUrl = 'https://jyotish-ai-backend.onrender.com/api';
  static String? _token;

  static Future<String?> get token async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  static Future<void> setToken(String? t) async {
    _token = t;
    final prefs = await SharedPreferences.getInstance();
    if (t != null) { prefs.setString('auth_token', t); }
    else { prefs.remove('auth_token'); }
  }

  static Future<Map<String, String>> _headers() async {
    final t = await token;
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  static Future<Map<String, dynamic>> _request(String method, String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers();
    http.Response response;

    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
        break;
      case 'PUT':
        response = await http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Unknown HTTP method: $method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw ApiException(err['error'] ?? 'Request failed', response.statusCode);
    }
  }

  // ── Auth ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> signup(String email, String password, String name) async {
    final res = await _request('POST', '/auth/signup', body: {'email': email, 'password': password, 'display_name': name});
    await setToken(res['session']?['access_token']);
    return res;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _request('POST', '/auth/login', body: {'email': email, 'password': password});
    await setToken(res['session']?['access_token']);
    return res;
  }

  static Future<Map<String, dynamic>> getProfile() => _request('GET', '/auth/profile');

  static Future<void> logout() async {
    try { await _request('POST', '/auth/logout'); } catch (_) {}
    await setToken(null);
  }

  // ── Kundali ──────────────────────────────────────────
  static Future<Map<String, dynamic>> generateKundali(Map<String, dynamic> birthData) =>
      _request('POST', '/kundali/generate', body: birthData);

  static Future<Map<String, dynamic>> listKundalis() => _request('GET', '/kundali/list');

  static Future<Map<String, dynamic>> getKundali(String id) => _request('GET', '/kundali/$id');

  static Future<void> deleteKundali(String id) async => await _request('DELETE', '/kundali/$id');

  // ── AI ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> createConversation({String? kundaliId, String? title, String? tradition}) =>
      _request('POST', '/ai/conversation', body: {
        if (kundaliId != null) 'kundali_id': kundaliId,
        'title': title ?? 'New Consultation',
        if (tradition != null) 'tradition': tradition,
      });

  static Future<Map<String, dynamic>> sendMessage(String conversationId, String message, {String? tradition}) =>
      _request('POST', '/ai/message', body: {
        'conversation_id': conversationId,
        'message': message,
        if (tradition != null) 'tradition': tradition,
      });

  static Future<Map<String, dynamic>> getConversation(String id) => _request('GET', '/ai/conversation/$id');
  static Future<Map<String, dynamic>> listConversations() => _request('GET', '/ai/conversations');

  static Future<Map<String, dynamic>> getFullReading(String kundaliId, {String? tradition}) =>
      _request('POST', '/ai/full-reading', body: {'kundali_id': kundaliId, if (tradition != null) 'tradition': tradition});

  static Future<void> submitFeedback(String messageId, int rating, {String? text}) async =>
      await _request('POST', '/ai/feedback', body: {'message_id': messageId, 'rating': rating, if (text != null) 'feedback_text': text});

  // ── Books ────────────────────────────────────────────
  static Future<Map<String, dynamic>> listBooks({String? tradition, String? status}) {
    String path = '/books?';
    if (tradition != null) path += 'tradition=$tradition&';
    if (status != null) path += 'status=$status&';
    return _request('GET', path);
  }

  static Future<Map<String, dynamic>> getBook(String id) => _request('GET', '/books/$id');

  // ── Knowledge ────────────────────────────────────────
  static Future<Map<String, dynamic>> searchKnowledge(String query, {String? tradition, int count = 5}) =>
      _request('POST', '/knowledge/search', body: {'query': query, if (tradition != null) 'tradition': tradition, 'count': count});

  static Future<Map<String, dynamic>> getKnowledgeStats() => _request('GET', '/knowledge/stats');
  static Future<Map<String, dynamic>> getTraditions() => _request('GET', '/knowledge/traditions');
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => 'ApiException($statusCode): $message';
}
