import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'identity_service.dart';
import 'database_service.dart';

class NearbyService {
  final IdentityService identityService;
  final DatabaseService databaseService;
  
  // Callbacks for UI updates
  Function()? onConnectionsChanged;
  Function(Map<String, dynamic>)? onMessageReceived;

  // Track connected peers
  final List<String> connectedEndpoints = [];

  // Strategy P2P_CLUSTER allows multiple M-to-N connections (Mesh)
  final Strategy strategy = Strategy.P2P_CLUSTER;

  NearbyService({required this.identityService, required this.databaseService});

  Future<bool> checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);
    return allGranted; // In a real app we might handle partial, but this suffices.
  }

  Future<void> startNetworking() async {
    final hasPerms = await checkPermissions();
    if (!hasPerms) return;

    final String userName = identityService.deviceId; // We use deviceId as endpointName

    try {
      await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: _onConnectionInit,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );

      await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
      );
    } catch (e) {
      print("Could not start networking: $e");
    }
  }

  void stopNetworking() {
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    connectedEndpoints.clear();
    onConnectionsChanged?.call();
  }

  // Advertising Callbacks
  void _onConnectionInit(String id, ConnectionInfo info) async {
    // Automatically accept the connection for the mesh
    await Nearby().acceptConnection(
      id,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: (id, payloadTransferUpdate) {},
    );
  }

  void _onConnectionResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      if (!connectedEndpoints.contains(id)) {
        connectedEndpoints.add(id);
      }
      onConnectionsChanged?.call();
      _syncLedgerWithPeer(id);
    } else if (status == Status.REJECTED || status == Status.ERROR) {
      connectedEndpoints.remove(id);
      onConnectionsChanged?.call();
    }
  }

  void _onDisconnected(String id) {
    connectedEndpoints.remove(id);
    onConnectionsChanged?.call();
  }

  // Discovery Callbacks
  void _onEndpointFound(String id, String endpointName, String serviceId) async {
    // Found someone! Let's request to connect
    try {
      await Nearby().requestConnection(
        identityService.deviceId,
        id,
        onConnectionInitiated: _onConnectionInit,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      print("Error requesting connection: $e");
    }
  }

  void _onEndpointLost(String? id) {
    print("Endpoint lost: $id");
  }

  // Payload Management
  void _onPayloadReceived(String endpointId, Payload payload) async {
    if (payload.type == PayloadType.BYTES) {
      String jsonString = String.fromCharCodes(payload.bytes!);
      try {
        Map<String, dynamic> data = jsonDecode(jsonString);
        _handleIncomingData(data);
      } catch (e) {
        print("Invalid payload: $e");
      }
    }
  }

  void _handleIncomingData(Map<String, dynamic> data) async {
    String type = data['type'];
    if (type == 'user_sync') {
      // Received the peer's known users ledger
      Map<String, dynamic> peerUsers = data['data'];
      await databaseService.mergeUsers(peerUsers);
    } else if (type == 'chat_message') {
      // Received a chat message
      Map<String, dynamic> message = data['data'];
      await databaseService.saveMessage(message);
      onMessageReceived?.call(message);
    }
  }

  // Blockchain/Ledger Sync
  void _syncLedgerWithPeer(String endpointId) {
    // Send our current knowledge of users (deviceId -> Nickname) to the newly connected peer
    Map<String, String> currentLedger = databaseService.getAllUsers();
    
    // Convert to Payload
    Map<String, dynamic> payloadMap = {
      'type': 'user_sync',
      'data': currentLedger,
    };
    String jsonString = jsonEncode(payloadMap);
    Nearby().sendBytesPayload(endpointId, Uint8List.fromList(jsonString.codeUnits));
  }

  // Broadcast Message to all connected peers
  void broadcastMessage(String text) {
    final message = {
      'id': const Uuid().v4(), // Need to import UUID here but it's fine, we can do it via a quick ID or random. No wait, I don't import uuid in this file. Let me just use timestamp + deviceId for unique id
      'senderId': identityService.deviceId,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    // Save to our own DB first
    databaseService.saveMessage(message);
    onMessageReceived?.call(message);

    Map<String, dynamic> payloadMap = {
      'type': 'chat_message',
      'data': message,
    };
    
    String jsonString = jsonEncode(payloadMap);
    Uint8List bytes = Uint8List.fromList(jsonString.codeUnits);
    
    for (String endpoint in connectedEndpoints) {
      try {
        Nearby().sendBytesPayload(endpoint, bytes);
      } catch (e) {
        print("Failed to send message to $endpoint: $e");
      }
    }
  }
}
