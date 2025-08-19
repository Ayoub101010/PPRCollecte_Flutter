class Buse {
  final int? id;
  final double xBuse;
  final double yBuse;
  final String enqueteur;
  final String dateCreation;
  final String? dateModification;
  final String? codePiste;

  Buse({
    this.id,
    required this.xBuse,
    required this.yBuse,
    required this.enqueteur,
    required this.dateCreation,
    this.dateModification,
    this.codePiste,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'x_buse': xBuse,
      'y_buse': yBuse,
      'enqueteur': enqueteur,
      'date_creation': dateCreation,
      'date_modification': dateModification,
      'code_piste': codePiste,
    };
  }

  factory Buse.fromMap(Map<String, dynamic> map) {
    return Buse(
      id: map['id'],
      xBuse: map['x_buse'],
      yBuse: map['y_buse'],
      enqueteur: map['enqueteur'],
      dateCreation: map['date_creation'],
      dateModification: map['date_modification'],
      codePiste: map['code_piste'],
    );
  }
}
