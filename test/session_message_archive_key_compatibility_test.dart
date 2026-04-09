import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/storage/data/hive_repository.dart';

void main() {
  test('parseSessionMessageArchiveIndexFromKey supports canonical archive keys',
      () {
    expect(
      parseSessionMessageArchiveIndexFromKey(
        'session-1::archive::0000000247',
        prefix: 'session-1::archive::',
      ),
      247,
    );
  });

  test('parseSessionMessageArchiveIndexFromKey supports legacy archive keys',
      () {
    expect(
      parseSessionMessageArchiveIndexFromKey(
        'session-1::archive::0000000247::msg-legacy',
        prefix: 'session-1::archive::',
      ),
      247,
    );
  });

  test('parseSessionMessageArchiveIndexFromKey ignores unrelated keys', () {
    expect(
      parseSessionMessageArchiveIndexFromKey(
        'session-2::messages::0000000247',
        prefix: 'session-1::archive::',
      ),
      isNull,
    );
  });
}
