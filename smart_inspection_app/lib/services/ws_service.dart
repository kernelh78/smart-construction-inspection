import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef DefectEventCallback = void Function(Map<String, dynamic> event);

class WsService {
  static const String _baseWs = 'ws://10.0.2.2:8000';

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  String? _siteId;
  Timer? _pingTimer;

  final List<DefectEventCallback> _listeners = [];

  void addListener(DefectEventCallback cb) => _listeners.add(cb);
  void removeListener(DefectEventCallback cb) => _listeners.remove(cb);

  void connect(String siteId, String token) {
    if (_siteId == siteId && _channel != null) return;
    disconnect();
    _siteId = siteId;

    final uri = Uri.parse('$_baseWs/ws/sites/$siteId/live?token=$token');
    _channel = WebSocketChannel.connect(uri);

    _sub = _channel!.stream.listen(
      (raw) {
        final data = jsonDecode(raw as String) as Map<String, dynamic>;
        if (data['type'] == 'defect_created') {
          for (final cb in List.of(_listeners)) {
            cb(data);
          }
        }
      },
      onError: (_) => _scheduleReconnect(token),
      onDone: () => _scheduleReconnect(token),
    );

    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _channel?.sink.add('ping');
    });
  }

  void disconnect() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    _siteId = null;
  }

  void _scheduleReconnect(String token) {
    final siteId = _siteId;
    if (siteId == null) return;
    disconnect();
    Future.delayed(const Duration(seconds: 5), () => connect(siteId, token));
  }
}
