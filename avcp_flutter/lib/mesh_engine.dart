import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The AVCP Ghost Mesh UUID space.
final Uuid _avcpMeshServiceUuid = Uuid.parse('12345678-1234-5678-1234-56789abcdef0');

// ══════════════════════════════════════════════════════════════════════
// Providers
// ══════════════════════════════════════════════════════════════════════

/// Monitors core internet connectivity mapping to Mesh Failover triggers.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Exposes the active MeshEngine state globally.
final meshEngineProvider = Provider<MeshEngine>((ref) {
  final engine = MeshEngine();
  
  // Listen to connectivity drops to automatically fire Ad-Hoc networks.
  ref.listen(connectivityProvider, (previous, next) {
    if (next.value != null && next.value!.contains(ConnectivityResult.none)) {
      debugPrint("📡 NETWORK BLACKOUT DETECTED: Booting P2P Ghost Mesh...");
      engine.startMeshNode('local_user_zone_id_placeholder');
    } else {
      engine.stopMeshNode();
    }
  });

  ref.onDispose(engine.dispose);
  return engine;
});

// ══════════════════════════════════════════════════════════════════════
// Ghost Mesh Core
// ══════════════════════════════════════════════════════════════════════

class MeshEngine {
  final FlutterReactiveBle? _ble = kIsWeb ? null : FlutterReactiveBle();
  StreamSubscription? _scanSubscription;

  /// Holds recently discovered off-grid peer packets.
  final Map<String, CongestionPacket> _meshDb = {};

  // 1. Serialization (The 31-byte advertising payload)
  List<int> encodePacket(String zoneId, double bottleneckScore) {
    // 31 bytes total BLE limit.
    // 16 bytes for UUID (implied by service advertisement usually, but let's manual).
    // Let's pack strictly into Manufacturer Data.
    final ByteData data = ByteData(10); // Minimal physical payload.
    
    // Bytes 0-3: Timestamp Delta (secs since epoch modulo trick)
    final int tsRaw = (DateTime.now().millisecondsSinceEpoch ~/ 1000) & 0xFFFFFFFF;
    data.setUint32(0, tsRaw, Endian.little);
    
    // Bytes 4-7: bottleneck score representation. (Float32)
    data.setFloat32(4, bottleneckScore, Endian.little);
    
    // Bytes 8-X: Zone ID string bytes (Truncated if required)
    List<int> zoneBytes = utf8.encode(zoneId);
    if (zoneBytes.length > 10) zoneBytes = zoneBytes.sublist(0, 10);
    
    return [
      ...data.buffer.asUint8List(),
      ...zoneBytes,
    ];
  }

  CongestionPacket? decodePacket(List<int> rawData) {
    try {
      if (rawData.length < 9) return null;
      
      final byteData = ByteData.sublistView(Uint8List.fromList(rawData));
      final int ts = byteData.getUint32(0, Endian.little);
      final double score = byteData.getFloat32(4, Endian.little);
      final String zone = utf8.decode(rawData.sublist(8));
      
      return CongestionPacket(
        zoneId: zone,
        bottleneckScore: score,
        timestampEpoch: ts,
      );
    } catch (e) {
      return null;
    }
  }

  // 2. Transmit & Receive Phase
  
  void startMeshNode(String currentZone, {double currentScore = 0.0}) {
    _startPeripheralAdvertising(currentZone, currentScore);
    _startCentralScanning();
  }
  
  void stopMeshNode() {
    _scanSubscription?.cancel();
    _stopPeripheralAdvertising();
  }

  void _startCentralScanning() {
    if (kIsWeb || _ble == null) return;
    
    _scanSubscription?.cancel();
    _scanSubscription = _ble!.scanForDevices(
      withServices: [_avcpMeshServiceUuid],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      final manufacturerData = device.manufacturerData;
      if (manufacturerData.isNotEmpty) {
        final packet = decodePacket(manufacturerData);
        if (packet != null) {
          _meshDb[packet.zoneId] = packet;
          debugPrint("🟦 [GHOST MESH] Received peer vector: ${packet.zoneId} @ ${packet.bottleneckScore}");
        }
      }
    }, onError: (Object e) {
      debugPrint("BLE Scan Error: $e");
    });
  }

  void _startPeripheralAdvertising(String zone, double score) {
    final List<int> payload = encodePacket(zone, score);
    // Note: flutter_reactive_ble is strictly Central-role (Scanning).
    // In production, Native Platform Channels (Android BLE Advertiser / iOS CBPeripheralManager)
    // transmit `payload` natively to broadcast offline physics data.
    debugPrint("🟦 [GHOST MESH] Peripheral Advertiser stub armed: Broadcasting $payload");
  }

  void _stopPeripheralAdvertising() {
    // Teardown platform channels.
  }

  void dispose() {
    stopMeshNode();
  }
}

// ══════════════════════════════════════════════════════════════════════
// Data Schema
// ══════════════════════════════════════════════════════════════════════

class CongestionPacket {
  final String zoneId;
  final double bottleneckScore;
  final int timestampEpoch;

  const CongestionPacket({
    required this.zoneId,
    required this.bottleneckScore,
    required this.timestampEpoch,
  });
}
