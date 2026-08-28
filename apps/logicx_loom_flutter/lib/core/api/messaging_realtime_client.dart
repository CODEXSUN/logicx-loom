import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'logicx_loom_api.dart';

class MessagingRealtimeClient {
  MessagingRealtimeClient({required this.api, required this.accessToken});

  final LogicXLoomApi api;
  final String accessToken;
  final _messages = StreamController<RealtimeMessage>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  var _closed = false;
  var _eventId = 0;
  final Set<int> _subscriptions = {};

  Stream<RealtimeMessage> get messages => _messages.stream;

  void connect() {
    if (_closed || _channel != null) return;
    final channel = WebSocketChannel.connect(api.messagingWebSocketUri);
    _channel = channel;
    _subscription = channel.stream.listen(
      _receive,
      onDone: _reconnect,
      onError: (_) => _reconnect(),
    );
    _send('auth', {'token': accessToken});
  }

  void subscribe(int conversationId) {
    _subscriptions.add(conversationId);
    _send('conversation.subscribe', {'conversationId': conversationId});
    _send('sync.request', {
      'conversationId': conversationId,
      'afterSequence': 0,
      'limit': 200,
    });
  }

  void _receive(dynamic raw) {
    final envelope = jsonDecode(raw as String) as Map<String, dynamic>;
    final eventType = envelope['eventType'] as String? ?? '';
    final payload = envelope['payload'] as Map<String, dynamic>? ?? {};
    if (eventType == 'auth.success') {
      for (final conversationId in _subscriptions) {
        subscribe(conversationId);
      }
    }
    if (eventType == 'message.created') {
      _messages.add(
        RealtimeMessage(
          conversationId: payload['conversationId'] as int,
          message: MessagingMessage.fromJson(
            payload['message'] as Map<String, dynamic>,
          ),
        ),
      );
    }
    if (eventType == 'sync.completed') {
      final conversationId = payload['conversationId'] as int;
      for (final value in payload['messages'] as List? ?? const []) {
        if (value is Map<String, dynamic>) {
          _messages.add(
            RealtimeMessage(
              conversationId: conversationId,
              message: MessagingMessage.fromJson(value),
            ),
          );
        }
      }
    }
  }

  void _send(String eventType, Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null) return;
    _eventId += 1;
    channel.sink.add(
      jsonEncode({
        'eventId': 'flutter-$_eventId',
        'eventType': eventType,
        'payload': payload,
      }),
    );
  }

  void _reconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    if (_closed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), connect);
  }

  Future<void> close() async {
    _closed = true;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    await _messages.close();
  }
}

class RealtimeMessage {
  const RealtimeMessage({required this.conversationId, required this.message});

  final int conversationId;
  final MessagingMessage message;
}
