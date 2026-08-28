import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:logicx_loom_flutter/core/api/logicx_loom_api.dart';
import 'package:logicx_loom_flutter/features/dashboard/dashboard_page.dart';

void main() {
  testWidgets('shows only Dashboard and Messenger destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardPage(
          api: _FakeApi(),
          session: _session,
          onSignOut: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Messenger'), findsOneWidget);
    expect(find.text('Job'), findsNothing);
    expect(find.text('Duty'), findsNothing);
    expect(find.text('Actions'), findsNothing);
    expect(find.text('1 payloads synchronized'), findsOneWidget);
    expect(find.textContaining('loom-02'), findsOneWidget);
  });

  testWidgets('opens the synchronized Messenger destination', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardPage(
          api: _FakeApi(),
          session: _session,
          onSignOut: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Messenger'));
    await tester.pump();

    expect(find.text('Production team'), findsOneWidget);
    expect(find.text('Loom 02 is running'), findsOneWidget);
  });
}

const _session = UserSession(
  accessToken: 'test-token',
  profile: UserProfile(
    name: 'Vijay Anand',
    email: 'vijay@logicxloom.in',
    role: 'admin',
  ),
);

class _FakeApi extends LogicXLoomApi {
  _FakeApi() : super('https://log.logicx.in/api/platform');

  @override
  Future<LoomDataPage> loomEvents(
    String accessToken, {
    int limit = 50,
    int? beforeId,
  }) async => LoomDataPage(
    nextBeforeId: null,
    items: [
      LoomDataEvent(
        id: 6,
        payload: const {'machineId': 'loom-02', 'status': 'running'},
        receivedAt: DateTime.utc(2026, 8, 28, 3, 8),
        sourceIp: '127.0.0.1',
        contentBytes: 62,
      ),
    ],
  );

  @override
  Future<List<MessagingConversation>> conversations(String accessToken) async =>
      [
        MessagingConversation(
          id: 1,
          title: 'Production team',
          preview: 'Loom 02 is running',
          updatedAt: DateTime.utc(2026, 8, 28, 3, 8),
          unreadCount: 1,
        ),
      ];
}
