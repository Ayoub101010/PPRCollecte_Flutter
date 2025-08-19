class Marche {
  final int? id;
  final double xMarche;
  final double yMarche;
  final String nom;
  final String type;
  final String enqueteur;
  final String dateCreation;
  final String? dateModification;
  final String? codePiste;

  Marche({
    this.id,
    required this.xMarche,
    required this.yMarche,
    required this.nom,
    required this.type,
    required this.enqueteur,
    required this.dateCreation,
    this.dateModification,
    this.codePiste,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'x_marche': xMarche,
      'y_marche': yMarche,
      'nom': nom,
      'type': type,
      'enqueteur': enqueteur,
      'date_creation': dateCreation,
      'date_modification': dateModification,
      'code_piste': codePiste,
    };
  }

  factory Marche.fromMap(Map<String, dynamic> map) {
    return Marche(
      id: map['id'],
      xMarche: map['x_marche'],
      yMarche: map['y_marche'],
      nom: map['nom'],
      type: map['type'],
      enqueteur: map['enqueteur'],
      dateCreation: map['date_creation'],
      dateModification: map['date_modification'],
      codePiste: map['code_piste'],
    );
  }
}
