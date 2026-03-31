import 'package:flutter/material.dart';
import '../main.dart';
import 'chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isNetworking = false;

  @override
  void initState() {
    super.initState();
    nearbyService.onConnectionsChanged = () {
      if (mounted) setState(() {});
    };
    // Auto-start networking if permissions are granted
    _startNetworking();
  }

  Future<void> _startNetworking() async {
    setState(() => _isNetworking = true);
    await nearbyService.startNetworking();
  }

  void _stopNetworking() {
    nearbyService.stopNetworking();
    setState(() => _isNetworking = false);
  }

  @override
  Widget build(BuildContext context) {
    int totalUsers = databaseService.getAllUsers().length;
    int activeConnections = nearbyService.connectedEndpoints.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mesh Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF020617),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Stats Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        identityService.nickname ?? "Unknown",
                        style: const TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        identityService.deviceId,
                        style: TextStyle(
                          fontSize: 14, 
                          color: Colors.white.withOpacity(0.8),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(activeConnections.toString(), "Peers", Icons.bluetooth_connected),
                          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                          _buildStatItem(totalUsers.toString(), "Known", Icons.people_alt),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Network Control
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Network Status",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Switch(
                      value: _isNetworking,
                      onChanged: (val) {
                        if (val) {
                          _startNetworking();
                        } else {
                          _stopNetworking();
                        }
                      },
                      activeColor: Colors.greenAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: activeConnections == 0
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.radar, size: 60, color: Colors.white.withOpacity(0.2)),
                                const SizedBox(height: 16),
                                Text(
                                  _isNetworking ? "Scanning for peers..." : "Networking is off",
                                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                )
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: activeConnections,
                            itemBuilder: (context, index) {
                              String peerId = nearbyService.connectedEndpoints[index];
                              String peerName = databaseService.getUser(peerId) ?? "Unknown Peer ($peerId)";
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.blueAccent,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(peerName, style: const TextStyle(color: Colors.white)),
                                subtitle: const Text("Connected via Mesh", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                                trailing: const Icon(Icons.bluetooth, color: Colors.blueAccent),
                              );
                            },
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                // Chat Button
                ElevatedButton(
                  onPressed: activeConnections > 0 ? () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: activeConnections > 0 ? 10 : 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, color: Colors.white),
                      SizedBox(width: 12),
                      Text("Enter Global Chat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String val, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
        const SizedBox(height: 8),
        Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
      ],
    );
  }
}
