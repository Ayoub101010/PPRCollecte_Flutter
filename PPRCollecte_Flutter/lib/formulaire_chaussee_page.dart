// lib/formulaire_chaussee_page.dart - VERSION FINALE CORRIGÉE
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'piste_chaussee_db_helper.dart';

class FormulaireChausseePage extends StatefulWidget {
  final List<LatLng> chausseePoints;
  final int? provisionalId;

  const FormulaireChausseePage({
    super.key,
    required this.chausseePoints,
    this.provisionalId,
  });

  @override
  State<FormulaireChausseePage> createState() => _FormulaireChausseePageState();
}

class _FormulaireChausseePageState extends State<FormulaireChausseePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // ✅ CHAMPS SELON VOS SPÉCIFICATIONS
  final _codePisteController = TextEditingController();
  final _codeGpsController = TextEditingController();
  final _endroitController = TextEditingController();

  String? _typeChaussee; // Radio buttons
  String? _etatPiste; // Radio buttons

  // ✅ OPTIONS SELON LA DOCUMENTATION OFFICIELLE
  final List<String> _typeChausseeOptions = [
    "Bitume",
    "Latérite",
    "Terre",
    "Bouwal",
    "Autre"
  ];

  final List<String> _etatPisteOptions = [
    "Bon état",
    "Moyennement dégradée",
    "Fortement dégradée"
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Initialisation si nécessaire
    // Les coordonnées seront calculées automatiquement depuis chausseePoints
  }

  double _calculateTotalDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += _distanceBetween(points[i], points[i + 1]);
    }
    return total;
  }

  double _distanceBetween(LatLng point1, LatLng point2) {
    const double p = 0.017453292519943295;
    final a = 0.5 - (cos((point2.latitude - point1.latitude) * p) / 2) + cos(point1.latitude * p) * cos(point2.latitude * p) * (1 - cos((point2.longitude - point1.longitude) * p)) / 2;
    return 12742000 * asin(sqrt(a));
  }

  Future<void> _saveChaussee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      // ✅ DONNÉES SELON VOS SPÉCIFICATIONS
      final chausseeData = {
        // Champs saisis par l'utilisateur
        'code_piste': _codePisteController.text,
        'code_gps': _codeGpsController.text,
        'endroit': _endroitController.text,
        'type_chaussee': _typeChaussee,
        'etat_piste': _etatPiste,

        // ✅ Coordonnées auto-gérées (les 4)
        'x_debut_chaussee': widget.chausseePoints.isNotEmpty ? widget.chausseePoints.first.longitude : null,
        'y_debut_chaussee': widget.chausseePoints.isNotEmpty ? widget.chausseePoints.first.latitude : null,
        'x_fin_chaussee': widget.chausseePoints.isNotEmpty ? widget.chausseePoints.last.longitude : null,
        'y_fin_chaussee': widget.chausseePoints.isNotEmpty ? widget.chausseePoints.last.latitude : null,

        // Métadonnées de collecte
        'points_collectes': widget.chausseePoints
            .map((p) => {
                  'latitude': p.latitude,
                  'longitude': p.longitude,
                })
            .toList(),
        'distance_totale_m': _calculateTotalDistance(widget.chausseePoints),
        'nombre_points': widget.chausseePoints.length,
        'created_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending',
      };
      final storageHelper = SimpleStorageHelper();
      final savedId = await storageHelper.saveChaussee(chausseeData);
      if (savedId != null) {
        print('✅ Chaussée sauvegardée en local avec ID: $savedId');
      }

      if (mounted) {
        Navigator.of(context).pop(chausseeData);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFF9800),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    padding: const EdgeInsets.all(8),
                  ),
                  const Expanded(
                    child: Text(
                      "🛣️ Formulaire Chaussée",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Contenu du formulaire
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Section Identification
                    _buildFormSection(
                      title: '🏷️ Identification',
                      children: [
                        _buildTextField(
                          controller: _codePisteController,
                          label: 'Code Piste *',
                          hint: 'Ex: 1B-02CR03P01',
                          required: true,
                        ),
                        _buildTextField(
                          controller: _codeGpsController,
                          label: 'Code GPS *',
                          hint: 'Identifiant GPS terrain',
                          required: true,
                        ),
                        _buildTextField(
                          controller: _endroitController,
                          label: 'Endroit *',
                          hint: 'Lieu/localisation',
                          required: true,
                        ),
                      ],
                    ),

                    // ✅ Section Coordonnées (AFFICHAGE SEULEMENT)
                    _buildFormSection(
                      title: '📍 Coordonnées (Auto-calculées)',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildCoordinateDisplay(
                                label: 'X Début chaussée',
                                value: widget.chausseePoints.isNotEmpty ? widget.chausseePoints.first.longitude.toStringAsFixed(8) : 'N/A',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildCoordinateDisplay(
                                label: 'Y Début chaussée',
                                value: widget.chausseePoints.isNotEmpty ? widget.chausseePoints.first.latitude.toStringAsFixed(8) : 'N/A',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCoordinateDisplay(
                                label: 'X Fin chaussée',
                                value: widget.chausseePoints.isNotEmpty ? widget.chausseePoints.last.longitude.toStringAsFixed(8) : 'N/A',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildCoordinateDisplay(
                                label: 'Y Fin chaussée',
                                value: widget.chausseePoints.isNotEmpty ? widget.chausseePoints.last.latitude.toStringAsFixed(8) : 'N/A',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ✅ Section Caractéristiques (RADIO BUTTONS)
                    _buildFormSection(
                      title: '🛣️ Caractéristiques',
                      children: [
                        _buildRadioGroupField(
                          label: 'Type de chaussée *',
                          value: _typeChaussee,
                          options: _typeChausseeOptions,
                          onChanged: (value) => setState(() => _typeChaussee = value),
                          required: true,
                        ),
                        _buildRadioGroupField(
                          label: 'État de la piste *',
                          value: _etatPiste,
                          options: _etatPisteOptions,
                          onChanged: (value) => setState(() => _etatPiste = value),
                          required: true,
                        ),
                      ],
                    ),

                    // Section GPS (info collecte)
                    _buildFormSection(
                      title: '📱 Données de collecte',
                      children: [
                        _buildGpsInfo(),
                      ],
                    ),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),

            // Bouton Sauvegarder
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChaussee,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Enregistrer la chaussée',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE3F2FD))),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF9800),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFFF9800)),
              ),
            ),
            validator: required
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '$label est obligatoire';
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // ✅ WIDGET POUR AFFICHAGE DES COORDONNÉES (LECTURE SEULE)
  Widget _buildCoordinateDisplay({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.gps_fixed,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ WIDGET POUR RADIO BUTTONS
  Widget _buildRadioGroupField({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
    bool required = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: options.map((option) {
                return RadioListTile<String>(
                  title: Text(
                    option,
                    style: const TextStyle(fontSize: 14),
                  ),
                  value: option,
                  groupValue: value,
                  onChanged: onChanged,
                  activeColor: const Color(0xFFFF9800),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }).toList(),
            ),
          ),
          if (required && (value == null || value.isEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(
                '$label est obligatoire',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGpsInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gps_fixed, size: 20, color: Color(0xFFFF9800)),
              SizedBox(width: 8),
              Text(
                'Tracé GPS collecté',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGpsInfoRow('Points collectés:', '${widget.chausseePoints.length}'),
          _buildGpsInfoRow('Distance totale:', '${(_calculateTotalDistance(widget.chausseePoints) / 1000).toStringAsFixed(2)} km'),
          if (widget.chausseePoints.isNotEmpty) ...[
            _buildGpsInfoRow('Premier point:', '${widget.chausseePoints.first.latitude.toStringAsFixed(6)}°, ${widget.chausseePoints.first.longitude.toStringAsFixed(6)}°'),
            _buildGpsInfoRow('Dernier point:', '${widget.chausseePoints.last.latitude.toStringAsFixed(6)}°, ${widget.chausseePoints.last.longitude.toStringAsFixed(6)}°'),
          ],
        ],
      ),
    );
  }

  Widget _buildGpsInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
