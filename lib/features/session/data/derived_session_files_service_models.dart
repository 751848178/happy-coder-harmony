part of 'derived_session_files_service.dart';

class _DerivedSessionFile {
  _DerivedSessionFile({
    required this.sessionId,
    required this.path,
    required this.createdAt,
    required this.updatedAt,
  });

  final String sessionId;
  final String path;
  DateTime createdAt;
  DateTime updatedAt;
  int? size;
  String? mimeType;
  String? content;

  void absorb({
    required DateTime timestamp,
    String? content,
    int? size,
    String? mimeType,
  }) {
    if (timestamp.isBefore(createdAt)) {
      createdAt = timestamp;
    }
    if (timestamp.isAfter(updatedAt)) {
      updatedAt = timestamp;
    }
    if (content != null && content.isNotEmpty) {
      this.content = content;
      this.size = size ?? utf8.encode(content).length;
    } else if (size != null) {
      this.size = size;
    }
    if (mimeType != null && mimeType.isNotEmpty) {
      this.mimeType = mimeType;
    }
  }

  SessionFile toSessionFile() {
    return SessionFile(
      id: 'derived:${base64Url.encode(utf8.encode(path))}',
      sessionId: sessionId,
      filePath: path,
      fileName: path.split('/').last,
      size: size,
      mimeType: mimeType,
      createdAt: createdAt.millisecondsSinceEpoch,
      updatedAt: updatedAt.millisecondsSinceEpoch,
    );
  }
}
