part of 'login_test_screen.dart';

Future<void> _runLoginFullTest(_LoginTestScreenState state) async {
  if (state._isRunning) {
    return;
  }
  state._setRunning(true);
  state._clearLogs();

  try {
    state._addLog(LogType.info, '步骤1', '验证输入链接', state._linkController.text);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final linkUrl = state._linkController.text.trim();
    if (linkUrl.isEmpty) {
      state._addLog(LogType.error, '步骤1', '链接为空', null);
      return;
    }
    if (!linkUrl.startsWith('happy://')) {
      state._addLog(LogType.warning, '步骤1', '链接格式不正确', '应以 happy:// 开头');
      return;
    }
    state._addLog(LogType.success, '步骤1', '输入验证通过', '链接长度: ${linkUrl.length}');

    state._addLog(LogType.info, '步骤2', '解析链接', null);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final secretKey = linkUrl.substring(8);
    state._addLog(
        LogType.success, '步骤2', '链接解析成功', 'Secret key 长度: ${secretKey.length}');
    state._addLog(
      LogType.info,
      '步骤2',
      'Secret key (前100字符)',
      secretKey.length > 100 ? secretKey.substring(0, 100) : secretKey,
    );

    state._addLog(LogType.info, '步骤3', '检查存储服务', null);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    TokenStorageService.instance;
    state._addLog(LogType.success, '步骤3', '存储服务已初始化', null);

    state._addLog(LogType.info, '步骤4', '检查登录状态', null);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final authRepo = AuthRepository.instance;
    final isAuthenticated = await authRepo.isAuthenticated();
    state._addLog(LogType.success, '步骤4', '登录状态检查完成', '已登录: $isAuthenticated');

    state._addLog(
        LogType.info, '步骤5', '调用登录 API', 'AuthRepository.loginWithSecretKey');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final stopwatch = Stopwatch()..start();
    final response = await authRepo.loginWithSecretKey(secretKey);
    stopwatch.stop();
    state._addLog(
      LogType.success,
      '步骤5',
      '登录 API 调用成功',
      '耗时: ${stopwatch.elapsedMilliseconds}ms',
    );
    state._addLog(
      LogType.info,
      '步骤5',
      '响应 Token (前50字符)',
      response.token.length > 50
          ? response.token.substring(0, 50)
          : response.token,
    );
    state._addLog(LogType.info, '步骤5', 'Machine ID', response.machineId);
    state._addLog(
        LogType.info, '步骤5', 'Encryption Type', response.encryptionType.name);
    state._addLog(
      LogType.info,
      '步骤5',
      'Public Key',
      response.publicKey?.substring(0, 50) ?? 'null',
    );
    state._addLog(
      LogType.info,
      '步骤5',
      'Machine Key',
      response.machineKey?.substring(0, 50) ?? 'null',
    );

    state._addLog(LogType.info, '步骤6', '保存凭证到存储', null);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final storage = TokenStorageService.instance;
    await storage.saveToken(response.token);
    await storage.saveMachineId(response.machineId);
    await storage.saveEncryptionType(response.encryptionType);
    if (response.encryptionKey != null) {
      await storage.saveEncryptionKey(response.encryptionKey!);
    }
    if (response.publicKey != null) {
      await storage.savePublicKey(response.publicKey!);
    }
    if (response.machineKey != null) {
      await storage.saveMachineKey(response.machineKey!);
    }
    state._addLog(LogType.success, '步骤6', '凭证保存成功', null);

    state._addLog(LogType.info, '步骤7', '验证保存的凭证', null);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final credentials = await authRepo.getCredentials();
    if (credentials == null) {
      state._addLog(LogType.error, '步骤7', '凭证验证失败', '无法读取保存的凭证');
      return;
    }
    state._addLog(
      LogType.success,
      '步骤7',
      '凭证验证成功',
      'Token 长度: ${credentials.token.length}',
    );

    state._addLog(LogType.info, '步骤8', '更新认证状态', null);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await state.ref
        .read(authStateProvider.notifier)
        .applyLoginResponse(response, secret: secretKey);
    state._addLog(LogType.success, '步骤8', '认证状态已更新', null);
    state._addLog(LogType.success, '完成', '登录流程测试全部通过！', '可以点击返回按钮进入主页');
  } on Exception catch (error) {
    state._addLog(LogType.error, '步骤5', '登录 API 调用失败', error.toString());
    Logger.error('Login test failed: $error');
  } catch (error) {
    state._addLog(LogType.error, '异常', '测试过程中发生未捕获的异常', error.toString());
    Logger.error('Test exception: $error');
  } finally {
    state._setRunning(false);
  }
}

void _testLoginLinkParsing(_LoginTestScreenState state) {
  state._clearLogs();
  final linkUrl = state._linkController.text.trim();
  state._addLog(LogType.info, '测试', '链接解析测试', linkUrl);
  if (linkUrl.isEmpty) {
    state._addLog(LogType.error, '测试', '链接为空', null);
    return;
  }
  if (linkUrl.startsWith('happy://')) {
    final value = linkUrl.substring(8);
    state._addLog(
        LogType.success, '测试', 'happy:// 格式识别成功', '值长度: ${value.length}');
    state._addLog(
      LogType.info,
      '测试',
      '提取的值',
      value.length > 200 ? value.substring(0, 200) : value,
    );
    return;
  }
  if (linkUrl.startsWith('handy://')) {
    state._addLog(LogType.warning, '测试', 'handy:// 格式识别（旧格式）', '已废弃');
    return;
  }
  state._addLog(LogType.error, '测试', '无法识别链接格式',
      '支持 happy://xxx 或 https://happy.link/xxxxx');
}

Future<void> _testLoginStorage(_LoginTestScreenState state) async {
  state._clearLogs();
  state._addLog(LogType.info, '测试', '存储测试', null);
  try {
    final storage = TokenStorageService.instance;
    await storage.write(
      key: 'test_key',
      value: 'test_value_${DateTime.now().millisecondsSinceEpoch}',
    );
    state._addLog(LogType.success, '测试', '写入成功', null);
    final value = await storage.read('test_key');
    state._addLog(LogType.success, '测试', '读取成功', value ?? 'null');
    await storage.delete('test_key');
    state._addLog(LogType.success, '测试', '删除成功', null);
    final deletedValue = await storage.read('test_key');
    state._addLog(
      deletedValue == null ? LogType.success : LogType.warning,
      '测试',
      deletedValue == null ? '删除验证成功' : '删除验证失败',
      deletedValue == null ? 'key 不存在' : 'key 仍然存在',
    );
  } catch (error) {
    state._addLog(LogType.error, '测试', '存储测试失败', error.toString());
  }
}

Future<void> _clearLoginCredentials(_LoginTestScreenState state) async {
  state._clearLogs();
  state._addLog(LogType.info, '操作', '清除凭证', null);
  try {
    final storage = TokenStorageService.instance;
    await storage.clearAll();
    state._addLog(LogType.success, '操作', '凭证已清除', null);
    final token = await storage.getToken();
    state._addLog(LogType.info, '验证', 'Token 是否存在', token != null ? '是' : '否');
  } catch (error) {
    state._addLog(LogType.error, '操作', '清除凭证失败', error.toString());
  }
}
