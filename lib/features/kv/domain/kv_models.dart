import 'package:json_annotation/json_annotation.dart';

part 'kv_models.g.dart';

/// KV 存储项模型
///
/// 用于存储键值对数据，支持版本控制
@JsonSerializable()
class KVItem {
  final String key;
  final String value;
  final int version;

  const KVItem({
    required this.key,
    required this.value,
    required this.version,
  });

  factory KVItem.fromJson(Map<String, dynamic> json) => _$KVItemFromJson(json);

  Map<String, dynamic> toJson() => _$KVItemToJson(this);

  KVItem copyWith({
    String? key,
    String? value,
    int? version,
  }) {
    return KVItem(
      key: key ?? this.key,
      value: value ?? this.value,
      version: version ?? this.version,
    );
  }
}

/// KV 批量更新请求
@JsonSerializable()
class KVBatchUpdateRequest {
  final List<KVMutation> mutations;

  const KVBatchUpdateRequest({required this.mutations});

  Map<String, dynamic> toJson() => <String, dynamic>{
    'mutations': mutations.map((m) => m.toJson()).toList(),
  };
}

/// KV 变更
@JsonSerializable()
class KVMutation {
  final String key;
  final String? value;
  final int? version;

  const KVMutation({
    required this.key,
    this.value,
    this.version,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'key': key,
    if (value != null) 'value': value,
    if (version != null) 'version': version,
  };
}

/// KV 获取响应
@JsonSerializable()
class KVListResponse {
  final List<KVItem> items;

  const KVListResponse({required this.items});

  factory KVListResponse.fromJson(Map<String, dynamic> json) => _$KVListResponseFromJson(json);
}
