class PointCritique {
  final int? id;
  final double xPointCritique;
  final double yPointCritique;
  final String typePointCritique;
  final String enqueteur;
  final String dateCreation;
  final String? dateModification;
  final String? codePiste;

  PointCritique({
    this.id,
    required this.xPointCritique,
    required this.yPointCritique,
    required this.typePointCritique,
    required this.enqueteur,
    required this.dateCreation,
    this.dateModification,
    this.codePiste,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'x_point_critique': xPointCritique,
      'y_point_critique': yPointCritique,
      'type_point_critique': typePointCritique,
      'enqueteur': enqueteur,
      'date_creation': dateCreation,
      'date_modification': dateModification,
      'code_piste': codePiste,
    };
  }

  factory PointCritique.fromMap(Map<String, dynamic> map) {
    return PointCritique(
      id: map['id'],
      xPointCritique: map['x_point_critique'],
      yPointCritique: map['y_point_critique'],
      typePointCritique: map['type_point_critique'],
      enqueteur: map['enqueteur'],
      dateCreation: map['date_creation'],
      dateModification: map['date_modification'],
      codePiste: map['code_piste'],
    );
  }
}
