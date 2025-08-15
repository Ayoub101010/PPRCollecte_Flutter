import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class FormulaireChausseePage extends StatefulWidget {
  final List<LatLng> chausseePoints;
  final String? provisionalId;
  final String? provisionalName;

  const FormulaireChausseePage({
    super.key,
    required this.chausseePoints,
    this.provisionalId,
    this.provisionalName,
  });

  @override
  State<FormulaireChausseePage> createState() => _FormulaireChausseePageState();
}

class _FormulaireChausseePageState extends State<FormulaireChausseePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Champs du formulaire selon le MCD pour les chaussées
  final _idController = TextEditingController();
  final _longueurController = TextEditingController();
  final _largeurController = TextEditingController();
  final _observationsController = TextEditingController();

  String? _pisteId;
  String? _revetement; // Corrigé : sans caractères spéciaux
  String? _etatChaussee;
  String? _typeDefaut;
  DateTime? _dateConstructionChaussee;
  DateTime? _dateDernierEntretien;

  // Options pour les dropdowns
  final List<String> _revetementOptions = [
    "Bitume",
    "Béton",
    "Pavés",
    "Gravier",
    "Terre",
    "Autre"
  ];

  final List<String> _etatOptions = [
    "Très bon",
    "Bon",
    "Moyen",
    "Mauvais",
    "Très mauvais"
  ];

  final List<String> _defautOptions = [
    "Aucun",
    "Nids de poule",
    "Fissures",
    "Affaissement",
    "Déformation",
    "Usure"
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.provisionalId != null) {
      _idController.text = widget.provisionalId!;
    }

    // Calculer la longueur automatiquement
    final distance = _calculateTotalDistance(widget.chausseePoints);
    _longueurController.text = (distance / 1000).toStringAsFixed(2); // en km
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
    // Formule de Haversine simplifiée
    const double p = 0.017453292519943295;
    final a = 0.5 -
        (cos((point2.latitude - point1.latitude) * p) / 2) +
        cos(point1.latitude * p) *
            cos(point2.latitude * p) *
            (1 - cos((point2.longitude - point1.longitude) * p)) /
            2;
    return 12742000 * asin(sqrt(a));
  }

  Future<void> _selectDate(
      BuildContext context, bool isConstructionDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isConstructionDate) {
          _dateConstructionChaussee = picked;
        } else {
          _dateDernierEntretien = picked;
        }
      });
    }
  }

  Future<void> _saveChaussee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Simuler sauvegarde
      await Future.delayed(const Duration(seconds: 1));

      // Données à sauvegarder selon le MCD
      final chausseeData = {
        'id': _idController.text,
        'piste_id': _pisteId,
        'longueur_chaussee_km': double.tryParse(_longueurController.text),
        'largeur_chaussee_m': double.tryParse(_largeurController.text),
        'revetement': _revetement,
        'etat_chaussee': _etatChaussee,
        'type_defaut': _typeDefaut,
        'date_construction_chaussee':
            _dateConstructionChaussee?.toIso8601String(),
        'date_dernier_entretien': _dateDernierEntretien?.toIso8601String(),
        'observations': _observationsController.text,
        'points': widget.chausseePoints
            .map((p) => {
                  'latitude': p.latitude,
                  'longitude': p.longitude,
                })
            .toList(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending',
      };

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
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
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
                          controller: _idController,
                          label: 'ID Chaussée *',
                          hint: 'Identifiant unique de la chaussée',
                          required: true,
                        ),
                        _buildTextField(
                          controller:
                              TextEditingController(text: _pisteId ?? ''),
                          label: 'Piste Associée',
                          hint: 'ID de la piste associée',
                          onChanged: (value) => _pisteId = value,
                        ),
                      ],
                    ),

                    // Section Caractéristiques Physiques
                    _buildFormSection(
                      title: '📏 Caractéristiques Physiques',
                      children: [
                        _buildTextField(
                          controller: _longueurController,
                          label: 'Longueur (km) *',
                          hint: 'Longueur calculée automatiquement',
                          keyboardType: TextInputType.number,
                          required: true,
                        ),
                        _buildTextField(
                          controller: _largeurController,
                          label: 'Largeur (m)',
                          hint: 'Largeur moyenne de la chaussée',
                          keyboardType: TextInputType.number,
                        ),
                        _buildDropdownField(
                          label: 'Revêtement *',
                          value: _revetement,
                          options: _revetementOptions,
                          onChanged: (value) =>
                              setState(() => _revetement = value),
                          required: true,
                        ),
                      ],
                    ),

                    // Section État et Défauts
                    _buildFormSection(
                      title: '⚠️ État et Défauts',
                      children: [
                        _buildDropdownField(
                          label: 'État de la Chaussée *',
                          value: _etatChaussee,
                          options: _etatOptions,
                          onChanged: (value) =>
                              setState(() => _etatChaussee = value),
                          required: true,
                        ),
                        _buildDropdownField(
                          label: 'Type de Défaut',
                          value: _typeDefaut,
                          options: _defautOptions,
                          onChanged: (value) =>
                              setState(() => _typeDefaut = value),
                        ),
                      ],
                    ),

                    // Section Historique
                    _buildFormSection(
                      title: '📅 Historique',
                      children: [
                        _buildDateField(
                          label: 'Date de Construction',
                          value: _dateConstructionChaussee,
                          onTap: () => _selectDate(context, true),
                        ),
                        _buildDateField(
                          label: 'Date Dernier Entretien',
                          value: _dateDernierEntretien,
                          onTap: () => _selectDate(context, false),
                        ),
                      ],
                    ),

                    // Section Observations
                    _buildFormSection(
                      title: '📝 Observations',
                      children: [
                        _buildTextField(
                          controller: _observationsController,
                          label: 'Observations',
                          hint: 'Remarques générales sur la chaussée',
                          maxLines: 3,
                        ),
                      ],
                    ),

                    // Section GPS
                    _buildFormSection(
                      title: '📍 Géolocalisation',
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
                              'Enregistrer la Chaussée',
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

  Widget _buildFormSection(
      {required String title, required List<Widget> children}) {
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
    TextEditingController? controller,
    required String label,
    required String hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    Function(String)? onChanged,
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
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
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
            textAlignVertical: maxLines > 1 ? TextAlignVertical.top : null,
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

  Widget _buildDropdownField({
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
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
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
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: onChanged,
            validator: required
                ? (value) {
                    if (value == null || value.isEmpty) {
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

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
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
          GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 20, color: Color(0xFF666666)),
                  const SizedBox(width: 12),
                  Text(
                    value != null
                        ? "${value.day}/${value.month}/${value.year}"
                        : "Sélectionner une date",
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null
                          ? const Color(0xFF374151)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
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
          _buildGpsInfoRow(
              'Points collectés:', '${widget.chausseePoints.length}'),
          _buildGpsInfoRow('Distance totale:',
              '${(_calculateTotalDistance(widget.chausseePoints) / 1000).toStringAsFixed(2)} km'),
          if (widget.chausseePoints.isNotEmpty) ...[
            _buildGpsInfoRow('Premier point:',
                '${widget.chausseePoints.first.latitude.toStringAsFixed(6)}°, ${widget.chausseePoints.first.longitude.toStringAsFixed(6)}°'),
            _buildGpsInfoRow('Dernier point:',
                '${widget.chausseePoints.last.latitude.toStringAsFixed(6)}°, ${widget.chausseePoints.last.longitude.toStringAsFixed(6)}°'),
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
