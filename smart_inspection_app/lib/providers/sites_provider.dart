import 'package:flutter/material.dart';
import '../models/site.dart';
import '../services/api_service.dart';

class SitesProvider extends ChangeNotifier {
  List<Site> sites = [];
  bool loading = false;
  String? error;

  Future<void> fetchSites(ApiService api) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      sites = await api.getSites();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> createSite(ApiService api, Map<String, dynamic> data) async {
    try {
      final site = await api.createSite(data);
      sites.insert(0, site);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSite(ApiService api, String id) async {
    try {
      await api.deleteSite(id);
      sites.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
