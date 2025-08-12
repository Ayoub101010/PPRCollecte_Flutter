import 'package:google_maps_flutter/google_maps_flutter.dart';

class FormulaireLigneController {
  // Champs Piste
  String nomPiste = '';
  double longueurPiste = 0;

  // Champs Chaussée
  String typeChaussee = '';

  // Construit l'objet final
  Map<String, dynamic> buildResult(List<LatLng> linePoints) {
    return {
      "nomPiste": nomPiste,
      "longueurPiste": longueurPiste,
      "typeChaussee": typeChaussee,
      "points": linePoints
          .map((p) => {
                "lat": p.latitude,
                "lng": p.longitude
              })
          .toList(),
    };
  }
}
