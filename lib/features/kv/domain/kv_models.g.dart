// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kv_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KVItem _$KVItemFromJson(Map<String, dynamic> json) => KVItem(
      key: json['key'] as String,
      value: json['value'] as String,
      version: (json['version'] as num).toInt(),
    );

Map<String, dynamic> _$KVItemToJson(KVItem instance) => <String, dynamic>{
      'key': instance.key,
      'value': instance.value,
      'version': instance.version,
    };

KVBatchUpdateRequest _$KVBatchUpdateRequestFromJson(
        Map<String, dynamic> json) =>
    KVBatchUpdateRequest(
      mutations: (json['mutations'] as List<dynamic>)
          .map((e) => KVMutation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$KVBatchUpdateRequestToJson(
        KVBatchUpdateRequest instance) =>
    <String, dynamic>{
      'mutations': instance.mutations,
    };

KVMutation _$KVMutationFromJson(Map<String, dynamic> json) => KVMutation(
      key: json['key'] as String,
      value: json['value'] as String?,
      version: (json['version'] as num?)?.toInt(),
    );

Map<String, dynamic> _$KVMutationToJson(KVMutation instance) =>
    <String, dynamic>{
      'key': instance.key,
      'value': instance.value,
      'version': instance.version,
    };

KVListResponse _$KVListResponseFromJson(Map<String, dynamic> json) =>
    KVListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => KVItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$KVListResponseToJson(KVListResponse instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
