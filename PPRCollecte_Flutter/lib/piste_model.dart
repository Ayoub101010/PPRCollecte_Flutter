// lib/piste_model.dart
import 'dart:convert';

class PisteModel {
  final int? id;
  final String codePiste;
  final String? communeRuraleId;
  final String userLogin;
  final String heureDebut;
  final String heureFin;
  final String nomOriginePiste;
  final double xOrigine;
  final double yOrigine;
  final String nomDestinationPiste;
  final double xDestination;
  final double yDestination;
  final String? typeOccupation;
  final String? debutOccupation;
  final String? finOccupation;
  final double? largeurEmprise;
  final String? frequenceTrafic;
  final String? typeTrafic;
  final String? travauxRealises;
  final String? dateTravaux;
  final String? entreprise;
  final String pointsJson;
  final String createdAt;
  final String? updatedAt;

  PisteModel({
    this.id,
    required this.codePiste,
    this.communeRuraleId,
    required this.userLogin,
    required this.heureDebut,
    required this.heureFin,
    required this.nomOriginePiste,
    required this.xOrigine,
    required this.yOrigine,
    required this.nomDestinationPiste,
    required this.xDestination,
    required this.yDestination,
    this.typeOccupation,
    this.debutOccupation,
    this.finOccupation,
    this.largeurEmprise,
    this.frequenceTrafic,
    this.typeTrafic,
    this.travauxRealises,
    this.dateTravaux,
    this.entreprise,
    required this.pointsJson,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PisteModel.fromFormData(Map<String, dynamic> formData) {
    final pointsData = formData['points'] as List<dynamic>? ?? [];
    final pointsJson = jsonEncode(pointsData);

    return PisteModel(
      codePiste: formData['code_piste'] ?? '',
      communeRuraleId: formData['commune_rurale_id'],
      userLogin: formData['user_login'] ?? '',
      heureDebut: formData['heure_debut'] ?? '',
      heureFin: formData['heure_fin'] ?? '',
      nomOriginePiste: formData['nom_origine_piste'] ?? '',
      xOrigine: _parseDouble(formData['x_origine']),
      yOrigine: _parseDouble(formData['y_origine']),
      nomDestinationPiste: formData['nom_destination_piste'] ?? '',
      xDestination: _parseDouble(formData['x_destination']),
      yDestination: _parseDouble(formData['y_destination']),
      typeOccupation: formData['type_occupation'],
      debutOccupation: formData['debut_occupation'],
      finOccupation: formData['fin_occupation'],
      largeurEmprise: formData['largeur_emprise'],
      frequenceTrafic: formData['frequence_trafic'],
      typeTrafic: formData['type_trafic'],
      travauxRealises: formData['travaux_realises'],
      dateTravaux: formData['date_travaux'],
      entreprise: formData['entreprise'],
      pointsJson: pointsJson,
      createdAt: formData['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: formData['updated_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code_piste': codePiste,
      'commune_rurale_id': communeRuraleId,
      'user_login': userLogin,
      'heure_debut': heureDebut,
      'heure_fin': heureFin,
      'nom_origine_piste': nomOriginePiste,
      'x_origine': xOrigine,
      'y_origine': yOrigine,
      'nom_destination_piste': nomDestinationPiste,
      'x_destination': xDestination,
      'y_destination': yDestination,
      'type_occupation': typeOccupation,
      'debut_occupation': debutOccupation,
      'fin_occupation': finOccupation,
      'largeur_emprise': largeurEmprise,
      'frequence_trafic': frequenceTrafic,
      'type_trafic': typeTrafic,
      'travaux_realises': travauxRealises,
      'date_travaux': dateTravaux,
      'entreprise': entreprise,
      'points_json': pointsJson,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory PisteModel.fromMap(Map<String, dynamic> map) {
    return PisteModel(
      id: map['id'],
      codePiste: map['code_piste'] ?? '',
      communeRuraleId: map['commune_rurale_id'],
      userLogin: map['user_login'] ?? '',
      heureDebut: map['heure_debut'] ?? '',
      heureFin: map['heure_fin'] ?? '',
      nomOriginePiste: map['nom_origine_piste'] ?? '',
      xOrigine: _parseDouble(map['x_origine']),
      yOrigine: _parseDouble(map['y_origine']),
      nomDestinationPiste: map['nom_destination_piste'] ?? '',
      xDestination: _parseDouble(map['x_destination']),
      yDestination: _parseDouble(map['y_destination']),
      typeOccupation: map['type_occupation'],
      debutOccupation: map['debut_occupation'],
      finOccupation: map['fin_occupation'],
      largeurEmprise: _parseDouble(map['largeur_emprise']),
      frequenceTrafic: map['frequence_trafic'],
      typeTrafic: map['type_trafic'],
      travauxRealises: map['travaux_realises'],
      dateTravaux: map['date_travaux'],
      entreprise: map['entreprise'],
      pointsJson: map['points_json'] ?? '[]',
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at'] ?? DateTime.now().toIso8601String(), // ← NOUVEAU
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
}
