import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/app/services/happy_link_service.dart';

void main() {
  final service = HappyLinkService.instance;

  test('classifies terminal links separately from restore links', () {
    expect(
      service.isTerminalLink('happy://terminal?BASE64URL_PUBLIC_KEY'),
      isTrue,
    );
    expect(
      service.isRestoreLink('happy://terminal?BASE64URL_PUBLIC_KEY'),
      isFalse,
    );
  });

  test('classifies account links separately from restore links', () {
    expect(
      service.isAccountLink('happy:///account?base64url=BASE64URL_PUBLIC_KEY'),
      isTrue,
    );
    expect(
      service.isRestoreLink('happy:///account?base64url=BASE64URL_PUBLIC_KEY'),
      isFalse,
    );
  });

  test('classifies direct restore links', () {
    expect(service.isRestoreLink('happy://BASE64URL_SECRET'), isTrue);
    expect(service.isRestoreLink('handy://BASE64_SECRET'), isTrue);
    expect(service.isRestoreLink('https://happy.link/BASE64_SECRET'), isTrue);
  });
}
