import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/site.dart';
import '../models/inspection.dart';
import '../models/dashboard.dart';
import '../models/user.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  final String? token;

  ApiService({this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handle(res);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<void> _delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    _handle(res);
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    throw ApiException(
      body['detail'] ?? '요청 실패',
      statusCode: res.statusCode,
    );
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'username=$email&password=$password',
    );
    return _handle(res);
  }

  Future<User> getMe() async {
    final data = await _get('/auth/me');
    return User.fromJson(data);
  }

  // Sites
  Future<List<Site>> getSites() async {
    final data = await _get('/sites/') as List;
    return data.map((e) => Site.fromJson(e)).toList();
  }

  Future<Site> getSite(String id) async {
    final data = await _get('/sites/$id');
    return Site.fromJson(data);
  }

  Future<Site> createSite(Map<String, dynamic> body) async {
    final data = await _post('/sites/', body);
    return Site.fromJson(data);
  }

  Future<Site> updateSite(String id, Map<String, dynamic> body) async {
    final data = await _put('/sites/$id', body);
    return Site.fromJson(data);
  }

  Future<void> deleteSite(String id) => _delete('/sites/$id');

  // Inspections
  Future<List<Inspection>> getInspections({String? siteId}) async {
    final path = siteId != null ? '/inspections/?site_id=$siteId' : '/inspections/';
    final data = await _get(path) as List;
    return data.map((e) => Inspection.fromJson(e)).toList();
  }

  Future<Inspection> getInspection(String id) async {
    final data = await _get('/inspections/$id');
    return Inspection.fromJson(data);
  }

  Future<Inspection> createInspection(Map<String, dynamic> body) async {
    final data = await _post('/inspections/', body);
    return Inspection.fromJson(data);
  }

  Future<void> deleteInspection(String id) => _delete('/inspections/$id');

  // Defects
  Future<List<Defect>> getDefects(String inspectionId) async {
    final data = await _get('/inspections/$inspectionId/defects') as List;
    return data.map((e) => Defect.fromJson(e)).toList();
  }

  Future<Defect> createDefect(String inspectionId, String severity, String description) async {
    final data = await _post('/inspections/$inspectionId/defects', {
      'severity': severity,
      'description': description,
    });
    return Defect.fromJson(data);
  }

  // Dashboard
  Future<DashboardSummary> getDashboardSummary() async {
    final data = await _get('/dashboard/summary');
    return DashboardSummary.fromJson(data);
  }

  Future<List<UnresolvedDefect>> getUnresolvedDefects() async {
    final data = await _get('/dashboard/defects') as List;
    return data.map((e) => UnresolvedDefect.fromJson(e)).toList();
  }
}
