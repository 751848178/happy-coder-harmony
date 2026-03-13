import 'package:json_annotation/json_annotation.dart';

part 'session_files_models.g.dart';

/// 会话文件模型
///
/// 表示会话关联的文件信息
@JsonSerializable()
class SessionFile {
  final String id;
  final String sessionId;
  final String filePath;
  final String fileName;
  final int? size;
  final String? mimeType;
  final int createdAt;
  final int updatedAt;

  const SessionFile({
    required this.id,
    required this.sessionId,
    required this.filePath,
    required this.fileName,
    this.size,
    this.mimeType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SessionFile.fromJson(Map<String, dynamic> json) => _$SessionFileFromJson(json);

  Map<String, dynamic> toJson() => _$SessionFileToJson(this);

  SessionFile copyWith({
    String? id,
    String? sessionId,
    String? filePath,
    String? fileName,
    int? size,
    String? mimeType,
    int? createdAt,
    int? updatedAt,
  }) {
    return SessionFile(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 文件列表响应
@JsonSerializable()
class SessionFilesResponse {
  final List<SessionFile> items;
  final String? nextCursor;
  final int? totalCount;

  const SessionFilesResponse({
    required this.items,
    this.nextCursor,
    this.totalCount,
  });

  factory SessionFilesResponse.fromJson(Map<String, dynamic> json) =>
      _$SessionFilesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SessionFilesResponseToJson(this);
}

/// 上传文件请求
@JsonSerializable()
class UploadFileRequest {
  final String sessionId;
  final String? localPath;
  final String? base64Data;

  const UploadFileRequest({
    required this.sessionId,
    this.localPath,
    this.base64Data,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'sessionId': sessionId,
      if (localPath != null) 'localPath': localPath,
      if (base64Data != null) 'base64Data': base64Data,
    };
    return json;
  }
}

/// 文件操作类型
enum FileOperationType {
  read,
  write,
  delete,
}

/// 文件操作历史
@JsonSerializable()
class FileOperation {
  final String id;
  final String sessionId;
  final FileOperationType operation;
  final String? filePath;
  final String? oldContent;
  final String? newContent;
  final String? errorMessage;
  final int? duration;
  final DateTime timestamp;

  const FileOperation({
    required this.id,
    required this.sessionId,
    required this.operation,
    this.filePath,
    this.oldContent,
    this.newContent,
    this.errorMessage,
    this.duration,
    required this.timestamp,
  });

  factory FileOperation.fromJson(Map<String, dynamic> json) => _$FileOperationFromJson(json);

  Map<String, dynamic> toJson() => _$FileOperationToJson(this);

  FileOperation copyWith({
    String? id,
    String? sessionId,
    FileOperationType? operation,
    String? filePath,
    String? oldContent,
    String? newContent,
    String? errorMessage,
    int? duration,
    DateTime? timestamp,
  }) {
    return FileOperation(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      operation: operation ?? this.operation,
      filePath: filePath ?? this.filePath,
      oldContent: oldContent ?? this.oldContent,
      newContent: newContent ?? this.newContent,
      errorMessage: errorMessage ?? this.errorMessage,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
