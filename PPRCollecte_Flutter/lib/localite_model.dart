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

  // Conversion vers Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'local_id': localId,
      'x_localite': xLocalite,
      'y_localite': yLocalite,
      'nom': nom,
      'type': type,
      'enqueteur': enqueteur,
      'date_creation': dateCreation.isEmpty ? DateTime.now().toString() : dateCreation,
    };
  }

  // Conversion depuis Map (pour les requêtes)
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
}
