Map<String, String>? _cleanQuery(Map<String, String?> values) {
  final query = <String, String>{};
  for (final entry in values.entries) {
    final value = entry.value;
    if (value != null && value.isNotEmpty) {
      query[entry.key] = value;
    }
  }
  return query.isEmpty ? null : query;
}

String sessionDetail(String sessionId) => '/session/$sessionId';
String sessionDetailLegacy(String sessionId) => '/session?id=$sessionId';
String sessionInfoDetail(String sessionId) => '/session/$sessionId/info';
String sessionFilesDetail(String sessionId) => '/session/$sessionId/files';
String sessionGitDetail(String sessionId) => '/session/$sessionId/git';
String sessionFileDetail(String sessionId) => '/session/$sessionId/file';
String sessionMessage(String sessionId, String messageId) =>
    '/session/$sessionId/message/$messageId';
String machine(String machineId) => '/machine/$machineId';
String userProfileDetail(String userId) => '/user/$userId';
String userProfileDetailLegacy(String userId) => '/user/profile?id=$userId';
String artifact(String artifactId) => '/artifacts/$artifactId';
String editArtifactWithId(String artifactId) => '/artifacts/edit/$artifactId';

String newPathPicker({String? machineId, String? path}) {
  return Uri(
    path: '/new/pick/path',
    queryParameters: _cleanQuery({'machineId': machineId, 'path': path}),
  ).toString();
}

String newClonedSession({
  String? machineId,
  String? path,
  String? agent,
  String? permissionMode,
  String? modelMode,
}) {
  return Uri(
    path: '/new',
    queryParameters: _cleanQuery({
      'machineId': machineId,
      'path': path,
      'agent': agent,
      'permissionMode': permissionMode,
      'modelMode': modelMode,
    }),
  ).toString();
}

String terminalApprovalDetail({
  required String requestId,
  required String sessionId,
  required String machine,
  required String path,
  String? command,
  String? requestingApp,
}) {
  return Uri(
    path: '/terminal/terminal-approval',
    queryParameters: _cleanQuery({
      'id': requestId,
      'sessionId': sessionId,
      'machine': machine,
      'path': path,
      'command': command,
      'requestingApp': requestingApp,
    }),
  ).toString();
}
