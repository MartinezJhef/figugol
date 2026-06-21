import 'dart:convert';

class UserQrPayload {
  const UserQrPayload({
    required this.userId,
    required this.userName,
  });

  final String userId;
  final String userName;

  static const _typeKey = 'type';
  static const _typeValue = 'user_profile';
  static const _userIdKey = 'uid';
  static const _userNameKey = 'name';

  String toEncoded() {
    final map = {
      _typeKey: _typeValue,
      _userIdKey: userId,
      _userNameKey: userName,
    };
    return jsonEncode(map);
  }

  factory UserQrPayload.fromEncoded(String encoded) {
    try {
      final map = jsonDecode(encoded) as Map<String, dynamic>;
      
      if (map[_typeKey] != _typeValue) {
        throw const FormatException('QR no válido para intercambio directo.');
      }
      
      final uid = map[_userIdKey] as String?;
      if (uid == null || uid.isEmpty) {
        throw const FormatException('El QR no contiene un ID de usuario válido.');
      }

      final name = map[_userNameKey] as String? ?? 'Usuario';

      return UserQrPayload(
        userId: uid,
        userName: name,
      );
    } catch (e) {
      if (e is FormatException) rethrow;
      throw const FormatException('Formato de QR irreconocible.');
    }
  }
}
