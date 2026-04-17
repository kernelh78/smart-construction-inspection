import 'package:flutter/material.dart';
import '../models/dashboard.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardSummary? summary;
  List<UnresolvedDefect> unresolvedDefects = [];
  bool loading = false;
  String? error;

  Future<void> fetch(ApiService api) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        api.getDashboardSummary(),
        api.getUnresolvedDefects(),
      ]);
      summary = results[0] as DashboardSummary;
      unresolvedDefects = results[1] as List<UnresolvedDefect>;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
