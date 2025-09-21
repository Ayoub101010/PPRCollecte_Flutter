class Dalot {
  final int? id;
  final double xDalot;
  final double yDalot;
  final String situationDalot;
  final String enqueteur;
  final String dateCreation;
  final String? dateModification;
  final String? codePiste;
  final int? communeId;

  Dalot({
    this.id,
    required this.xDalot,
    required this.yDalot,
    required this.situationDalot,
    required this.enqueteur,
    required this.dateCreation,
    this.dateModification,
    this.codePiste,
    this.communeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'x_dalot': xDalot,
      'y_dalot': yDalot,
      'situation_dalot': situationDalot,
      'enqueteur': enqueteur,
      'date_creation': dateCreation,
      'date_modification': dateModification,
      'code_piste': codePiste,
      'commune_id': communeId,
    };
  }

  factory Dalot.fromMap(Map<String, dynamic> map) {
    return Dalot(
      id: map['id'],
      xDalot: map['x_dalot'],
      yDalot: map['y_dalot'],
      situationDalot: map['situation_dalot'],
      enqueteur: map['enqueteur'],
      dateCreation: map['date_creation'],
      dateModification: map['date_modification'],
      codePiste: map['code_piste'],
      communeId: map['commune_id'],
    );
  }
}
