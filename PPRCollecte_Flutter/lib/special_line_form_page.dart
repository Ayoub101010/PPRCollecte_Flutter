import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'point_form_widget.dart'; // ← IMPORTEZ LE FORMULAIRE EXISTANT
import 'config.dart';
import 'api_service.dart';
import 'database_helper.dart';

class SpecialLineFormPage extends StatefulWidget {
  final List<LatLng> linePoints;
  final String? provisionalCode;
  final DateTime startTime;
  final DateTime endTime;
  final String agentName;
  final String specialType;
  final double totalDistance;

  const SpecialLineFormPage({
    super.key,
    required this.linePoints,
    required this.provisionalCode,
    required this.startTime,
    required this.endTime,
    required this.agentName,
    required this.specialType,
    required this.totalDistance,
  });

  @override
  State<SpecialLineFormPage> createState() => _SpecialLineFormPageState();
}

class _SpecialLineFormPageState extends State<SpecialLineFormPage> {
  Map<String, dynamic> _prepareFormData() {
    final firstPoint = widget.linePoints.first;
    final lastPoint = widget.linePoints.last;
    print('📍 Premier point: ${firstPoint.latitude}, ${firstPoint.longitude}');
    print('📍 Dernier point: ${lastPoint.latitude}, ${lastPoint.longitude}');
    print('📍 Distance: ${widget.totalDistance}m');
    // UTILISEZ LES MÊMES NOMS DE CHAMPS QUE LE FORMULAIRE EXISTANT
    return {
      'id': null,
      'latitude': firstPoint.latitude, // ← Même champ que pour les points normaux
      'longitude': firstPoint.longitude, // ← Même champ que pour les points normaux
      // Ajoutez les champs spéciaux en PLUS
      'latitude_debut': firstPoint.latitude,
      'longitude_debut': firstPoint.longitude,
      'latitude_fin': lastPoint.latitude,
      'longitude_fin': lastPoint.longitude,
      'distance': widget.totalDistance,
      'code_piste': widget.provisionalCode,
      'date_creation': DateTime.now().toIso8601String(),
      'enqueteur': widget.agentName,
      'nom': null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final formData = _prepareFormData();

    return Scaffold(
      body: PointFormWidget(
        category: "Ouvrages",
        type: widget.specialType,
        pointData: formData,
        onBack: () {
          // AFFICHER DIRECTEMENT LA CONFIRMATION
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Abandonner la saisie ?"),
              content: const Text("Les données non sauvegardées seront perdues."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Annuler"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Fermer la boîte
                    Navigator.of(context).pop(); // Fermer le formulaire
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("Abandonner"),
                ),
              ],
            ),
          );
        },
        onSaved: () {
          Navigator.of(context).pop(true);
        },
        agentName: widget.agentName,
        nearestPisteCode: widget.provisionalCode,
        isSpecialLine: true,
      ),
    );
  }
}
