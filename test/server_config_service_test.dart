import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/core/config/server_config_service.dart';

void main() {
  test('built-in svton server points to hapmony domain', () {
    expect(
      ServerConfigService.svtonServerUrl,
      'https://hapmony.svton.cn',
    );

    final option = ServerConfigService.builtInServerOptions.firstWhere(
      (item) => item.id == ServerConfigService.svtonServerId,
    );

    expect(option.name, '开发者提供的国内服务器');
    expect(option.url, 'https://hapmony.svton.cn');
    expect(option.description, contains('我们 APP 开发者提供的国内服务器'));
  });
}
