import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';

Future<T?> openSessionDetail<T>({
  required BuildContext context,
  required WidgetRef ref,
  required String sessionId,
}) async {
  final provider = ref.read(activeSessionDetailIdProvider.notifier);
  final previousSessionId = ref.read(activeSessionDetailIdProvider);
  provider.state = sessionId;
  try {
    return await context.push<T>(AppRoutes.sessionDetail(sessionId));
  } catch (_) {
    if (ref.read(activeSessionDetailIdProvider) == sessionId) {
      provider.state = previousSessionId;
    }
    rethrow;
  }
}

void replaceWithSessionDetail({
  required BuildContext context,
  required WidgetRef ref,
  required String sessionId,
}) {
  ref.read(activeSessionDetailIdProvider.notifier).state = sessionId;
  context.pushReplacement(AppRoutes.sessionDetail(sessionId));
}

void goToSessionDetail({
  required BuildContext context,
  required WidgetRef ref,
  required String sessionId,
}) {
  ref.read(activeSessionDetailIdProvider.notifier).state = sessionId;
  context.go(AppRoutes.sessionDetail(sessionId));
}
