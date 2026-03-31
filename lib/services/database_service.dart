import 'package:hive/hive.dart';

class DatabaseService {
  static const String _usersBoxName = 'users_box';
  static const String _messagesBoxName = 'messages_box';

  late Box _usersBox;
  late Box _messagesBox;

  Future<void> init() async {
    _usersBox = await Hive.openBox(_usersBoxName);
    _messagesBox = await Hive.openBox(_messagesBoxName);
  }

  // --- Users Ledger (Blockchain-like) ---
  
  // Saves a user to the local ledger.
  // We use deviceId (MAC) as the key.
  Future<void> saveUser(String deviceId, String nickname) async {
    await _usersBox.put(deviceId, nickname);
  }

  // Gets a specific user's nickname by MAC.
  String? getUser(String deviceId) {
    return _usersBox.get(deviceId) as String?;
  }

  // Retrieves all known users in the entire network that this device has seen.
  Map<String, String> getAllUsers() {
    final Map<String, String> users = {};
    for (final key in _usersBox.keys) {
      users[key.toString()] = _usersBox.get(key).toString();
    }
    return users;
  }

  // Receives a batch of users from another peer and merges them into our local ledger.
  Future<void> mergeUsers(Map<String, dynamic> peerUsers) async {
    for (final entry in peerUsers.entries) {
      if (!_usersBox.containsKey(entry.key)) {
        await _usersBox.put(entry.key, entry.value.toString());
      }
    }
  }

  // --- Messages ---
  
  // Saves a message chat
  Future<void> saveMessage(Map<String, dynamic> message) async {
    // message must have 'id', 'senderId', 'text', 'timestamp'
    final String msgId = message['id'].toString();
    if (!_messagesBox.containsKey(msgId)) {
      await _messagesBox.put(msgId, message);
    }
  }

  // Get all messages sorted by timestamp
  List<Map<String, dynamic>> getAllMessages() {
    final List<Map<String, dynamic>> messages = [];
    for (final key in _messagesBox.keys) {
      final value = _messagesBox.get(key);
      if (value is Map) {
         messages.add(Map<String, dynamic>.from(value));
      }
    }
    messages.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
    return messages;
  }
}
