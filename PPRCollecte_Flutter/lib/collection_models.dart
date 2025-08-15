import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum CollectionType { ligne, chaussee }

enum CollectionStatus { inactive, active, paused }

class CollectionBase {
  final String id;
  final String provisionalName;
  final CollectionType type;
  final CollectionStatus status;
  final List<LatLng> points;
  final DateTime startTime;
  final DateTime? lastPointTime;
  final double totalDistance;

  CollectionBase({
    required this.id,
    required this.provisionalName,
    required this.type,
    required this.status,
    required this.points,
    required this.startTime,
    this.lastPointTime,
    this.totalDistance = 0.0,
  });

  CollectionBase copyWith({
    String? id,
    String? provisionalName,
    CollectionType? type,
    CollectionStatus? status,
    List<LatLng>? points,
    DateTime? startTime,
    DateTime? lastPointTime,
    double? totalDistance,
  }) {
    return CollectionBase(
      id: id ?? this.id,
      provisionalName: provisionalName ?? this.provisionalName,
      type: type ?? this.type,
      status: status ?? this.status,
      points: points ?? this.points,
      startTime: startTime ?? this.startTime,
      lastPointTime: lastPointTime ?? this.lastPointTime,
      totalDistance: totalDistance ?? this.totalDistance,
    );
  }

  bool get isActive => status == CollectionStatus.active;
  bool get isPaused => status == CollectionStatus.paused;
  bool get isInactive => status == CollectionStatus.inactive;
}

class LigneCollection extends CollectionBase {
  LigneCollection({
    required super.id,
    required super.provisionalName,
    required super.status,
    required super.points,
    required super.startTime,
    super.lastPointTime,
    super.totalDistance,
  }) : super(type: CollectionType.ligne);

  @override
  LigneCollection copyWith({
    String? id,
    String? provisionalName,
    CollectionType? type,
    CollectionStatus? status,
    List<LatLng>? points,
    DateTime? startTime,
    DateTime? lastPointTime,
    double? totalDistance,
  }) {
    return LigneCollection(
      id: id ?? this.id,
      provisionalName: provisionalName ?? this.provisionalName,
      status: status ?? this.status,
      points: points ?? this.points,
      startTime: startTime ?? this.startTime,
      lastPointTime: lastPointTime ?? this.lastPointTime,
      totalDistance: totalDistance ?? this.totalDistance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provisionalName': provisionalName,
      'type': 'ligne',
      'status': status.toString(),
      'points':
          points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'startTime': startTime.toIso8601String(),
      'lastPointTime': lastPointTime?.toIso8601String(),
      'totalDistance': totalDistance,
    };
  }

  factory LigneCollection.fromJson(Map<String, dynamic> json) {
    return LigneCollection(
      id: json['id'],
      provisionalName: json['provisionalName'],
      status: CollectionStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      points: (json['points'] as List)
          .map((p) => LatLng(p['lat'], p['lng']))
          .toList(),
      startTime: DateTime.parse(json['startTime']),
      lastPointTime: json['lastPointTime'] != null
          ? DateTime.parse(json['lastPointTime'])
          : null,
      totalDistance: json['totalDistance']?.toDouble() ?? 0.0,
    );
  }
}

class ChausseeCollection extends CollectionBase {
  ChausseeCollection({
    required super.id,
    required super.provisionalName,
    required super.status,
    required super.points,
    required super.startTime,
    super.lastPointTime,
    super.totalDistance,
  }) : super(type: CollectionType.chaussee);

  @override
  ChausseeCollection copyWith({
    String? id,
    String? provisionalName,
    CollectionType? type,
    CollectionStatus? status,
    List<LatLng>? points,
    DateTime? startTime,
    DateTime? lastPointTime,
    double? totalDistance,
  }) {
    return ChausseeCollection(
      id: id ?? this.id,
      provisionalName: provisionalName ?? this.provisionalName,
      status: status ?? this.status,
      points: points ?? this.points,
      startTime: startTime ?? this.startTime,
      lastPointTime: lastPointTime ?? this.lastPointTime,
      totalDistance: totalDistance ?? this.totalDistance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provisionalName': provisionalName,
      'type': 'chaussee',
      'status': status.toString(),
      'points':
          points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'startTime': startTime.toIso8601String(),
      'lastPointTime': lastPointTime?.toIso8601String(),
      'totalDistance': totalDistance,
    };
  }

  factory ChausseeCollection.fromJson(Map<String, dynamic> json) {
    return ChausseeCollection(
      id: json['id'],
      provisionalName: json['provisionalName'],
      status: CollectionStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      points: (json['points'] as List)
          .map((p) => LatLng(p['lat'], p['lng']))
          .toList(),
      startTime: DateTime.parse(json['startTime']),
      lastPointTime: json['lastPointTime'] != null
          ? DateTime.parse(json['lastPointTime'])
          : null,
      totalDistance: json['totalDistance']?.toDouble() ?? 0.0,
    );
  }
}

class CollectionResult {
  final String id;
  final String provisionalName;
  final CollectionType type;
  final List<LatLng> points;
  final double totalDistance;
  final DateTime startTime;
  final DateTime endTime;

  CollectionResult({
    required this.id,
    required this.provisionalName,
    required this.type,
    required this.points,
    required this.totalDistance,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'provisionalName': provisionalName,
      'type': type.toString(),
      'points': points,
      'totalDistance': totalDistance,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
