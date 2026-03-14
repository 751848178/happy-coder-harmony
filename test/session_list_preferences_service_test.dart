import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/session/data/session_list_preferences_service.dart';

void main() {
  test('session list preferences json roundtrip keeps selected machine', () {
    const preferences = SessionListPreferences(
      selectedMachineId: 'machine-123',
    );

    final restored = SessionListPreferences.fromJson(preferences.toJson());

    expect(restored.selectedMachineId, 'machine-123');
    expect(restored.isDefault, isFalse);
  });

  test('default session list preferences omit empty machine selection', () {
    const preferences = SessionListPreferences();

    expect(preferences.selectedMachineId, isNull);
    expect(preferences.isDefault, isTrue);
    expect(preferences.toJson(), isEmpty);
  });

  test('copyWith can clear selected machine', () {
    const preferences = SessionListPreferences(
      selectedMachineId: 'machine-123',
    );

    final cleared = preferences.copyWith(selectedMachineId: null);

    expect(cleared.selectedMachineId, isNull);
    expect(cleared.isDefault, isTrue);
  });
}
