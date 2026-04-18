import 'package:flutter/material.dart';
import '../services/ws_service.dart';

class WsNotification {
  final String siteId;
  final String severity;
  final String description;
  final DateTime receivedAt;

  WsNotification({
    required this.siteId,
    required this.severity,
    required this.description,
    required this.receivedAt,
  });
}

class WsProvider extends ChangeNotifier {
  final WsService _ws = WsService();
  final List<WsNotification> _notifications = [];

  List<WsNotification> get notifications => List.unmodifiable(_notifications);
  WsNotification? get latest => _notifications.isNotEmpty ? _notifications.last : null;

  WsProvider() {
    _ws.addListener(_onEvent);
  }

  void connectToSite(String siteId, String token) {
    _ws.connect(siteId, token);
  }

  void disconnect() => _ws.disconnect();

  void _onEvent(Map<String, dynamic> event) {
    _notifications.add(WsNotification(
      siteId: event['site_id'] ?? '',
      severity: event['severity'] ?? '',
      description: event['description'] ?? '',
      receivedAt: DateTime.now(),
    ));
    notifyListeners();
  }

  @override
  void dispose() {
    _ws.removeListener(_onEvent);
    _ws.disconnect();
    super.dispose();
  }
}
