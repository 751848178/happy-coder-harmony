import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:happy_coder_flutter/app/providers/app_providers.dart';
import 'package:happy_coder_flutter/features/chat/components/session_list.dart';
import 'package:happy_coder_flutter/features/session/data/session_repository.dart';
import 'package:happy_coder_flutter/features/session/domain/session_models.dart';

void main() {
  testWidgets(
    'session list item shows latest user preview from loaded messages',
    (tester) async {
      final repository = SessionRepository.instance;
      repository.clearAll();

      final notifier = SessionServiceNotifier(repository);
      final session = Session(
        id: 'session-count-1',
        title: 'Count Test',
        messages: const [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
        active: true,
      );

      repository.applySessions([session]);
      repository.applyMessages(session.id, [
        ReducerMessage(
          id: 'message-1',
          kind: 'text',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
          text: 'hello',
        ),
        ReducerMessage(
          id: 'message-2',
          kind: 'text',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1772962444908),
          metadata: const {'role': 'user'},
          text: 'latest user preview',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionStateProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SessionListItem(session: session),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('latest user preview'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      repository.clearAll();
    },
  );

  testWidgets(
    'session list item shows syncing placeholder before messages load',
    (tester) async {
      final repository = SessionRepository.instance;
      repository.clearAll();

      final notifier = SessionServiceNotifier(repository);
      final session = Session(
        id: 'session-count-persisted',
        title: 'Persisted Count',
        messages: const [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
        active: true,
        latestUsage: LatestUsage(
          messageCount: 5,
          tokenCount: 256,
          timestamp: DateTime.fromMillisecondsSinceEpoch(1772962444908),
        ),
      );

      repository.applySessions([session]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionStateProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SessionListItem(session: session),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('最近消息待同步'), findsOneWidget);
      expect(find.text('待同步'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      repository.clearAll();
    },
  );

  testWidgets(
    'loaded messages override history placeholder once snapshot is ready',
    (tester) async {
      final repository = SessionRepository.instance;
      repository.clearAll();

      final notifier = SessionServiceNotifier(repository);
      final session = Session(
        id: 'session-count-loaded-wins',
        title: 'Loaded Wins',
        messages: const [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
        active: true,
        latestUsage: LatestUsage(
          messageCount: 9,
          tokenCount: 128,
          timestamp: DateTime.fromMillisecondsSinceEpoch(1772962444908),
        ),
      );

      repository.applySessions([session]);
      repository.applyMessages(session.id, [
        ReducerMessage(
          id: 'message-loaded-1',
          kind: 'text',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1772962443908),
          text: 'hello',
        ),
        ReducerMessage(
          id: 'message-loaded-2',
          kind: 'text',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1772962444908),
          metadata: const {'role': 'user'},
          text: 'world',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionStateProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SessionListItem(session: session),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('world'), findsOneWidget);
      expect(find.text('最近消息待同步'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      repository.clearAll();
    },
  );
}
