/// 应用字符串常量
///
/// 统一管理的字符串资源
class AppStrings {
  AppStrings._();

  // ========== 通用 ==========
  static const String appName = '开心编码';
  static const String loading = '加载中...';
  static const String error = '错误';
  static const String retry = '重试';
  static const String cancel = '取消';
  static const String confirm = '确认';
  static const String delete = '删除';
  static const String save = '保存';
  static const String done = '完成';

  // ========== 认证 ==========
  static const String loginTitle = '登录开心编码';
  static const String scanQRCode = '扫码';
  static const String waitingForQR = '等待二维码...';
  static const String scanInstructions = '扫描电脑上显示的二维码';
  static const String logoutTitle = '退出登录';
  static const String logoutConfirm = '确认要退出登录吗？';
  static const String backupKeys = '备份密钥';
  static const String restoreKeys = '恢复密钥';
  static const String qrCodeExpired = '二维码已过期，请重新生成。';
  static const String qrCodeError = '二维码错误';

  // ========== 会话 ==========
  static const String sessions = '会话';
  static const String newSession = '新建会话';
  static const String activeSessions = '活跃';
  static const String archivedSessions = '已归档';
  static const String noSessions = '还没有会话';
  static const String startNewSession = '从电脑端开始新的会话';
  static const String connectToComputer = '连接电脑';

  // ========== 消息 ==========
  static const String sendMessage = '发送消息...';
  static const String thinking = '思考中...';
  static const String agent = '助手';
  static const String you = '你';
  static const String messageError = '消息发送失败';
  static const String copyMessage = '复制消息';
  static const String messageCopied = '消息已复制';

  // ========== 工具/权限 ==========
  static const String toolExecution = '工具执行';
  static const String permissionRequest = '权限请求';
  static const String allow = '允许';
  static const String deny = '拒绝';
  static const String allowForSession = '本会话允许';
  static const String allowAlways = '始终允许此工具';
  static const String runCommand = '运行命令';
  static const String viewCode = '查看代码';
  static const String viewDiff = '查看改动';

  // ========== 设置 ==========
  static const String settings = '设置';
  static const String theme = '主题';
  static const String language = '语言';
  static const String notifications = '通知';
  static const String privacy = '隐私';
  static const String terms = '服务条款';
  static const String about = '关于';
  static const String version = '版本';
  static const String clearCache = '清理缓存';
  static const String exportData = '导出数据';

  // ========== 实时语音 ==========
  static const String voiceAssistant = '语音助手';
  static const String connectingVoice = '正在连接语音...';
  static const String voiceConnected = '语音已连接';
  static const String voiceDisconnected = '语音已断开';
  static const String microphonePermission = '麦克风权限';
  static const String microphoneDenied = '未获得麦克风权限';

  // ========== 错误消息 ==========
  static const String networkError = '网络异常，请检查连接。';
  static const String serverError = '服务器异常，请稍后重试。';
  static const String authError = '认证失败，请重新登录。';
  static const String encryptionError = '加密异常，数据可能已损坏。';
  static const String sessionNotFound = '会话不存在或已被移除。';
  static const String connectionLost = '连接已断开，正在重连...';

  // ========== 鸿蒙特定 ==========
  static const String harmonySpecific = '鸿蒙';
  static const String platformNotSupported = '该功能在当前鸿蒙环境下暂未完全支持。';

  // ========== 单位 ==========
  static const String second = '秒';
  static const String minute = '分';
  static const String hour = '小时';
  static const String day = '天';
  static const String week = '周';
  static const String month = '月';
  static const String year = '年';
  static const String ago = '前';
}
