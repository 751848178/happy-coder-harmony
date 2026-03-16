part of 'artifact_models.dart';

@JsonSerializable()
class ArtifactListResponse {
  final List<Artifact> items;
  final String? nextCursor;

  const ArtifactListResponse({
    required this.items,
    this.nextCursor,
  });

  factory ArtifactListResponse.fromJson(Map<String, dynamic> json) =>
      _$ArtifactListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ArtifactListResponseToJson(this);
}

@JsonSerializable()
class CreateArtifactRequest {
  final String id;
  final String header;
  final int? headerVersion;
  final String? body;
  final int? bodyVersion;
  final String dataEncryptionKey;

  const CreateArtifactRequest({
    required this.id,
    required this.header,
    this.headerVersion,
    this.body,
    this.bodyVersion,
    required this.dataEncryptionKey,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'header': header,
        if (headerVersion != null) 'headerVersion': headerVersion,
        if (body != null) 'body': body,
        if (bodyVersion != null) 'bodyVersion': bodyVersion,
        'dataEncryptionKey': dataEncryptionKey,
      };
}

@JsonSerializable()
class UpdateArtifactRequest {
  final String? header;
  final int? headerVersion;
  final String? body;
  final int? bodyVersion;

  const UpdateArtifactRequest({
    this.header,
    this.headerVersion,
    this.body,
    this.bodyVersion,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (header != null) 'header': header,
        if (headerVersion != null) 'headerVersion': headerVersion,
        if (body != null) 'body': body,
        if (bodyVersion != null) 'bodyVersion': bodyVersion,
      };
}
