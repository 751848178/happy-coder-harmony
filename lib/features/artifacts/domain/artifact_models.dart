import 'package:json_annotation/json_annotation.dart';

part 'artifact_models.g.dart';
part 'artifact_models_requests.dart';

/// Artifact 工件模型
///
/// 表示一个文件或代码工件，支持版本控制
@JsonSerializable()
class Artifact {
  /// 工件唯一标识符
  final String id;

  /// 工件标题
  final String? title;

  /// 工件描述
  final String? description;

  /// 工件类型 (file, code, snippet, etc.)
  final String? type;

  /// 工件关联的会话 ID
  final String? sessionId;

  /// 文件路径 (如果是文件类型)
  final String? filePath;

  /// 文件大小 (字节)
  final int? size;

  /// MIME 类型
  final String? mimeType;

  /// 语言标识符 (用于代码高亮)
  final String? language;

  /// 缩略图数据 (用于图片预览)
  final String? thumbnail;

  /// 头数据 (加密的元数据)
  final String? header;

  /// 头版本号
  final int? headerVersion;

  /// 主体数据 (加密的内容)
  final String? body;

  /// 主体版本号
  final int? bodyVersion;

  /// 数据加密密钥 (DEK)
  final String? dataEncryptionKey;

  /// 创建时间戳
  final int createdAt;

  /// 更新时间戳
  final int updatedAt;

  /// 序列号
  final int seq;

  /// 是否已加载
  final bool isLoaded;

  /// 加载进度 (0.0 - 1.0)
  final double? loadProgress;

  /// 加载错误信息
  final String? loadError;

  const Artifact({
    required this.id,
    this.title,
    this.description,
    this.type,
    this.sessionId,
    this.filePath,
    this.size,
    this.mimeType,
    this.language,
    this.thumbnail,
    this.header,
    this.headerVersion,
    this.body,
    this.bodyVersion,
    this.dataEncryptionKey,
    required this.createdAt,
    required this.updatedAt,
    required this.seq,
    this.isLoaded = false,
    this.loadProgress,
    this.loadError,
  });

  factory Artifact.fromJson(Map<String, dynamic> json) =>
      _$ArtifactFromJson(json);

  Map<String, dynamic> toJson() => _$ArtifactToJson(this);

  Artifact copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? sessionId,
    String? filePath,
    int? size,
    String? mimeType,
    String? language,
    String? thumbnail,
    String? header,
    int? headerVersion,
    String? body,
    int? bodyVersion,
    String? dataEncryptionKey,
    int? createdAt,
    int? updatedAt,
    int? seq,
    bool? isLoaded,
    double? loadProgress,
    String? loadError,
  }) {
    return Artifact(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      sessionId: sessionId ?? this.sessionId,
      filePath: filePath ?? this.filePath,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      language: language ?? this.language,
      thumbnail: thumbnail ?? this.thumbnail,
      header: header ?? this.header,
      headerVersion: headerVersion ?? this.headerVersion,
      body: body ?? this.body,
      bodyVersion: bodyVersion ?? this.bodyVersion,
      dataEncryptionKey: dataEncryptionKey ?? this.dataEncryptionKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      seq: seq ?? this.seq,
      isLoaded: isLoaded ?? this.isLoaded,
      loadProgress: loadProgress ?? this.loadProgress,
      loadError: loadError ?? this.loadError,
    );
  }
}
