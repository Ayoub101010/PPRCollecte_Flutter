import 'dart:convert';

class Localite {
  final int? localId;
  final double xLocalite;
  final double yLocalite;
  final String nom;
  final String type;
  final String enqueteur;
  final String dateCreation;

  Localite({
    this.localId,
    required this.xLocalite,
    required this.yLocalite,
    required this.nom,
    required this.type,
    required this.enqueteur,
    this.dateCreation = '',
  });

  // Conversion vers Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'local_id': localId,
      'x_localite': xLocalite,
      'y_localite': yLocalite,
      'nom': nom,
      'type': type,
      'enqueteur': enqueteur,
      'date_creation': dateCreation.isEmpty ? DateTime.now().toIso8601String() : dateCreation,
    };
  }

  // Conversion depuis Map (SQLite)
  factory Localite.fromMap(Map<String, dynamic> map) {
    return Localite(
      localId: map['local_id'],
      xLocalite: map['x_localite'],
      yLocalite: map['y_localite'],
      nom: map['nom'],
      type: map['type'],
      enqueteur: map['enqueteur'],
      dateCreation: map['date_creation'],
    );
  }

  // Conversion vers JSON (string)
  Map<String, dynamic> toJson() => {
        'local_id': localId,
        'x_localite': xLocalite,
        'y_localite': yLocalite,
        'nom': nom,
        'type': type,
        'enqueteur': enqueteur,
        'date_creation': dateCreation.isEmpty ? DateTime.now().toIso8601String() : dateCreation,
      };

  // Conversion depuis JSON
  factory Localite.fromJson(Map<String, dynamic> json) => Localite(
        localId: json['local_id'],
        xLocalite: (json['x_localite'] as num).toDouble(),
        yLocalite: (json['y_localite'] as num).toDouble(),
        nom: json['nom'],
        type: json['type'],
        enqueteur: json['enqueteur'],
        dateCreation: json['date_creation'],
      );
}
