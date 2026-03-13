// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_files_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionFile _$SessionFileFromJson(Map<String, dynamic> json) => SessionFile(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      size: (json['size'] as num?)?.toInt(),
      mimeType: json['mimeType'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$SessionFileToJson(SessionFile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'filePath': instance.filePath,
      'fileName': instance.fileName,
      'size': instance.size,
      'mimeType': instance.mimeType,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

SessionFilesResponse _$SessionFilesResponseFromJson(
        Map<String, dynamic> json) =>
    SessionFilesResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => SessionFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      totalCount: (json['totalCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SessionFilesResponseToJson(
        SessionFilesResponse instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
      'totalCount': instance.totalCount,
    };

UploadFileRequest _$UploadFileRequestFromJson(Map<String, dynamic> json) =>
    UploadFileRequest(
      sessionId: json['sessionId'] as String,
      localPath: json['localPath'] as String?,
      base64Data: json['base64Data'] as String?,
    );

Map<String, dynamic> _$UploadFileRequestToJson(UploadFileRequest instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'localPath': instance.localPath,
      'base64Data': instance.base64Data,
    };

FileOperation _$FileOperationFromJson(Map<String, dynamic> json) =>
    FileOperation(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      operation: $enumDecode(_$FileOperationTypeEnumMap, json['operation']),
      filePath: json['filePath'] as String?,
      oldContent: json['oldContent'] as String?,
      newContent: json['newContent'] as String?,
      errorMessage: json['errorMessage'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$FileOperationToJson(FileOperation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'operation': _$FileOperationTypeEnumMap[instance.operation]!,
      'filePath': instance.filePath,
      'oldContent': instance.oldContent,
      'newContent': instance.newContent,
      'errorMessage': instance.errorMessage,
      'duration': instance.duration,
      'timestamp': instance.timestamp.toIso8601String(),
    };

const _$FileOperationTypeEnumMap = {
  FileOperationType.read: 'read',
  FileOperationType.write: 'write',
  FileOperationType.delete: 'delete',
};
