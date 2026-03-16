import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:happy_coder_flutter/app/providers/app_providers.dart';
import 'package:happy_coder_flutter/features/chat/components/session_list.dart';
import 'package:happy_coder_flutter/features/session/data/session_repository.dart';

void main() {
  testWidgets(
    'session list item shows refreshed count from sessionMessages',
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

      expect(find.text('2'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      repository.clearAll();
    },
  );
}
