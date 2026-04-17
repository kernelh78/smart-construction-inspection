import 'package:flutter/material.dart';
import '../models/inspection.dart';
import '../services/api_service.dart';

class InspectionsProvider extends ChangeNotifier {
  List<Inspection> inspections = [];
  List<Defect> defects = [];
  bool loading = false;
  String? error;

  Future<void> fetchInspections(ApiService api, {String? siteId}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      inspections = await api.getInspections(siteId: siteId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> createInspection(ApiService api, Map<String, dynamic> data) async {
    try {
      final inspection = await api.createInspection(data);
      inspections.insert(0, inspection);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchDefects(ApiService api, String inspectionId) async {
    loading = true;
    notifyListeners();
    try {
      defects = await api.getDefects(inspectionId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> createDefect(ApiService api, String inspectionId, String severity, String description) async {
    try {
      final defect = await api.createDefect(inspectionId, severity, description);
      defects.insert(0, defect);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
