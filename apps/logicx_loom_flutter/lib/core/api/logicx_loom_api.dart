import 'dart:convert';

import 'package:http/http.dart' as http;

class LogicXLoomApi {
  LogicXLoomApi(String baseUrl) : _baseUri = Uri.parse(baseUrl);

  final Uri _baseUri;

  Future<ApiHealth> health() async {
    return ApiHealth.fromJson(await _request('/health'));
  }

  Future<UserSession> signIn({
    required String email,
    required String password,
  }) async {
    final data = await _request(
      '/auth/login',
      body: {'email': email, 'password': password},
      method: 'POST',
    );
    return UserSession.fromJson(data);
  }

  Future<UserSession> developmentSignIn() async {
    return UserSession.fromJson(
      await _request('/auth/development/login', method: 'POST'),
    );
  }

  Future<UserProfile> session(String accessToken) async {
    return UserProfile.fromJson(
      await _request('/auth/session', accessToken: accessToken),
    );
  }

  Uri get messagingWebSocketUri {
    final scheme = _baseUri.scheme == 'https' ? 'wss' : 'ws';
    return _baseUri.replace(
      scheme: scheme,
      path: '${_baseUri.path}/ws/messaging',
      query: null,
    );
  }

  Future<LoomDataPage> loomEvents(
    String accessToken, {
    int limit = 50,
    int? beforeId,
  }) async {
    final data = await _request(
      '/loomdata/events',
      accessToken: accessToken,
      query: {'limit': '$limit', if (beforeId != null) 'beforeId': '$beforeId'},
    );
    return LoomDataPage.fromJson(data as Map<String, dynamic>);
  }

  Future<List<MessagingConversation>> conversations(String accessToken) async {
    final data = await _request(
      '/messaging/conversations',
      accessToken: accessToken,
    );
    if (data is! List) {
      throw const LogicXLoomApiException('Unexpected conversations response.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(MessagingConversation.fromJson)
        .toList();
  }

  Future<List<MessagingMessage>> messages(
    String accessToken,
    int conversationId,
  ) async {
    final data = await _request(
      '/messaging/conversations/$conversationId/messages',
      accessToken: accessToken,
      query: const {'limit': '100'},
    );
    if (data is! List) {
      throw const LogicXLoomApiException('Unexpected messages response.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(MessagingMessage.fromJson)
        .toList();
  }

  Future<MessagingMessage> sendMessage({
    required String accessToken,
    required int conversationId,
    required String content,
  }) async {
    return MessagingMessage.fromJson(
      await _request(
        '/messaging/conversations/$conversationId/messages',
        accessToken: accessToken,
        method: 'POST',
        body: {
          'clientMessageId':
              '${DateTime.now().microsecondsSinceEpoch}-$conversationId',
          'content': content,
          'type': 'TEXT',
        },
      ) as Map<String, dynamic>,
    );
  }

  Future<dynamic> _request(
    String path, {
    String? accessToken,
    Map<String, dynamic>? body,
    String method = 'GET',
    Map<String, String>? query,
  }) async {
    final request = http.Request(
      method,
      _baseUri.replace(path: '${_baseUri.path}$path', queryParameters: query),
    );
    request.headers['Accept'] = 'application/json';
    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final response = await request.send();
    final payload = jsonDecode(
      utf8.decode(await response.stream.toBytes()),
    ) as Map<String, dynamic>;
    if (payload['success'] != true || response.statusCode >= 400) {
      final error = payload['error'] as Map<String, dynamic>?;
      throw LogicXLoomApiException(
        error?['message'] as String? ?? 'Request failed.',
      );
    }
    return payload['data'];
  }
}

class ApiHealth {
  const ApiHealth({required this.isHealthy});

  final bool isHealthy;

  factory ApiHealth.fromJson(Map<String, dynamic> json) {
    return ApiHealth(isHealthy: json['status'] == 'ok');
  }
}

class UserSession {
  const UserSession({required this.accessToken, required this.profile});

  final String accessToken;
  final UserProfile profile;

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      accessToken: json['accessToken'] as String,
      profile: UserProfile.fromJson(json),
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.email,
    required this.name,
    required this.role,
  });

  final String email;
  final String name;
  final String role;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      email: json['email'] as String,
      name: json['name'] as String? ?? json['email'] as String,
      role: json['role'] as String? ?? 'user',
    );
  }
}

class LogicXLoomApiException implements Exception {
  const LogicXLoomApiException(this.message);

  final String message;
}

class LoomDataPage {
  const LoomDataPage({required this.items, required this.nextBeforeId});

  final List<LoomDataEvent> items;
  final int? nextBeforeId;

  factory LoomDataPage.fromJson(Map<String, dynamic> json) => LoomDataPage(
    items: (json['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LoomDataEvent.fromJson)
        .toList(),
    nextBeforeId: json['nextBeforeId'] as int?,
  );
}

class LoomDataEvent {
  const LoomDataEvent({
    required this.id,
    required this.payload,
    required this.receivedAt,
    required this.sourceIp,
    required this.contentBytes,
  });

  final int id;
  final Object? payload;
  final DateTime receivedAt;
  final String sourceIp;
  final int contentBytes;

  factory LoomDataEvent.fromJson(Map<String, dynamic> json) => LoomDataEvent(
    id: json['id'] as int,
    payload: json['payload'],
    receivedAt: DateTime.parse(json['receivedAt'] as String),
    sourceIp: json['sourceIp'] as String? ?? 'unknown',
    contentBytes: json['contentBytes'] as int? ?? 0,
  );

  String get formattedPayload =>
      const JsonEncoder.withIndent('  ').convert(payload);
}

class MessagingConversation {
  const MessagingConversation({
    required this.id,
    required this.title,
    required this.preview,
    required this.updatedAt,
    required this.unreadCount,
  });

  final int id;
  final String title;
  final String preview;
  final DateTime updatedAt;
  final int unreadCount;

  factory MessagingConversation.fromJson(Map<String, dynamic> json) {
    final last = json['lastMessage'] as Map<String, dynamic>?;
    final members = (json['members'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return MessagingConversation(
      id: json['id'] as int,
      title:
          json['title'] as String? ??
          (members.isEmpty
              ? 'Conversation'
              : members.first['userName'] as String? ?? 'Conversation'),
      preview: last?['content'] as String? ?? 'No messages yet',
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}

class MessagingMessage {
  const MessagingMessage({
    required this.id,
    required this.senderName,
    required this.senderEmail,
    required this.content,
    required this.createdAt,
    required this.status,
  });

  final int id;
  final String senderName;
  final String senderEmail;
  final String content;
  final DateTime createdAt;
  final String status;

  factory MessagingMessage.fromJson(Map<String, dynamic> json) =>
      MessagingMessage(
        id: json['id'] as int,
        senderName: json['senderName'] as String? ?? 'User',
        senderEmail: json['senderEmail'] as String? ?? '',
        content: json['content'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        status: json['status'] as String? ?? 'SENT',
      );
}
