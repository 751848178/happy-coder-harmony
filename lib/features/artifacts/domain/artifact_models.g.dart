// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artifact_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Artifact _$ArtifactFromJson(Map<String, dynamic> json) => Artifact(
      id: json['id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String?,
      sessionId: json['sessionId'] as String?,
      filePath: json['filePath'] as String?,
      size: (json['size'] as num?)?.toInt(),
      mimeType: json['mimeType'] as String?,
      language: json['language'] as String?,
      thumbnail: json['thumbnail'] as String?,
      header: json['header'] as String?,
      headerVersion: (json['headerVersion'] as num?)?.toInt(),
      body: json['body'] as String?,
      bodyVersion: (json['bodyVersion'] as num?)?.toInt(),
      dataEncryptionKey: json['dataEncryptionKey'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
      seq: (json['seq'] as num).toInt(),
      isLoaded: json['isLoaded'] as bool? ?? false,
      loadProgress: (json['loadProgress'] as num?)?.toDouble(),
      loadError: json['loadError'] as String?,
    );

Map<String, dynamic> _$ArtifactToJson(Artifact instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'type': instance.type,
      'sessionId': instance.sessionId,
      'filePath': instance.filePath,
      'size': instance.size,
      'mimeType': instance.mimeType,
      'language': instance.language,
      'thumbnail': instance.thumbnail,
      'header': instance.header,
      'headerVersion': instance.headerVersion,
      'body': instance.body,
      'bodyVersion': instance.bodyVersion,
      'dataEncryptionKey': instance.dataEncryptionKey,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'seq': instance.seq,
      'isLoaded': instance.isLoaded,
      'loadProgress': instance.loadProgress,
      'loadError': instance.loadError,
    };

ArtifactListResponse _$ArtifactListResponseFromJson(
        Map<String, dynamic> json) =>
    ArtifactListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => Artifact.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$ArtifactListResponseToJson(
        ArtifactListResponse instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
    };

CreateArtifactRequest _$CreateArtifactRequestFromJson(
        Map<String, dynamic> json) =>
    CreateArtifactRequest(
      id: json['id'] as String,
      header: json['header'] as String,
      headerVersion: (json['headerVersion'] as num?)?.toInt(),
      body: json['body'] as String?,
      bodyVersion: (json['bodyVersion'] as num?)?.toInt(),
      dataEncryptionKey: json['dataEncryptionKey'] as String,
    );

Map<String, dynamic> _$CreateArtifactRequestToJson(
        CreateArtifactRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'header': instance.header,
      'headerVersion': instance.headerVersion,
      'body': instance.body,
      'bodyVersion': instance.bodyVersion,
      'dataEncryptionKey': instance.dataEncryptionKey,
    };

UpdateArtifactRequest _$UpdateArtifactRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateArtifactRequest(
      header: json['header'] as String?,
      headerVersion: (json['headerVersion'] as num?)?.toInt(),
      body: json['body'] as String?,
      bodyVersion: (json['bodyVersion'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UpdateArtifactRequestToJson(
        UpdateArtifactRequest instance) =>
    <String, dynamic>{
      'header': instance.header,
      'headerVersion': instance.headerVersion,
      'body': instance.body,
      'bodyVersion': instance.bodyVersion,
    };
