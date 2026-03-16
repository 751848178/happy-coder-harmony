part of 'storage_models.dart';

class SessionStorageModelAdapter extends TypeAdapter<SessionStorageModel> {
  @override
  final int typeId = 100;

  @override
  SessionStorageModel read(BinaryReader reader) {
    return SessionStorageModel(
      id: reader.readString(),
      title: reader.readString(),
      messages: reader.readStringList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      lastAccessedAt: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      isPinned: reader.readBool(),
      isArchived: reader.readBool(),
      tag: reader.read() as String?,
      metadata: _normalizeStringDynamicMap(reader.read()),
    );
  }

  @override
  void write(BinaryWriter writer, SessionStorageModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeStringList(obj.messages);
    writer.write(obj.createdAt.millisecondsSinceEpoch);
    writer.write(obj.updatedAt.millisecondsSinceEpoch);
    writer.write(obj.lastAccessedAt.millisecondsSinceEpoch);
    writer.writeBool(obj.isPinned);
    writer.writeBool(obj.isArchived);
    writer.write(obj.tag);
    writer.write(obj.metadata);
  }
}

class MessageStorageModelAdapter extends TypeAdapter<MessageStorageModel> {
  @override
  final int typeId = 101;

  @override
  MessageStorageModel read(BinaryReader reader) {
    return MessageStorageModel(
      id: reader.readString(),
      sessionId: reader.readString(),
      content: reader.readString(),
      role: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      metadata: _normalizeStringDynamicMap(reader.read()),
    );
  }

  @override
  void write(BinaryWriter writer, MessageStorageModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.sessionId);
    writer.writeString(obj.content);
    writer.writeString(obj.role);
    writer.write(obj.createdAt.millisecondsSinceEpoch);
    writer.write(obj.metadata);
  }
}

class SearchKeywordAdapter extends TypeAdapter<SearchKeyword> {
  @override
  final int typeId = 102;

  @override
  SearchKeyword read(BinaryReader reader) {
    return SearchKeyword(
      id: reader.readString(),
      keyword: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.read()),
    );
  }

  @override
  void write(BinaryWriter writer, SearchKeyword obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.keyword);
    writer.write(obj.createdAt.millisecondsSinceEpoch);
  }
}
