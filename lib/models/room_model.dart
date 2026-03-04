import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String name;
  final String building;
  final int capacity;
  final double latitude;
  final double longitude;
  final Map<String, int> wifiFingerprint; // BSSID -> RSSI

  RoomModel({
    required this.id,
    required this.name,
    required this.building,
    required this.capacity,
    required this.latitude,
    required this.longitude,
    this.wifiFingerprint = const {},
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      id: doc.id,
      name: data['name'] ?? '',
      building: data['building'] ?? '',
      capacity: data['capacity'] ?? 0,
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      wifiFingerprint: Map<String, int>.from(data['wifiFingerprint'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'building': building,
      'capacity': capacity,
      'latitude': latitude,
      'longitude': longitude,
      'wifiFingerprint': wifiFingerprint,
    };
  }
}
