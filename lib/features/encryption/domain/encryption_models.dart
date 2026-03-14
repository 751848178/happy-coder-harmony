part of 'encryption_service.dart';

/// 密钥对模型
class KeyPair {
  final String publicKey;
  final String secretKey;

  const KeyPair({
    required this.publicKey,
    required this.secretKey,
  });

  factory KeyPair.fromJson(Map<String, dynamic> json) {
    return KeyPair(
      publicKey: json['publicKey'] as String? ?? '',
      secretKey: json['secretKey'] as String? ?? '',
    );
  }
}

/// 加密状态
class EncryptionState {
  const EncryptionState._();

  static const EncryptionState initial = EncryptionState._();

  static EncryptionState hasKeys() => const _HasKeysState();
  static EncryptionState encrypting(bool isOwnKey) => _EncryptingState(isOwnKey);
  static EncryptionState decrypted(String data) => _DecryptedState(data);
  static EncryptionState error(String message) => _EncryptionErrorState(message);

  String? get decryptedData =>
      this is _DecryptedState ? (this as _DecryptedState).data : null;

  bool get isEncrypting => this is _EncryptingState;
  bool get isInitial => this is EncryptionState;
  bool get isHasKeys => this is _HasKeysState;
  bool get isDecrypted => this is _DecryptedState;
  bool get isError => this is _EncryptionErrorState;
  String? get errorMessage =>
      this is _EncryptionErrorState ? (this as _EncryptionErrorState).message : null;
  bool get isOwnKeyEncrypting =>
      this is _EncryptingState ? (this as _EncryptingState).isOwnKey : false;
}

class _HasKeysState extends EncryptionState {
  const _HasKeysState() : super._();
}

class _EncryptingState extends EncryptionState {
  final bool isOwnKey;

  const _EncryptingState(this.isOwnKey) : super._();
}

class _DecryptedState extends EncryptionState {
  final String data;

  const _DecryptedState(this.data) : super._();
}

class _EncryptionErrorState extends EncryptionState {
  final String message;

  const _EncryptionErrorState(this.message) : super._();
}
