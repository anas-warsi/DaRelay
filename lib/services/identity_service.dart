import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class IdentityService {
  static const String _boxName = 'identity_box';
  static const String _idKey = 'device_id';
  static const String _nicknameKey = 'nickname';

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    
    // Generate a permanent MAC-like ID if one doesn't exist
    if (!_box.containsKey(_idKey)) {
      final String newId = _generateMacLikeId();
      await _box.put(_idKey, newId);
    }
  }

  String _generateMacLikeId() {
    final uuid = const Uuid().v4().replaceAll('-', '');
    // Format as MAC Address: 0A:1B:2C:3D:4E:5F
    String mac = '';
    for (int i = 0; i < 12; i += 2) {
      mac += uuid.substring(i, i + 2).toUpperCase();
      if (i < 10) mac += ':';
    }
    return mac;
  }

  String get deviceId {
    return _box.get(_idKey, defaultValue: '00:00:00:00:00:00');
  }

  String? get nickname {
    return _box.get(_nicknameKey);
  }

  Future<void> setNickname(String name) async {
    await _box.put(_nicknameKey, name);
  }

  bool get hasNickname => _box.containsKey(_nicknameKey);
}
