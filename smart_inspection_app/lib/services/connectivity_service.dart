import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_db_service.dart';
import 'api_service.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  StreamSubscription? _sub;
  bool _online = true;

  bool get isOnline => _online;

  void init(ApiService api) {
    _sub = Connectivity().onConnectivityChanged.listen((results) async {
      final wasOffline = !_online;
      _online = results.any((r) => r != ConnectivityResult.none);
      if (wasOffline && _online) {
        await _syncPending(api);
      }
    });
  }

  void dispose() => _sub?.cancel();

  Future<void> _syncPending(ApiService api) async {
    final inspections = await LocalDbService.getPendingInspections();
    for (final row in inspections) {
      try {
        await api.createInspection({
          'site_id': row['site_id'],
          'inspector_id': row['inspector_id'],
          'category': row['category'],
          'status': row['status'],
          'memo': row['memo'],
        });
        await LocalDbService.markInspectionSynced(row['id'] as String);
      } catch (_) {}
    }

    final defects = await LocalDbService.getPendingDefects();
    for (final row in defects) {
      try {
        await api.createDefect(
          row['inspection_id'] as String,
          row['severity'] as String,
          row['description'] as String,
        );
        await LocalDbService.markDefectSynced(row['id'] as String);
      } catch (_) {}
    }
  }
}
